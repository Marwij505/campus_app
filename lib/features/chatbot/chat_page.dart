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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Chatbot',
              style: AppTheme.pixel(10, color: Colors.white),
            ),
            const Text(
              'KHUSUS INFORMASI SIAKAD FASILKOM',
              style: TextStyle(fontSize: 9, color: Color(0xFFFFD6BD)),
            ),
          ],
        ),
        backgroundColor: AppTheme.red,
        foregroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: ColoredBox(
            color: AppTheme.ink,
            child: SizedBox(height: 4, width: double.infinity),
          ),
        ),
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
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 420,
                                          ),
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: AppTheme.ink,
                                              width: 2,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const LinearProgressIndicator(
                                                minHeight: 4,
                                              ),
                                              const SizedBox(height: 10),
                                              const Text(
                                                'Menyusun jawaban dari isi SIAKAD…',
                                                style: TextStyle(fontSize: 11),
                                              ),
                                              const SizedBox(height: 6),
                                              TextButton(
                                                onPressed: chat.useGuided,
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                ),
                                                child: const Text(
                                                  'Batalkan · kembali ke terpandu',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (chat.error != null) ...[
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF0F0),
                                          border: Border.all(
                                            color: AppTheme.red,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              chat.error!,
                                              style: const TextStyle(
                                                color: AppTheme.red,
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (chat.canRetry) ...[
                                              const SizedBox(height: 6),
                                              TextButton(
                                                onPressed: chat.retry,
                                                child: const Text('Coba lagi'),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              _quickSiakadStrip(),
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

  Widget _modePanel() {
    final statusColor = chat.connecting
        ? const Color(0xFFED7D21)
        : chat.mode == ChatMode.localAi
        ? const Color(0xFF198754)
        : AppTheme.blue;
    return PixelPanel(
      color: const Color(0xFFF8FBFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  border: Border.all(color: AppTheme.ink, width: 1.5),
                ),
              ),
              Text(
                chat.connecting
                    ? 'MENCARI AI LOKAL…'
                    : chat.mode == ChatMode.localAi
                    ? 'AI LOKAL AKTIF'
                    : 'BANTUAN TERPANDU',
                style: AppTheme.pixel(9, color: statusColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.blue.withValues(alpha: .1),
                  border: Border.all(
                    color: AppTheme.blue.withValues(alpha: .35),
                  ),
                ),
                child: const Text(
                  'Fokus SIAKAD · Tanpa Info Luar',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Asisten hanya menjawab informasi di dalam SIAKAD FASILKOM (KRS, jadwal, nilai, izin online, perwalian PA, dan bimbingan TA) serta menolak pertanyaan di luar SIAKAD.',
            style: TextStyle(fontSize: 11, height: 1.5),
          ),
          const SizedBox(height: 6),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Ketersediaan layanan',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
  }

  static const _quickPrompts = [
    ('Apa itu SIAKAD?', 'apa itu siakad'),
    ('Apa itu KRS?', 'apa itu krs'),
    ('Cara Izin Online', 'apa itu surat izin'),
    ('Alur Perwalian PA', 'apa itu perwalian'),
    ('Bimbingan & Sidang TA', 'apa itu sidang'),
  ];

  Widget _quickSiakadStrip() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: const BoxDecoration(
      color: Color(0xFFF3F8FC),
      border: Border(top: BorderSide(color: Color(0xFFD5E0ED), width: 1.5)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _quickPrompts.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            InkWell(
              onTap: chat.busy ? null : () => chat.send(_quickPrompts[i].$2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: AppTheme.blue.withValues(alpha: .45),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _quickPrompts[i].$1,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blue,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _composer() => Material(
    color: Colors.white,
    child: Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.ink, width: 3)),
      ),
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
              textInputAction: TextInputAction.send,
              onSubmitted: chat.busy ? null : (value) => chat.send(value),
              decoration: const InputDecoration(
                labelText: 'Tulis pesan',
                hintText: 'Tanya seputar SIAKAD (KRS, jadwal, izin, PA, TA)...',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => chat.input = value,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.blue,
              border: Border.all(color: AppTheme.ink, width: 2),
            ),
            child: IconButton(
              tooltip: 'Kirim pesan',
              color: Colors.white,
              onPressed: chat.busy ? null : () => chat.send(_input.text),
              icon: const Icon(Icons.send),
            ),
          ),
        ],
      ),
    ),
  );
}
