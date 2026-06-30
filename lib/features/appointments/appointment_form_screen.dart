import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_theme.dart';

const _apptTypes = ['Erstbesuch', 'Folgebesuch', 'Akutbesuch', 'Kontrolle'];

final _allOwnersProvider = FutureProvider<List<Owner>>((ref) {
  return ref.watch(databaseProvider).getAllOwners();
});

class AppointmentFormScreen extends ConsumerStatefulWidget {
  final Appointment? appointment;
  final int? preselectedOwnerId;
  final DateTime? preselectedDate;

  const AppointmentFormScreen({
    super.key,
    this.appointment,
    this.preselectedOwnerId,
    this.preselectedDate,
  });

  @override
  ConsumerState<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  late DateTime _date;
  late TimeOfDay _time;
  late int _duration;
  late String _type;
  late final TextEditingController _notes;
  late final TextEditingController _einnahmeAnfahrt;
  late final TextEditingController _einnahmeProTier;
  late final TextEditingController _einnahmeTrinkgeld;
  int? _selectedOwnerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    final base = a?.scheduledAt ?? widget.preselectedDate ?? DateTime.now();
    _date = DateTime(base.year, base.month, base.day);
    _time = TimeOfDay(hour: a?.scheduledAt.hour ?? 9, minute: a?.scheduledAt.minute ?? 0);
    _duration = a?.durationMinutes ?? 60;
    _type = a?.type ?? _apptTypes[1];
    _notes = TextEditingController(text: a?.notes ?? '');
    _einnahmeAnfahrt = TextEditingController(
      text: a != null && a.einnahmeAnfahrt > 0 ? a.einnahmeAnfahrt.toStringAsFixed(2) : '',
    );
    _einnahmeProTier = TextEditingController(
      text: a != null && a.einnahmeProTier > 0 ? a.einnahmeProTier.toStringAsFixed(2) : '',
    );
    _einnahmeTrinkgeld = TextEditingController(
      text: a != null && a.einnahmeTrinkgeld > 0 ? a.einnahmeTrinkgeld.toStringAsFixed(2) : '',
    );
    _selectedOwnerId = a?.ownerId ?? widget.preselectedOwnerId;
  }

  @override
  void dispose() {
    _notes.dispose();
    _einnahmeAnfahrt.dispose();
    _einnahmeProTier.dispose();
    _einnahmeTrinkgeld.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  double _parseEuro(TextEditingController ctrl) =>
      double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0.0;

  Future<void> _save() async {
    if (_selectedOwnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte einen Kunden auswählen.')));
      return;
    }
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final scheduledAt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

    if (widget.appointment == null) {
      await db.insertAppointment(AppointmentsCompanion(
        ownerId: Value(_selectedOwnerId!),
        scheduledAt: Value(scheduledAt),
        durationMinutes: Value(_duration),
        type: Value(_type),
        notes: Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
        einnahmeAnfahrt: Value(_parseEuro(_einnahmeAnfahrt)),
        einnahmeProTier: Value(_parseEuro(_einnahmeProTier)),
        einnahmeTrinkgeld: Value(_parseEuro(_einnahmeTrinkgeld)),
      ));
    } else {
      await db.updateAppointment(AppointmentsCompanion(
        id: Value(widget.appointment!.id),
        ownerId: Value(_selectedOwnerId!),
        scheduledAt: Value(scheduledAt),
        durationMinutes: Value(_duration),
        type: Value(_type),
        notes: Value(_notes.text.trim().isEmpty ? null : _notes.text.trim()),
        einnahmeAnfahrt: Value(_parseEuro(_einnahmeAnfahrt)),
        einnahmeProTier: Value(_parseEuro(_einnahmeProTier)),
        einnahmeTrinkgeld: Value(_parseEuro(_einnahmeTrinkgeld)),
        isDone: Value(widget.appointment!.isDone),
        createdAt: Value(widget.appointment!.createdAt),
      ));
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.appointment == null;
    final dateFmt = DateFormat('dd.MM.yyyy');
    final ownersAsync = ref.watch(_allOwnersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isNew ? 'Neuer Termin' : 'Termin bearbeiten'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saving ? null : _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kunde auswählen
          Text('Kunde', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          ownersAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Fehler: $e'),
            data: (owners) => DropdownButtonFormField<int>(
              value: _selectedOwnerId,
              hint: const Text('Kunde wählen...'),
              decoration: const InputDecoration(),
              items: owners.map((o) => DropdownMenuItem(
                    value: o.id,
                    child: Text(o.name),
                  )).toList(),
              onChanged: (v) => setState(() => _selectedOwnerId = v),
            ),
          ),
          const SizedBox(height: 16),

          // Datum
          Text('Datum', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _selectDate,
            child: _infoBox(context, Icons.calendar_today_outlined, dateFmt.format(_date)),
          ),
          const SizedBox(height: 16),

          // Uhrzeit
          Text('Uhrzeit', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _selectTime,
            child: _infoBox(context, Icons.access_time, _time.format(context)),
          ),
          const SizedBox(height: 16),

          // Dauer
          Text('Dauer (Minuten)', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _duration,
            decoration: const InputDecoration(),
            items: [30, 45, 60, 90, 120].map((d) => DropdownMenuItem(value: d, child: Text('$d Min.'))).toList(),
            onChanged: (v) => setState(() => _duration = v!),
          ),
          const SizedBox(height: 16),

          // Terminart
          Text('Terminart', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(),
            items: _apptTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 16),

          // Einnahmen
          Text('Einnahmen', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _euroField('Anfahrt', _einnahmeAnfahrt)),
              const SizedBox(width: 8),
              Expanded(child: _euroField('Pro Tier', _einnahmeProTier)),
              const SizedBox(width: 8),
              Expanded(child: _euroField('Trinkgeld', _einnahmeTrinkgeld)),
            ],
          ),
          const SizedBox(height: 16),

          // Notizen
          Text('Notizen', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Optionale Anmerkungen...'),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(isNew ? 'Termin anlegen' : 'Änderungen speichern'),
          ),
        ],
      ),
    );
  }

  Widget _euroField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            suffixText: '€',
            hintText: '0.00',
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _infoBox(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
