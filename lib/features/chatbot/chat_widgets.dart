// Bagian tampilan chat yang digunakan ulang: pilihan bantuan dan gelembung pesan
// dengan tema retro pixel SIAKAD yang ramah pengguna.
import 'package:flutter/material.dart';

import '../../core/app_motion.dart';
import '../../core/app_theme.dart';
import 'chat_models.dart';

class ChatHelpOptions extends StatelessWidget {
  const ChatHelpOptions({super.key, required this.onChoose});
  final ValueChanged<HelpTopic>? onChoose;

  static IconData _iconFor(HelpTopic topic) => switch (topic) {
    HelpTopic.academic => Icons.school_outlined,
    HelpTopic.contact => Icons.contact_mail_outlined,
    HelpTopic.letter => Icons.description_outlined,
    HelpTopic.issue => Icons.report_problem_outlined,
    HelpTopic.files => Icons.attach_file,
    HelpTopic.records => Icons.bar_chart_outlined,
    HelpTopic.study => Icons.menu_book_outlined,
  };

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final topic in HelpTopic.values)
        OutlinedButton.icon(
          onPressed: onChoose == null ? null : () => onChoose!(topic),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.ink,
            side: const BorderSide(color: AppTheme.ink, width: 2),
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          ),
          icon: Icon(_iconFor(topic), size: 15, color: AppTheme.blue),
          label: Text(
            topic.label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
        ? const Color(0xFFEAF2FC)
        : isOutOfScope
        ? const Color(0xFFFFF8E8)
        : Colors.white;
    final accentColor = message.isUser
        ? AppTheme.blue
        : isOutOfScope
        ? const Color(0xFFED7D21)
        : message.isAi
        ? const Color(0xFF198754)
        : AppTheme.blue;

    return Entrance(
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: isOutOfScope ? const Color(0xFFED7D21) : AppTheme.ink,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0xFFC5CFD4), offset: Offset(3, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: .14),
                      border: Border.all(color: accentColor, width: 1.5),
                    ),
                    child: Icon(
                      message.isUser
                          ? Icons.person_outline
                          : isOutOfScope
                          ? Icons.shield_outlined
                          : Icons.smart_toy_outlined,
                      size: 13,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message.isUser
                          ? 'Kamu'
                          : message.label ??
                                (message.isAi
                                    ? 'AI lokal · khusus SIAKAD'
                                    : 'Asisten SIAKAD'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(
                message.text,
                style: const TextStyle(fontSize: 12, height: 1.6),
              ),
              if (message.choices.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < message.choices.length; i++)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF6FAFF),
                          foregroundColor: AppTheme.blue,
                          side: const BorderSide(
                            color: AppTheme.blue,
                            width: 1.5,
                          ),
                          shape: const RoundedRectangleBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
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
                            color: AppTheme.ink,
                            width: 1.5,
                          ),
                          shape: const RoundedRectangleBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
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
