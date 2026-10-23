// Halaman percakapan. Controller milik dashboard menjaga draf saat halaman ditutup.
import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../shared/pixel_widgets.dart';
import 'chat_controller.dart';
import 'chat_models.dart';
import 'chat_widgets.dart';
import 'draft_page.dart';
import 'connection_settings.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.controller,
    this.showCloseButton = false,
  });
  final ChatController controller;
  final bool showCloseButton;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late final TextEditingController _input;
  final _scroll = ScrollController();
  ChatController get chat => widget.controller;
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: chat.input);
    _messageCount = chat.messages.length;
    chat.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    // Sambungkan saat chat dibuka; kegagalan tidak menghalangi bantuan terpandu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) chat.autoConnect();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) chat.autoConnect();
  }

  // Gulir setelah pesan baru selesai ditata; perubahan ukuran tidak menghapus input.
  void _changed() {
    if (!mounted) return;
    if (_input.text != chat.input) _input.text = chat.input;
    if (_messageCount != chat.messages.length) {
      _messageCount = chat.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: AppMotion.duration(context, 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _choose(HelpTopic topic) {
    chat.choose(topic);
    if (topic == HelpTopic.letter && chat.openLeave != null) {
      chat.openLeave!();
      return;
    }
    if (topic == HelpTopic.letter || topic == HelpTopic.issue) {
      Navigator.of(context).push(
        AppMotion.route(
          DraftPage(
            draft: topic == HelpTopic.letter ? chat.letter : chat.issue,
            chat: chat,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    chat.removeListener(_changed);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: chat,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        leading: widget.showCloseButton
            ? IconButton(
                tooltip: 'Tutup chatbot',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            : null,
        title: const Text('Smart Chatbot', style: TextStyle(fontSize: 14)),
        backgroundColor: AppTheme.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Percakapan baru',
            onPressed: chat.newConversation,
            icon: const Icon(Icons.add_comment_outlined),
          ),
          IconButton(
            tooltip: 'Pengaturan koneksi',
            onPressed: chat.busy
                ? null
                : () => showConnectionSettings(context, chat),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CampusBackground(dashboard: true),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1250),
                child: LayoutBuilder(
                  builder: (context, bounds) {
                    final wide =
                        bounds.maxWidth >= 1000 &&
                        MediaQuery.textScalerOf(context).scale(1) <= 1.3;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (wide)
                          SizedBox(
                            width: 260,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('BANTUAN', style: AppTheme.pixel(10)),
                                  const SizedBox(height: 20),
                                  ChatHelpOptions(
                                    onChoose: chat.busy ? null : _choose,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Draf dan percakapan disimpan sementara selama sesi login. Lampiran tidak dikirim ke AI.',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView(
                                  controller: _scroll,
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    _modePanel(),
                                    if (!wide) ...[
                                      const SizedBox(height: 12),
                                      // Bantuan dapat dilipat agar HP dan keyboard tetap punya ruang.
                                      Card(
                                        child: ExpansionTile(
                                          title: const Text(
                                            'Pilihan bantuan & draf',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          childrenPadding: const EdgeInsets.all(
                                            12,
                                          ),
                                          children: [
                                            ChatHelpOptions(
                                              onChoose: chat.busy
                                                  ? null
                                                  : _choose,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    for (final message in chat.messages)
                                      ChatBubble(
                                        message: message,
                                        onChoose: chat.busy ? null : _choose,
                                        onPrompt: chat.busy ? null : chat.send,
                                      ),
                                    if (chat.busy)
                                      const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Column(
                                          children: [
                                            LinearProgressIndicator(),
                                            SizedBox(height: 8),
                                            Text(
                                              'Menghubungi AI lokal…',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (chat.error != null) ...[
                                      Text(
                                        chat.error!,
                                        style: const TextStyle(
                                          color: AppTheme.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (chat.canRetry)
                                        TextButton(
                                          onPressed: chat.retry,
                                          child: const Text('Coba lagi'),
                                        ),
                                    ],
                                    if (chat.busy)
                                      TextButton(
                                        onPressed: chat.useGuided,
                                        child: const Text(
                                          'Batalkan · kembali ke terpandu',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              _composer(),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _modePanel() => PixelPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          chat.connecting
              ? 'MENCARI AI LOKAL…'
              : chat.mode == ChatMode.localAi
              ? 'AI LOKAL AKTIF'
              : 'BANTUAN TERPANDU',
          style: AppTheme.pixel(9, color: AppTheme.blue),
        ),
        const SizedBox(height: 10),
        const Text(
          'Data kampus belum terhubung. Draf belum dikirim. Jawaban AI berupa informasi umum yang perlu diperiksa.',
          style: TextStyle(fontSize: 11, height: 1.5),
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'Ketersediaan layanan',
            style: TextStyle(fontSize: 11),
          ),
          children: [
            Text(
              chat.capabilities.summary,
              style: const TextStyle(fontSize: 11, height: 1.5),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: chat.busy || chat.connecting
                  ? null
                  : chat.mode == ChatMode.localAi
                  ? chat.useGuided
                  : chat.enableAi,
              icon: Icon(
                chat.mode == ChatMode.localAi
                    ? Icons.checklist
                    : Icons.smart_toy_outlined,
              ),
              label: Text(
                chat.mode == ChatMode.localAi
                    ? 'Gunakan terpandu'
                    : 'Aktifkan AI lokal',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _composer() => Material(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 3,
              maxLength: 2000,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'Tulis pesan',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => chat.input = value,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Kirim pesan',
            onPressed: chat.busy ? null : () => chat.send(_input.text),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    ),
  );
}
