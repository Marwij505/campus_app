// Bagian tampilan chat yang digunakan ulang: pilihan bantuan dan gelembung pesan.
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import 'chat_models.dart';

class ChatHelpOptions extends StatelessWidget {
  const ChatHelpOptions({super.key, required this.onChoose});
  final ValueChanged<HelpTopic>? onChoose;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final topic in HelpTopic.values)
        OutlinedButton(
          onPressed: onChoose == null ? null : () => onChoose!(topic),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.all(12),
          ),
          child: Text(topic.label, style: const TextStyle(fontSize: 11)),
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
  Widget build(BuildContext context) => Align(
    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 680),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: message.isUser ? const Color(0xFFEAF2FC) : Colors.white,
        border: Border.all(color: AppTheme.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identitas sumber selalu ditampilkan agar AI tidak dikira dosen.
          Text(
            message.isUser
                ? 'Kamu'
                : message.label ??
                      (message.isAi
                          ? 'AI lokal · informasi umum'
                          : 'Bantuan terpandu'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.blue,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            message.text,
            style: const TextStyle(fontSize: 12, height: 1.6),
          ),
          // Pilihan bisa diketuk atau dijawab dengan nomor: hemat mengetik di HP.
          if (message.choices.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < message.choices.length; i++)
                  OutlinedButton(
                    onPressed: onPrompt == null
                        ? null
                        : () => onPrompt!(message.choices[i].prompt),
                    child: Text(
                      '${i + 1}. ${message.choices[i].label}',
                      style: const TextStyle(fontSize: 11),
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
                  OutlinedButton(
                    onPressed: onChoose == null
                        ? null
                        : () => onChoose!(action),
                    child: Text(
                      action.label,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
