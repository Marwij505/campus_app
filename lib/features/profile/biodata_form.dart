// Satu mesin formulir untuk lima bagian, supaya aturan simpan dan error seragam.
import 'package:flutter/material.dart';

import '../../data/biodata_fields.dart';
import '../../data/biodata_repository.dart';
import '../../data/profile_repository.dart';
import '../../data/student_profile.dart';

class BiodataForm extends StatefulWidget {
  const BiodataForm({
    super.key,
    required this.section,
    required this.repository,
    required this.student,
    required this.onSaved,
    required this.onDirty,
  });
  final BiodataSection section;
  final BiodataRepository repository;
  final StudentProfile student;
  final Future<void> Function() onSaved;
  final ValueChanged<bool> onDirty;
  @override
  State<BiodataForm> createState() => _BiodataFormState();
}

class _BiodataFormState extends State<BiodataForm> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  Map<String, dynamic> _row = {};
  bool _loading = true, _editing = false, _saving = false, _loaded = false;
  String? _error, _message;
  @override
  void initState() {
    super.initState();
    for (final f in widget.section.fields) {
      _controllers[f.key] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _restore() {
    for (final f in widget.section.fields) {
      final value = widget.section.key == 'biodata' && f.key == 'phone'
          ? widget.student.phone
          : _row[f.key];
      _controllers[f.key]!.text =
          value?.toString() ??
          (f.key == 'private_email' && _row.isEmpty
              ? widget.student.email ?? ''
              : '');
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final row = await widget.repository.loadSection(widget.section);
      if (!mounted) return;
      _row = row;
      _loaded = true;
      _restore();
    } catch (_) {
      if (mounted) {
        _error = 'Data belum dapat dimuat. Periksa koneksi, lalu coba lagi.';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    try {
      final row = await widget.repository.saveSection(
        widget.section,
        _controllers.map((key, value) => MapEntry(key, value.text)),
        _row['updated_at'] as String?,
      );
      if (!mounted) return;
      _row = row;
      _editing = false;
      widget.onDirty(false);
      _message = '${widget.section.label} berhasil disimpan.';
      // Sinkronkan nomor WhatsApp dan ringkasan profil ke beranda setelah DB sukses.
      try {
        await widget.onSaved();
      } catch (_) {
        _message =
            'Data tersimpan. Ringkasan belum diperbarui; tekan Muat ulang.';
      }
    } catch (e) {
      if (mounted) _error = e is ProfileException ? e.message : 'Belum berhasil disimpan. Isian tetap tersedia. Periksa koneksi atau masuk ulang bila sesi berakhir.';
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(BiodataField field) {
    final controller = _controllers[field.key]!;
    final disabledDetail =
        widget.section.key == 'accessibility' &&
        field.key != 'has_disability' &&
        _controllers['has_disability']!.text != 'Ya';
    if (disabledDetail) return const SizedBox.shrink();
    Widget input;
    if (!_editing) {
      final value = controller.text;
      input = SelectableText(
        value.isEmpty ? 'Belum diisi' : value,
        style: TextStyle(color: value.isEmpty ? Colors.blueGrey : null),
      );
    } else if (field.options.isNotEmpty) {
      input = DropdownButtonFormField<String>(
        initialValue: field.options.contains(controller.text)
            ? controller.text
            : '',
        isExpanded: true,
        hint: const Text('Pilih'),
        items: ['', ...field.options]
            .map(
              (v) => DropdownMenuItem(
                value: v,
                child: Text(
                  v.isEmpty ? 'Belum diisi' : v,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: _saving
            ? null
            : (v) => setState(() => controller.text = v ?? ''),
        validator: (value) => field.validate(value ?? ''),
      );
    } else {
      input = TextFormField(
        key: ValueKey(field.key),
        controller: controller,
        enabled: !_saving,
        maxLength: field.maxLength,
        readOnly: field.kind == 'date',
        minLines: field.kind == 'long' ? 2 : 1,
        maxLines: field.kind == 'long' ? 4 : 1,
        keyboardType: field.kind == 'phone'
            ? TextInputType.phone
            : field.kind == 'email'
            ? TextInputType.emailAddress
            : ['score', 'nik', 'nisn', 'postal', 'digits'].contains(field.kind)
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          counterText: '',
          hintText: field.kind == 'phone' ? '08… atau +kode negara' : null,
          suffixIcon: field.kind == 'date'
              ? IconButton(
                  tooltip: controller.text.isEmpty
                      ? 'Pilih tanggal'
                      : 'Kosongkan tanggal',
                  onPressed: controller.text.isEmpty || _saving
                      ? null
                      : () => setState(() => controller.clear()),
                  icon: Icon(
                    controller.text.isEmpty
                        ? Icons.calendar_month_outlined
                        : Icons.clear,
                  ),
                )
              : null,
        ),
        validator: (v) => field.validate(v ?? ''),
        onTap: field.kind != 'date'
            ? null
            : () async {
                final now = DateTime.now();
                final parsed = DateTime.tryParse(controller.text);
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1900),
                  lastDate: now,
                  initialDate:
                      parsed != null &&
                          !parsed.isAfter(now) &&
                          parsed.year >= 1900
                      ? parsed
                      : DateTime(now.year - 18),
                );
                if (date != null && mounted) {
                  setState(
                    () => controller.text = date.toIso8601String().substring(
                      0,
                      10,
                    ),
                  );
                }
              },
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDFE6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF586A7B),
            ),
          ),
          const SizedBox(height: 8),
          input,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.section.fields.map((f) => f.group).toSet();
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 8,
            children: [
              if (_editing) ...[
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0C9A4C),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Menyimpan…' : 'Simpan'),
                ),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () {
                          setState(() {
                            _restore();
                            _editing = false;
                            _error = null;
                          });
                          widget.onDirty(false);
                        },
                  child: const Text('Batal'),
                ),
              ] else ...[
                TextButton.icon(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat ulang'),
                ),
                FilledButton.icon(
                  onPressed: !_loaded || _loading
                      ? null
                      : () {
                          setState(() {
                            _editing = true;
                            _message = null;
                          });
                          widget.onDirty(true);
                        },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ],
            ],
          ),
          const Divider(height: 30),
          if (_loading || _saving) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _message!,
                style: const TextStyle(color: Color(0xFF08773C)),
              ),
            ),
          if (_loaded) ...[
            if (_editing)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Lengkapi data sesuai dokumenmu. Bagian yang belum diketahui boleh dikosongkan.',
                ),
              ),
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  group,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF155BC0),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, bounds) {
                  final two =
                      bounds.maxWidth >= 640 &&
                      MediaQuery.textScalerOf(context).scale(1) < 1.5;
                  // Alamat mengikuti referensi: jalan selebar panel, rincian
                  // pendek empat kolom di desktop; HP tetap satu kolom.
                  final address = group.startsWith('Alamat');
                  final columns = address && bounds.maxWidth >= 800 && two
                      ? 4
                      : (two ? 2 : 1);
                  return Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      for (final f in widget.section.fields.where(
                        (f) => f.group == group,
                      ))
                        SizedBox(
                          width: address && f.key == 'street'
                              ? bounds.maxWidth
                              : (bounds.maxWidth - 16 * (columns - 1)) /
                                    columns,
                          child: _field(f),
                        ),
                    ],
                  );
                },
              ),
              if (group == 'Kontak') ...[
                const SizedBox(height: 12),
                SelectableText(
                  'Email kampus: ${widget.student.campusEmail ?? 'Belum tersedia'}',
                ),
                const SizedBox(height: 6),
                SelectableText(
                  'Email login / pemulihan: ${widget.student.email ?? 'Belum tersedia'}',
                ),
                const Text(
                  'Mengubah email pribadi di biodata tidak mengubah email login. Email kampus dikelola kampus.',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
