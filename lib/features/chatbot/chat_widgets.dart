// Komponen tampilan Smart Chatbot bertema ramah pengguna (friendly) dengan
// gelembung pesan lembut, tombol salin cepat, indikator mengetik beranimasi,
// dan tombol bantuan berbentuk pil yang nyaman disentuh.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import 'chat_models.dart';

class ChatHelpOptions extends StatelessWidget {
  const ChatHelpOptions({super.key, required this.onChoose});
  final ValueChanged<HelpTopic>? onChoose;

  static IconData _iconFor(HelpTopic topic) => switch (topic) {
    HelpTopic.academic => Icons.school_rounded,
    HelpTopic.contact => Icons.contact_mail_rounded,
    HelpTopic.letter => Icons.description_rounded,
    HelpTopic.issue => Icons.support_agent_rounded,
    HelpTopic.files => Icons.attach_file_rounded,
    HelpTopic.records => Icons.bar_chart_rounded,
    HelpTopic.study => Icons.menu_book_rounded,
  };

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final topic in HelpTopic.values)
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onChoose == null ? null : () => onChoose!(topic),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD2E1F0), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0E08142A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppTheme.blue.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFor(topic),
                      size: 14,
                      color: AppTheme.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    topic.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onChoose,
    this.onPrompt,
  });
  final ChatMessage message;
  final ValueChanged<HelpTopic>? onChoose;
  final ValueChanged<String>? onPrompt;

  @override
  Widget build(BuildContext context) {
    final isOutOfScope = message.label == 'Di luar lingkup SIAKAD';
    final bgColor = message.isUser
        ? const Color(0xFFE7F2FF)
        : isOutOfScope
        ? const Color(0xFFFFF8EC)
        : Colors.white;
    final borderColor = message.isUser
        ? const Color(0xFF9AC2EE)
        : isOutOfScope
        ? const Color(0xFFF3B778)
        : const Color(0xFFD7E3EE);
    final accentColor = message.isUser
        ? AppTheme.blue
        : isOutOfScope
        ? const Color(0xFFD96B16)
        : message.isAi
        ? const Color(0xFF198754)
        : AppTheme.blue;

    return Entrance(
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 660),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(message.isUser ? 18 : 6),
              bottomRight: Radius.circular(message.isUser ? 6 : 18),
            ),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1208142A),
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
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: .13),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      message.isUser
                          ? Icons.person_rounded
                          : isOutOfScope
                          ? Icons.shield_rounded
                          : Icons.smart_toy_rounded,
                      size: 15,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.isUser
                          ? 'Kamu'
                          : message.label ??
                                (message.isAi
                                    ? 'AI lokal · khusus SIAKAD'
                                    : 'Asisten SIAKAD'),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  if (!message.isUser)
                    IconButton(
                      tooltip: 'Salin jawaban',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: AppTheme.muted,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Jawaban disalin ke clipboard.'),
                            ),
                          );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                message.text,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.62,
                  color: AppTheme.ink,
                ),
              ),
              if (message.choices.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < message.choices.length; i++)
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEAF3FE),
                          foregroundColor: AppTheme.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: AppTheme.blue.withValues(alpha: .3),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: onPrompt == null
                            ? null
                            : () => onPrompt!(message.choices[i].prompt),
                        child: Text(
                          '${i + 1}. ${message.choices[i].label}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (message.actions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final action in message.actions)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.ink,
                          side: const BorderSide(
                            color: Color(0xFFBACCE0),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: onChoose == null
                            ? null
                            : () => onChoose!(action),
                        icon: Icon(
                          ChatHelpOptions._iconFor(action),
                          size: 14,
                          color: AppTheme.blue,
                        ),
                        label: Text(
                          action.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Gelembung indikator mengetik beranimasi ramah pengguna saat AI sedang berpikir.
class ChatTypingBubble extends StatefulWidget {
  const ChatTypingBubble({super.key, required this.onCancel});
  final VoidCallback onCancel;

  @override
  State<ChatTypingBubble> createState() => _ChatTypingBubbleState();
}

class _ChatTypingBubbleState extends State<ChatTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: const Color(0xFFD7E3EE), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1208142A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.blue.withValues(
                            alpha: 0.3 +
                                0.7 *
                                    (((i * 0.28 + _controller.value) % 1.0) <
                                            0.5
                                        ? ((i * 0.28 + _controller.value) %
                                                1.0) *
                                            2
                                        : (1.0 -
                                                ((i * 0.28 +
                                                        _controller.value) %
                                                    1.0)) *
                                            2),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'Menyusun jawaban dari isi SIAKAD…',
                  style: TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: widget.onCancel,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
            ),
            child: const Text(
              'Batalkan · kembali ke terpandu',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );
}
