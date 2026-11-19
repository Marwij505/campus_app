// Halaman percakapan Smart Chatbot bertema ramah pengguna (friendly)
// yang berfokus pada isi SIAKAD aktif sesuai peran (Mahasiswa / Dosen).
import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import '../../shared/pixel_widgets.dart';
import 'chat_controller.dart';
import 'chat_models.dart';
import 'chat_widgets.dart';
import 'connection_settings.dart';
import 'draft_page.dart';

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
            duration: AppMotion.duration(context, 220),
            curve: Curves.easeOutCubic,
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
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .45),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart Chatbot',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Asisten SIAKAD · ${chat.activeRoleLabel}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFFFE4D6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.red,
        foregroundColor: Colors.white,
        elevation: 0,
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
                            width: 270,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .94),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFD7E3EE),
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1008142A),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 16,
                                          color: AppTheme.blue,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'BANTUAN CEPAT',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    ChatHelpOptions(
                                      onChoose: chat.busy ? null : _choose,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Riwayat chat disimpan lokal di perangkat untuk akun ini. Lampiran tidak dikirim ke AI.',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: AppTheme.muted,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
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
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFD7E3EE),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Theme(
                                          data: Theme.of(context).copyWith(
                                            dividerColor: Colors.transparent,
                                          ),
                                          child: ExpansionTile(
                                            leading: const Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 18,
                                              color: AppTheme.blue,
                                            ),
                                            title: const Text(
                                              'Pilihan bantuan & draf',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            childrenPadding:
                                                const EdgeInsets.fromLTRB(
                                                  12,
                                                  0,
                                                  12,
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
                                      ChatTypingBubble(
                                        onCancel: chat.useGuided,
                                      ),
                                    if (chat.error != null) ...[
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF4F4),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.red.withValues(
                                              alpha: .55,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.info_outline_rounded,
                                                  size: 16,
                                                  color: AppTheme.red,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    chat.error!,
                                                    style: const TextStyle(
                                                      color: AppTheme.red,
                                                      fontSize: 11.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (chat.canRetry) ...[
                                              const SizedBox(height: 8),
                                              FilledButton.tonal(
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD2E1F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1208142A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chat.connecting
                          ? 'Mencari AI lokal…'
                          : chat.mode == ChatMode.localAi
                          ? 'AI Lokal Aktif'
                          : 'Mode Terpandu SIAKAD',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 13,
                      color: AppTheme.blue,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Fokus SIAKAD · Tanpa Info Luar',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            chat.greetingName == null
                ? 'Halo! Saya siap membantu informasi di dalam SIAKAD FASILKOM. Pertanyaan di luar SIAKAD akan ditolak otomatis.'
                : 'Halo, ${chat.greetingName}! Saya terhubung dengan ringkasan data ${chat.activeRoleLabel} Anda di SIAKAD dan menolak info dari luar.',
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 6),
              title: const Text(
                'Ketersediaan layanan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.muted,
                ),
              ),
              children: [
                Text(
                  chat.capabilities.summary,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEAF3FE),
                  foregroundColor: AppTheme.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: chat.busy || chat.connecting
                    ? null
                    : chat.mode == ChatMode.localAi
                    ? chat.useGuided
                    : chat.enableAi,
                icon: Icon(
                  chat.mode == ChatMode.localAi
                      ? Icons.checklist_rounded
                      : Icons.smart_toy_rounded,
                  size: 16,
                ),
                label: Text(
                  chat.mode == ChatMode.localAi
                      ? 'Gunakan terpandu'
                      : 'Aktifkan AI lokal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickSiakadStrip() {
    final prompts = chat.quickPrompts;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F9FE),
        border: Border(top: BorderSide(color: Color(0xFFD8E5F2))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < prompts.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: chat.busy ? null : () => chat.send(prompts[i].$2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.blue.withValues(alpha: .35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 12,
                          color: AppTheme.blue.withValues(alpha: .8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          prompts[i].$1,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _composer() => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFD8E5F2), width: 1.5)),
      boxShadow: [
        BoxShadow(
          color: Color(0x1008142A),
          blurRadius: 8,
          offset: Offset(0, -2),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _input,
            minLines: 1,
            maxLines: 3,
            maxLength: 2000,
            style: const TextStyle(fontSize: 12.5),
            textInputAction: TextInputAction.send,
            onSubmitted: chat.busy ? null : (value) => chat.send(value),
            decoration: InputDecoration(
              labelText: 'Tulis pesan',
              hintText: 'Tanya seputar SIAKAD (${chat.activeRoleLabel})...',
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF6FAFE),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(
                  color: Color(0xFFC3D7EC),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(
                  color: Color(0xFFC3D7EC),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppTheme.blue, width: 2),
              ),
            ),
            onChanged: (value) => chat.input = value,
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: chat.busy ? const Color(0xFFBACCE0) : AppTheme.blue,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Kirim pesan',
            color: Colors.white,
            onPressed: chat.busy ? null : () => chat.send(_input.text),
            icon: const Icon(Icons.send_rounded, size: 20),
          ),
        ),
      ],
    ),
  );
}
