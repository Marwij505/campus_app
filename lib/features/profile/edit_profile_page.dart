// Pengeditan terbatas: identitas resmi tidak pernah menjadi masukan bebas.
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../data/profile_repository.dart';
import '../../data/student_profile.dart';
import '../../data/profile_photo.dart';
import '../../shared/student_profile_avatar.dart';
import '../dashboard/dashboard_detail_page.dart';
import '../chatbot/chat_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.student,
    required this.repository,
    required this.onSaved,
    this.chat,
  });
  final StudentProfile student;
  final ProfileRepository repository;
  final ValueChanged<StudentProfile> onSaved;
  final ChatController? chat;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _name = TextEditingController(text: widget.student.preferredName);
  late final _phone = TextEditingController(text: widget.student.phone);
  late String _variant = widget.student.avatarVariant;
  Uint8List? _photo;
  bool _remove = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Gambar',
            extensions: [
              'jpg',
              'jpeg',
              'jfif',
              'png',
              'webp',
              'gif',
              'bmp',
              'tif',
              'tiff',
              'ico',
              'heic',
              'heif',
              'avif',
            ],
            mimeTypes: ['image/*'],
            uniformTypeIdentifiers: ['public.image'],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > ProfilePhoto.maxInputBytes) {
        throw const ProfileException('Foto maksimal 20 MB.');
      }
      final bytes = await ProfilePhoto.prepare(await file.readAsBytes());
      if (mounted) {
        setState(() {
          _photo = bytes;
          _remove = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ProfileException
              ? e.message
              : 'Foto belum dapat dipilih. Coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final changes = ProfileChanges(
      preferredName: _name.text,
      phone: _phone.text,
      avatarVariant: _variant,
      photo: _photo,
      removePhoto: _remove,
    );
    final error = changes.validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final student = await widget.repository.save(changes);
      if (!mounted) return;
      widget.onSaved(student);
      Navigator.pop(context, true);
    } catch (e) {
      // Isian tetap ada bila server gagal; jangan mengaku sukses sebelum konfirmasi.
      if (mounted) {
        setState(
          () => _error = e is ProfileException ? e.message : 'Profil belum berhasil disimpan. Periksa koneksi lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: DashboardDetailPage(
      title: 'Edit profil',
      chat: widget.chat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nama resmi, NIM, fakultas, dan program studi dikelola pengelola kampus.',
          ),
          const SizedBox(height: 20),
          Center(
            child: StudentProfileAvatar(
              variant: _variant,
              photo: _remove ? null : _photo ?? widget.student.avatarBytes,
              size: 128,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Avatar bawaan · ilustrasi, bukan data jenis kelamin'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final pair in [
                ('male', 'Pria'),
                ('female', 'Perempuan'),
                ('neutral', 'Netral'),
              ])
                Semantics(
                  selected: _variant == pair.$1,
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _variant = pair.$1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StudentProfileAvatar(variant: pair.$1, size: 64),
                          const SizedBox(height: 8),
                          Text('${_variant == pair.$1 ? '✓ ' : ''}${pair.$2}'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Pilihan avatar tidak menghapus foto. Hapus foto untuk memakai ilustrasi bawaan.',
            style: TextStyle(fontSize: 11),
          ),
          Wrap(
            spacing: 12,
            children: [
              TextButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.upload),
                label: const Text('Pilih foto · berbagai format ≤ 20 MB'),
              ),
              if (widget.student.avatarPath != null || _photo != null)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _remove = true;
                          _photo = null;
                        }),
                  child: const Text('Hapus foto'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            enabled: !_busy,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: 'Nama panggilan',
              helperText: 'Kosongkan untuk memakai nama lengkap.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            enabled: !_busy,
            maxLength: 30,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telepon (opsional)',
              hintText: '081234567890 atau +6281234567890',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Menyimpan…' : 'Simpan profil'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    ),
  );
}
