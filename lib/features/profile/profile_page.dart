// Biodata mengikuti satu state AuthService sehingga perubahan juga terlihat di beranda.
// Ringkasan di kiri dan tujuh bagian di kanan mengikuti susunan referensi SIAKAD.
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/auth_service.dart';
import '../../data/biodata_fields.dart';
import '../../shared/student_profile_avatar.dart';
import '../auth/reset_password_page.dart';
import '../chatbot/chat_controller.dart';
import '../chatbot/chat_launcher.dart';
import 'edit_profile_page.dart';
import 'biodata_form.dart';
import 'profile_records.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.service, this.chat});
  final AuthService service;
  final ChatController? chat;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _section = 0;
  bool _dirty = false;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<bool> _canLeave() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tinggalkan perubahan?'),
            content: const Text('Perubahan yang belum disimpan akan dibuang.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tetap mengedit'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Buang perubahan'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _refresh() async {
    final profile = await widget.service.profiles!.load();
    if (mounted) widget.service.acceptProfile(profile);
  }

  Future<void> _preferences() async {
    if (!await _canLeave() || !mounted) return;
    setState(() => _dirty = false);
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => EditProfilePage(
          student: widget.service.currentUser!,
          repository: widget.service.profiles!,
          onSaved: widget.service.acceptProfile,
          chat: widget.chat,
        ),
      ),
    );
    if (mounted) setState(() => _reload++);
  }

  int _reload = 0;
  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x120B355F),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Material(color: Colors.transparent, child: child),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.service,
    builder: (context, _) {
      final p = widget.service.currentUser;
      if (p == null) return const SizedBox.shrink();
      final repository = widget.service.profiles?.biodata;
      final identity = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF1662BE), Color(0xFF12459C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    StudentProfileAvatar(
                      variant: p.avatarVariant,
                      photo: p.avatarBytes,
                      size: 148,
                    ),
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: IconButton.filled(
                        tooltip: 'Edit foto dan nama panggilan',
                        onPressed: _preferences,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8800),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  p.name ?? 'Mahasiswa',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(p.nim, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                Text(
                  p.status ?? 'Status akademik belum tersedia',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (final item in <(String, Object?)>[
                        ('Prodi', p.major),
                        ('Fakultas', p.faculty),
                        (
                          'Dosen wali',
                          p.advisor == null
                              ? null
                              : '${p.advisor}${p.advisorCode == null ? '' : ' (${p.advisorCode})'}',
                        ),
                        ('Periode daftar', p.enrollmentPeriod),
                        ('Basis', p.studyBasis),
                        ('Gelombang', p.admissionWave),
                        ('Status masuk', p.admissionStatus),
                        ('Semester', p.semester),
                        ('IPK', p.gpa),
                        ('SKS lulus', p.passedCredits),
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.$1,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.$2?.toString() ?? '—',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            Column(
              children: [
                for (final item in [
                  (0, 'Biodata', Icons.person_outline),
                  (1, 'Pendidikan', Icons.school_outlined),
                  (2, 'Keluarga', Icons.family_restroom),
                  (3, 'Pekerjaan', Icons.work_outline),
                  (4, 'Disabilitas', Icons.accessible),
                  (5, 'Riwayat Keuangan', Icons.receipt_long_outlined),
                  (6, 'Berkas', Icons.folder_outlined),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      leading: Icon(item.$3, size: 22),
                      title: Text(
                        item.$2,
                        style: const TextStyle(fontSize: 13),
                      ),
                      selected: _section == item.$1,
                      selectedColor: Colors.white,
                      selectedTileColor: const Color(0xFF155BC0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () async {
                        if (_section == item.$1 ||
                            !await _canLeave() ||
                            !mounted) {
                          return;
                        }
                        setState(() {
                          _section = item.$1;
                          _dirty = false;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            p.verificationStatus == 'verified'
                ? 'Terverifikasi'
                : 'Belum diverifikasi',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
          TextButton(
            onPressed: _preferences,
            child: const Text('Edit foto / nama panggilan'),
          ),
          TextButton(
            onPressed: () async {
              if (!await _canLeave() || !context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ResetPasswordPage(
                    service: widget.service,
                    chat: widget.chat,
                  ),
                ),
              );
            },
            child: const Text('Ubah password'),
          ),
        ],
      );
      final content = _card(
        repository == null
            ? const Text(
                'Biodata memerlukan sesi Supabase. Silakan masuk dengan akun mahasiswa.',
              )
            : _section < 5
            ? BiodataForm(
                key: ValueKey('$_section-$_reload'),
                section: biodataSections[_section],
                repository: repository,
                student: p,
                onSaved: _refresh,
                onDirty: (v) => setState(() => _dirty = v),
              )
            : ProfileRecords(
                key: ValueKey(_section),
                repository: repository,
                documents: _section == 6,
                chat: widget.chat,
              ),
      );
      // Tema lokal: struktur referensi tanpa mengubah halaman SIAKAD lainnya.
      final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCAD7E5)),
      );
      return PopScope(
        canPop: !_dirty,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop || !await _canLeave() || !context.mounted) return;
          setState(() => _dirty = false);
          if (context.mounted) Navigator.pop(context);
        },
        child: Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: const BorderSide(
                  color: Color(0xFF155BC0),
                  width: 2,
                ),
              ),
              errorBorder: border.copyWith(
                borderSide: const BorderSide(color: Colors.red),
              ),
              contentPadding: const EdgeInsets.all(12),
              errorMaxLines: 3,
            ),
          ),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Biodata mahasiswa'),
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
            ),
            floatingActionButton: widget.chat == null
                ? null
                : ChatLauncher(controller: widget.chat!),
            backgroundColor: const Color(0xFFF0F3F7),
            body: SafeArea(
              child: SingleChildScrollView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1560),
                    child: LayoutBuilder(
                      builder: (context, bounds) {
                        if (bounds.maxWidth >= 1000 &&
                            MediaQuery.textScalerOf(context).scale(1) < 1.5) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 340, child: identity),
                              const SizedBox(width: 24),
                              Expanded(child: content),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            identity,
                            const SizedBox(height: 20),
                            content,
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
