// Menyimpan percakapan, konteks SIAKAD aktif, riwayat lokal, dan draf selama sesi.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_connection.dart';
import 'chat_models.dart';
import 'chat_policy.dart';
import 'ollama_service.dart';
import 'siakad_context.dart';

class ChatController extends ChangeNotifier {
  ChatController({ChatService? service, this.storageKey})
    : _service = service ?? OllamaService(addresses: ChatConnection.candidates);

  final ChatService _service;
  final String? storageKey;
  final capabilities = const ChatCapabilities();
  RequestPlan? _plan;

  // Halaman induk menghubungkan formulir izin dan data SIAKAD aktif pengguna.
  VoidCallback? openLeave;
  String Function()? siakadContextProvider;
  SiakadKnowledge Function()? knowledgeProvider;

  static const _defaultQuickPrompts = [
    ('Apa itu SIAKAD?', 'apa itu siakad'),
    ('Apa itu KRS?', 'apa itu krs'),
    ('Cara Izin Online', 'apa itu surat izin'),
    ('Alur Perwalian PA', 'apa itu perwalian'),
    ('Bimbingan & Sidang TA', 'apa itu sidang'),
  ];

  bool get hasContext =>
      knowledgeProvider != null || siakadContextProvider != null;

  String get activeRoleLabel =>
      knowledgeProvider?.call().roleLabel ?? 'SIAKAD FASILKOM';

  String? get greetingName => knowledgeProvider?.call().greetingName;

  List<(String, String)> get quickPrompts =>
      knowledgeProvider?.call().quickPrompts ?? _defaultQuickPrompts;

  final messages = <ChatMessage>[
    const ChatMessage(
      'Halo! Saya Asisten Khusus SIAKAD FASILKOM. Silakan pilih topik cepat di bawah atau ketik pertanyaan seputar jadwal, KRS, nilai, Izin Online, Perwalian PA, atau Bimbingan TA. Saya hanya memakai data SIAKAD dan tidak mengambil info dari luar.',
      label: 'Asisten SIAKAD · fokus internal',
    ),
  ];
  final _aiHistory = <ChatMessage>[];
  final letter = StudentDraft(DraftKind.letter);
  final issue = StudentDraft(DraftKind.issue);
  ChatMode mode = ChatMode.guided;
  bool busy = false;
  bool connecting = false;
  bool _preferGuided = false;
  bool _historyLoaded = false;
  String? get connectedAddress =>
      _service is OllamaService ? _service.connectedAddress : null;
  String? error;
  String input = '';
  bool canRetry = false;
  bool _disposed = false;
  int _request = 0;

