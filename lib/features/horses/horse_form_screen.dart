import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/db/database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/horse_avatar.dart';

class HorseFormScreen extends ConsumerStatefulWidget {
  final int ownerId;
  final Horse? horse;

  const HorseFormScreen({super.key, required this.ownerId, this.horse});

  @override
  ConsumerState<HorseFormScreen> createState() => _HorseFormScreenState();
}

class _HorseFormScreenState extends ConsumerState<HorseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _birthYear;
  late final TextEditingController _notes;
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final h = widget.horse;
    _name = TextEditingController(text: h?.name ?? '');
    _breed = TextEditingController(text: h?.breed ?? '');
    _birthYear = TextEditingController(text: h?.birthYear?.toString() ?? '');
    _notes = TextEditingController(text: h?.notes ?? '');
    _photoPath = h?.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _birthYear.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dest = p.join(dir.path, 'horses', '${DateTime.now().millisecondsSinceEpoch}.jpg');
    await Directory(p.dirname(dest)).create(recursive: true);
    await File(img.path).copy(dest);
    setState(() => _photoPath = dest);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final year = int.tryParse(_birthYear.text.trim());

    if (widget.horse == null) {
      await db.insertHorse(HorsesCompanion(
        ownerId: Value(widget.ownerId),
        name: Value(_name.text.trim()),
        breed: Value(_breed.text.trim().isEmpty ? null : _breed.text.trim()),
        birthYear: Value(year),
        notes: Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
        photoPath: Value(_photoPath),
      ));
    } else {
      await db.updateHorse(HorsesCompanion(
        id: Value(widget.horse!.id),
        ownerId: Value(widget.ownerId),
        name: Value(_name.text.trim()),
        breed: Value(_breed.text.trim().isEmpty ? null : _breed.text.trim()),
        birthYear: Value(year),
        notes: Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
        photoPath: Value(_photoPath),
        isArchived: Value(widget.horse!.isArchived),
        createdAt: Value(widget.horse!.createdAt),
      ));
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.horse == null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isNew ? 'Neues Pferd' : 'Pferd bearbeiten'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saving ? null : _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    HorseAvatar(photoPath: _photoPath, radius: 48),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.secondary,
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _field('Name *', _name, required: true),
            const SizedBox(height: 12),
            _field('Rasse', _breed),
            const SizedBox(height: 12),
            _field('Geburtsjahr', _birthYear, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field('Besonderheiten / Notizen', _notes, maxLines: 4),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(isNew ? 'Pferd anlegen' : 'Änderungen speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null : null,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }
}
