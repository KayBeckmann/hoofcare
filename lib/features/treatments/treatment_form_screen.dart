import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/db/database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_theme.dart';

const _treatmentTypes = [
  'Barhuf-Pflege',
  'Beschlag',
  'Routinepflege',
  'Akutbehandlung',
  'Erstbesuch',
  'Kontrolle',
  'Sonstiges',
];

class TreatmentFormScreen extends ConsumerStatefulWidget {
  final int horseId;
  final Treatment? treatment;

  const TreatmentFormScreen({super.key, required this.horseId, this.treatment});

  @override
  ConsumerState<TreatmentFormScreen> createState() => _TreatmentFormScreenState();
}

class _TreatmentFormScreenState extends ConsumerState<TreatmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late DateTime _date;
  late final TextEditingController _findings;
  late final TextEditingController _measures;
  late final TextEditingController _notes;
  List<String> _photoPaths = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.treatment;
    _type = t?.treatmentType ?? _treatmentTypes.first;
    _date = t?.date ?? DateTime.now();
    _findings = TextEditingController(text: t?.findings ?? '');
    _measures = TextEditingController(text: t?.measures ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
  }

  @override
  void dispose() {
    _findings.dispose();
    _measures.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photoPaths.length >= 8) return;
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, 'treatments', '${DateTime.now().millisecondsSinceEpoch}.jpg');
    await Directory(p.dirname(dest)).create(recursive: true);
    await File(img.path).copy(dest);
    setState(() => _photoPaths.add(dest));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    int treatmentId;
    if (widget.treatment == null) {
      treatmentId = await db.insertTreatment(TreatmentsCompanion(
        horseId: Value(widget.horseId),
        date: Value(_date),
        treatmentType: Value(_type),
        findings: Value(_findings.text.trim().isEmpty ? null : _findings.text.trim()),
        measures: Value(_measures.text.trim().isEmpty ? null : _measures.text.trim()),
        notes: Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
      ));
    } else {
      await db.updateTreatment(TreatmentsCompanion(
        id: Value(widget.treatment!.id),
        horseId: Value(widget.horseId),
        date: Value(_date),
        treatmentType: Value(_type),
        findings: Value(_findings.text.trim().isEmpty ? null : _findings.text.trim()),
        measures: Value(_measures.text.trim().isEmpty ? null : _measures.text.trim()),
        notes: Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
        createdAt: Value(widget.treatment!.createdAt),
      ));
      treatmentId = widget.treatment!.id;
    }

    for (final path in _photoPaths) {
      await db.insertTreatmentPhoto(TreatmentPhotosCompanion(
        treatmentId: Value(treatmentId),
        path: Value(path),
      ));
    }

    if (mounted) context.pop();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.treatment == null;
    final dateFmt = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isNew ? 'Neuer Eintrag' : 'Eintrag bearbeiten'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saving ? null : _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Datum
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(dateFmt.format(_date), style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Behandlungsart
            Text('Behandlungsart', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(),
              items: _treatmentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),

            // Befund
            _textArea('Befund', _findings, hint: 'Zustand der Hufe beschreiben...'),
            const SizedBox(height: 16),

            // Maßnahmen
            _textArea('Maßnahmen', _measures, hint: 'Durchgeführte Arbeiten eintragen...'),
            const SizedBox(height: 16),

            // Fotos
            Text('Fotos (Dokumentation)', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            _PhotoPicker(paths: _photoPaths, onAdd: _pickPhoto, onRemove: (i) => setState(() => _photoPaths.removeAt(i))),
            const SizedBox(height: 16),

            // Notizen
            _textArea('Notizen (Optional)', _notes, hint: 'Zusätzliche Anmerkungen...'),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Speichern & Termin planen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textArea(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: 4,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final List<String> paths;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _PhotoPicker({required this.paths, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...paths.asMap().entries.map((e) => _PhotoThumb(
                path: e.value,
                onRemove: () => onRemove(e.key),
              )),
          if (paths.length < 8)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant, style: BorderStyle.solid),
                ),
                child: paths.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                        ],
                      )
                    : const Icon(Icons.add, color: AppColors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _PhotoThumb({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(File(path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