  /// Muat riwayat percakapan terakhir milik akun dari penyimpanan lokal.
  Future<void> loadHistory() async {
    if (_disposed || _historyLoaded || storageKey == null) return;
    _historyLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('siakad_chat_$storageKey');
      if (raw == null || raw.isEmpty || _disposed) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty) return;
      final restored = <ChatMessage>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic> && item['text'] is String) {
          restored.add(
            ChatMessage(
              item['text'] as String,
              isUser: item['isUser'] == true,
              isAi: item['isAi'] == true,
              label: item['label'] as String?,
            ),
          );
        }
      }
      if (restored.isNotEmpty && !_disposed) {
        messages
          ..clear()
          ..addAll(restored);
        notifyListeners();
      }
    } catch (_) {
      // Abaikan jika penyimpanan lokal belum tersedia (misal pada lingkungan uji).
    }
  }

  Future<void> _saveHistory() async {
    if (_disposed || storageKey == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = messages.length > 40
          ? messages.sublist(messages.length - 40)
          : messages;
      final encoded = jsonEncode([
        for (final m in trimmed)
          {
            'text': m.text,
            'isUser': m.isUser,
            'isAi': m.isAi,
            'label': m.label,
          },
      ]);
      await prefs.setString('siakad_chat_$storageKey', encoded);
    } catch (_) {
      // Abaikan kegagalan penyimpanan agar percakapan tetap lancar.
    }
  }

  // Model dinyatakan siap hanya setelah server mengonfirmasi ketersediaannya.
  Future<void> autoConnect() async {
    await loadHistory();
    if (!_disposed && !_preferGuided && !busy && !connecting) await enableAi();
  }

  Future<void> enableAi() async {
    if (_disposed || busy || connecting) return;
    _preferGuided = false;
    final request = ++_request;
    connecting = true;
    mode = ChatMode.guided;
    error = null;
    canRetry = false;
    notifyListeners();
    try {
      await _service.check();
      if (_disposed || request != _request) return;
      mode = ChatMode.localAi;
    } on ChatServiceException catch (e) {
      if (!_disposed && request == _request) {
        mode = ChatMode.guided;
        error = e.message;
      }
    } finally {
      if (!_disposed && request == _request) {
        connecting = false;
        notifyListeners();
      }
    }
  }

  // Membatalkan permintaan juga membuat jawaban terlambat diabaikan.
  void useGuided() {
    _preferGuided = true;
    _request++;
    _service.cancel();
    busy = false;
    connecting = false;
    mode = ChatMode.guided;
    error = null;
    canRetry = false;
    _aiHistory.clear();
    notifyListeners();
  }

  void choose(HelpTopic topic) {
    if (busy) return;
    _aiHistory.clear();
    _plan = RequestPlan(switch (topic) {
      HelpTopic.study => RequestKind.study,
      HelpTopic.letter || HelpTopic.issue => RequestKind.draft,
      HelpTopic.files => RequestKind.files,
      HelpTopic.academic => RequestKind.policy,
      _ => RequestKind.personal,
    }, text: topic.reply);
    messages.add(ChatMessage(topic.label, isUser: true));
    messages.add(ChatMessage(topic.reply, label: 'Asisten SIAKAD'));
    error = null;
    canRetry = false;
    notifyListeners();
    _saveHistory();
  }

  Future<void> send(String text) async {
    text = text.trim();
    if (busy || text.isEmpty) return;
    if (text.length > 2000) {
      error = 'Pesan maksimal 2.000 karakter.';
      notifyListeners();
      return;
    }
    input = '';
    error = null;
    canRetry = false;
    messages.add(ChatMessage(text, isUser: true));
    var plan = ChatPolicy.route(
      text,
      previous: _plan,
      hasSiakadContext: hasContext,
    );
    if (plan.followUp && _aiHistory.isEmpty) {
      plan = const RequestPlan(
        RequestKind.clarify,
        text:
            'Konteks AI sebelumnya belum tersedia. Topik SIAKAD mana yang ingin Anda lanjutkan?',
      );
    }
    if (!plan.followUp) _aiHistory.clear();
    _plan = plan;
    final definition = plan.kind == RequestKind.study
        ? plan.text ?? ChatPolicy.definition(text)
        : null;
    if (definition != null) {
      final answer = ChatMessage(
        definition,
        label: 'Info SIAKAD · glosarium internal',
      );
      messages.add(answer);
      _aiHistory.addAll([ChatMessage(text, isUser: true), answer]);
      notifyListeners();
      _saveHistory();
      return;
    }
    if (!plan.usesAi || mode == ChatMode.guided) {
      final guidedText =
          plan.text ??
          (knowledgeProvider != null
              ? knowledgeProvider!().answerLocally(text)
              : siakadContextProvider != null
              ? 'Ringkasan data SIAKAD aktif Anda (Mode Terpandu):\n\n${siakadContextProvider!()}'
              : ChatPolicy.offlineStudy(text));
      final guidedLabel = plan.text == null && knowledgeProvider != null
          ? 'Info SIAKAD · data akun aktif'
          : plan.label;
      messages.add(
        ChatMessage(
          guidedText,
          label: guidedLabel,
          actions: plan.actions,
          choices: plan.choices,
        ),
      );
      notifyListeners();
      _saveHistory();
      return;
    }
    // Buang permintaan AI sebelumnya yang gagal sebelum menerima pertanyaan baru.
    if (_aiHistory.isNotEmpty && _aiHistory.last.isUser) {
      _aiHistory.removeLast();
    }
    _aiHistory.add(
      ChatMessage(
        text,
        isUser: true,
        task: plan.kind == RequestKind.writing
            ? ChatTask.writing
            : ChatTask.study,
      ),
    );
    await _answer(query: text);
  }

  // Coba lagi menggunakan pesan terakhir yang sama, tanpa menggandakan gelembung pesan.
  Future<void> retry() async {
    if (!busy && canRetry) {
      final lastQuery = _aiHistory.isEmpty ? '' : _aiHistory.last.text;
      await _answer(query: lastQuery);
    }
  }

  Future<void> _answer({required String query}) async {
    final request = ++_request;
    busy = true;
    error = null;
    canRetry = false;
    notifyListeners();
    try {
      final ctx =
          knowledgeProvider?.call().contextForQuery(query) ??
          siakadContextProvider?.call();
      final text = await _service.reply(
        List.of(_aiHistory),
        siakadContext: ctx,
      );
      if (_disposed || request != _request) return;
      final answer = ChatMessage(
        text,
        isAi: true,
        task: _aiHistory.last.task,
        label: _aiHistory.last.task == ChatTask.writing
            ? 'AI lokal · usulan bahasa draf SIAKAD'
            : 'AI lokal · khusus SIAKAD',
      );
      messages.add(answer);
      _aiHistory.add(answer);
      _saveHistory();
    } on ChatServiceException catch (e) {
      if (!_disposed && request == _request) {
        error = e.message;
        canRetry = true;
      }
    } finally {
      if (!_disposed && request == _request) {
        busy = false;
        notifyListeners();
      }
    }
  }

  // Percakapan baru membuang konteks lama dan membersihkan riwayat lokal akun ini.
  void newConversation() {
    _request++;
    _service.cancel();
    busy = false;
    connecting = false;
    canRetry = false;
    error = null;
    input = '';
    _plan = null;
    _aiHistory.clear();
    messages
      ..clear()
      ..add(
        const ChatMessage(
          'Percakapan baru dimulai! Silakan pilih topik cepat di bawah atau tanyakan seputar SIAKAD FASILKOM.',
          label: 'Asisten SIAKAD · fokus internal',
        ),
      );
    notifyListeners();
    if (storageKey != null) {
      SharedPreferences.getInstance()
          .then((prefs) => prefs.remove('siakad_chat_$storageKey'))
          .catchError((_) => false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    _service.cancel();
    messages.clear();
    _aiHistory.clear();
    _plan = null;
    letter.attachments.clear();
    openLeave = null;
    siakadContextProvider = null;
    knowledgeProvider = null;
    issue.attachments.clear();
    letter.fields.clear();
    issue.fields.clear();
    letter.preview = null;
    issue.preview = null;
    input = '';
    super.dispose();
  }
}
