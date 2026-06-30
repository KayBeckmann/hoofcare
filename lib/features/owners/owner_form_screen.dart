import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_theme.dart';

class OwnerFormScreen extends ConsumerStatefulWidget {
  final Owner? owner;
  const OwnerFormScreen({super.key, this.owner});

  @override
  ConsumerState<OwnerFormScreen> createState() => _OwnerFormScreenState();
}

class _OwnerFormScreenState extends ConsumerState<OwnerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _notes;
  late String _kategorie;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final o = widget.owner;
    _name = TextEditingController(text: o?.name ?? '');
    _phone = TextEditingController(text: o?.phone ?? '');
    _email = TextEditingController(text: o?.email ?? '');
    _address = TextEditingController(text: o?.address ?? '');
    _notes = TextEditingController(text: o?.notes ?? '');
    _kategorie = o?.kategorie ?? 'B';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    if (widget.owner == null) {
      await db.insertOwner(OwnersCompanion(
        name: Value(_name.text.trim()),
        phone: Value(_phone.text.trim().isEmpty ? null : _phone.text.trim()),
        email: Value(_email.text.trim().isEmpty ? null : _email.text.trim()),
        address: Value(_address.text.trim().isEmpty ? null : _address.text.trim()),
        notes: Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
        kategorie: Value(_kategorie),
      ));
    } else {
      await db.updateOwner(OwnersCompanion(
        id: Value(widget.owner!.id),
        name: Value(_name.text.trim()),
        phone: Value(_phone.text.trim().isEmpty ? null : _phone.text.trim()),
        email: Value(_email.text.trim().isEmpty ? null : _email.text.trim()),
        address: Value(_address.text.trim().isEmpty ? null : _address.text.trim()),
        notes: Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
        kategorie: Value(_kategorie),
        isArchived: Value(widget.owner!.isArchived),
        createdAt: Value(widget.owner!.createdAt),
      ));
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.owner == null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isNew ? 'Neuer Kunde' : 'Kunde bearbeiten'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('Name *', _name, required: true),
            const SizedBox(height: 12),
            _field('Telefon', _phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _field('E-Mail', _email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field('Adresse', _address, maxLines: 2),
            const SizedBox(height: 12),
            _field('Notizen', _notes, maxLines: 4),
            const SizedBox(height: 16),
            Text('Kategorie', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 8),
            _KategorieSelector(value: _kategorie, onChanged: (v) => setState(() => _kategorie = v)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(isNew ? 'Kunde anlegen' : 'Änderungen speichern'),
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

class _KategorieSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _KategorieSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'A',
          label: Text('A — Freundlich'),
          icon: Icon(Icons.sentiment_very_satisfied_outlined),
        ),
        ButtonSegment(
          value: 'B',
          label: Text('B — Neutral'),
          icon: Icon(Icons.sentiment_neutral_outlined),
        ),
        ButtonSegment(
          value: 'C',
          label: Text('C — Schwierig'),
          icon: Icon(Icons.sentiment_very_dissatisfied_outlined),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.15),
        selectedForegroundColor: AppColors.primary,
      ),
    );
  }
}
