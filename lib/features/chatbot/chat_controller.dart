// Menyimpan percakapan dan draf selama sesi dashboard, terpisah dari kode tampilan.
import 'package:flutter/foundation.dart';

import 'chat_models.dart';
import 'chat_connection.dart';
import 'ollama_service.dart';

class ChatController extends ChangeNotifier {
  ChatController({ChatService? service})
    : _service = service ?? OllamaService(addresses: ChatConnection.candidates);
  final ChatService _service;
  final messages = <ChatMessage>[
    const ChatMessage(
      'Halo! Saya dapat membantu menyiapkan draf surat izin dan kendala. AI lokal akan dicoba otomatis untuk pertanyaan umum. Data kampus belum terhubung.',
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
    if (mode == ChatMode.guided || needsCampusData(text)) {
      messages.add(ChatMessage(guidedReply(text)));
      notifyListeners();
      return;
    }
    // Buang permintaan AI sebelumnya yang gagal sebelum menerima pertanyaan baru.
    if (_aiHistory.isNotEmpty && _aiHistory.last.isUser) {
      _aiHistory.removeLast();
    }
    _aiHistory.add(ChatMessage(text, isUser: true));
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
      final answer = ChatMessage(text, isAi: true);
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

  @override
  void dispose() {
    _disposed = true;
    _request++;
    _service.cancel();
    messages.clear();
    _aiHistory.clear();
    letter.attachments.clear();
    issue.attachments.clear();
    letter.fields.clear();
    issue.fields.clear();
    letter.preview = null;
    issue.preview = null;
    input = '';
    super.dispose();
  }
}
