// Menyimpan percakapan dan draf selama sesi dashboard, terpisah dari kode tampilan.
import 'package:flutter/foundation.dart';

import 'chat_models.dart';
import 'chat_connection.dart';
import 'ollama_service.dart';
import 'chat_policy.dart';

class ChatController extends ChangeNotifier {
  ChatController({ChatService? service})
    : _service = service ?? OllamaService(addresses: ChatConnection.candidates);
  final ChatService _service;
  final capabilities = const ChatCapabilities();
  RequestPlan? _plan;
  // Halaman induk menghubungkan formulir izin dengan akun dan antrean yang sama.
  VoidCallback? openLeave;
  final messages = <ChatMessage>[
    const ChatMessage(
      'Halo! Ketik jadwal, ipk, atau krs untuk cek cepat; tambahkan ? untuk pilihan bantuan. Saya membantu kebutuhan mahasiswa semester 1–14, belajar, dan draf. Data kampus belum terhubung.',
    ),
  ];
  final _aiHistory = <ChatMessage>[];
  final letter = StudentDraft(DraftKind.letter);
  final issue = StudentDraft(DraftKind.issue);
  ChatMode mode = ChatMode.guided;
  bool busy = false;
  bool connecting = false;
  bool _preferGuided = false;
  String? get connectedAddress =>
      _service is OllamaService ? _service.connectedAddress : null;
  String? error;
  String input = '';
  bool canRetry = false;
  bool _disposed = false;
  int _request = 0;

  // Model dinyatakan siap hanya setelah server mengonfirmasi ketersediaannya.
  Future<void> autoConnect() async {
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
    messages.add(ChatMessage(topic.reply));
    error = null;
    canRetry = false;
    notifyListeners();
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
    var plan = ChatPolicy.route(text, previous: _plan);
    if (plan.followUp && _aiHistory.isEmpty) {
      plan = const RequestPlan(
        RequestKind.clarify,
        text: 'Konteks AI sebelumnya belum tersedia. Topik atau teks mana yang ingin Anda lanjutkan?',
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
        label: 'Penjelasan umum · glosarium aplikasi',
      );
      messages.add(answer);
      _aiHistory.addAll([ChatMessage(text, isUser: true), answer]);
      notifyListeners();
      return;
    }
    if (!plan.usesAi || mode == ChatMode.guided) {
      messages.add(
        ChatMessage(
          plan.text ?? ChatPolicy.offlineStudy(text),
          label: plan.label,
          actions: plan.actions,
          choices: plan.choices,
        ),
      );
      notifyListeners();
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
    await _answer();
  }

  // Coba lagi menggunakan pesan terakhir yang sama, tanpa menggandakan gelembung pesan.
  Future<void> retry() async {
    if (!busy && canRetry) await _answer();
  }

  Future<void> _answer() async {
    final request = ++_request;
    busy = true;
    error = null;
    canRetry = false;
    notifyListeners();
    try {
      final text = await _service.reply(List.of(_aiHistory));
      if (_disposed || request != _request) return;
      final answer = ChatMessage(
        text,
        isAi: true,
        task: _aiHistory.last.task,
        label: _aiHistory.last.task == ChatTask.writing
            ? 'AI lokal · usulan bahasa, perlu diperiksa'
            : 'AI lokal · penjelasan umum',
      );
      messages.add(answer);
      _aiHistory.add(answer);
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

  // Percakapan baru membuang konteks lama; formulir draf tetap milik sesi login.
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
          'Percakapan baru. Sebutkan topik yang ingin dibahas. Data kampus belum terhubung.',
        ),
      );
    notifyListeners();
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
    issue.attachments.clear();
    letter.fields.clear();
    issue.fields.clear();
    letter.preview = null;
    issue.preview = null;
    input = '';
    super.dispose();
  }
}
