import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/db/database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/status_chip.dart';

final _selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
final _focusedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final _dayAppointmentsProvider = FutureProvider<List<_ApptWithOwner>>((ref) async {
  final day = ref.watch(_selectedDayProvider);
  final db = ref.watch(databaseProvider);
  final appts = await db.getAppointmentsForDay(day);
  final result = <_ApptWithOwner>[];
  for (final a in appts) {
    final owner = await db.getOwner(a.ownerId);
    result.add(_ApptWithOwner(a, owner));
  }
  return result;
});

final _monthAppointmentsProvider = FutureProvider<Map<DateTime, List<Appointment>>>((ref) async {
  final month = ref.watch(_focusedMonthProvider);
  final db = ref.watch(databaseProvider);
  final appts = await db.getAppointmentsForMonth(month);
  final map = <DateTime, List<Appointment>>{};
  for (final a in appts) {
    final key = DateTime(a.scheduledAt.year, a.scheduledAt.month, a.scheduledAt.day);
    map.putIfAbsent(key, () => []).add(a);
  }
  return map;
});

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(_selectedDayProvider);
    final focusedMonth = ref.watch(_focusedMonthProvider);
    final monthAppts = ref.watch(_monthAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: TableCalendar<Appointment>(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: focusedMonth,
                selectedDayPredicate: (d) => isSameDay(d, selectedDay),
                eventLoader: (day) {
                  final key = DateTime(day.year, day.month, day.day);
                  return monthAppts.value?[key] ?? [];
                },
                onDaySelected: (selected, focused) {
                  ref.read(_selectedDayProvider.notifier).state = selected;
                  ref.read(_focusedMonthProvider.notifier).state = focused;
                },
                onPageChanged: (focused) {
                  ref.read(_focusedMonthProvider.notifier).state = focused;
                  ref.invalidate(_monthAppointmentsProvider);
                },
                locale: 'de_DE',
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  markerDecoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Termine am ${DateFormat('d. MMMM', 'de_DE').format(selectedDay)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Expanded(child: _DayAppointmentList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/appointments/new', extra: {'date': ref.read(_selectedDayProvider)})
            .then((_) {
              ref.invalidate(_dayAppointmentsProvider);
              ref.invalidate(_monthAppointmentsProvider);
            }),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DayAppointmentList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(_dayAppointmentsProvider);

    return apptAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              'Keine Termine an diesem Tag.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (ctx, i) => _ApptCard(item: items[i]),
        );
      },
    );
  }
}

class _ApptCard extends ConsumerWidget {
  final _ApptWithOwner item;
  const _ApptCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = item.appt;
    final start = DateFormat('HH:mm').format(a.scheduledAt);
    final end = DateFormat('HH:mm').format(a.scheduledAt.add(Duration(minutes: a.durationMinutes)));
    final chipLabel = a.isDone ? 'Regulär' : a.type == 'Akutbesuch' ? 'Akut' : 'Geplant';
    final total = a.einnahmeAnfahrt + a.einnahmeProTier + a.einnahmeTrinkgeld;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(start, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text('-', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                Text(end, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.owner.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      StatusChip.fromString(chipLabel),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(a.type, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                  if (item.owner.address != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.owner.address!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (total > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.euro_outlined, size: 12, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          '${total.toStringAsFixed(2)} €',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_calendar_outlined, size: 20, color: AppColors.primary),
              onPressed: () => context.push('/appointments/${a.id}/edit', extra: a)
                  .then((_) {
                    ref.invalidate(_dayAppointmentsProvider);
                    ref.invalidate(_monthAppointmentsProvider);
                  }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApptWithOwner {
  final Appointment appt;
  final Owner owner;
  _ApptWithOwner(this.appt, this.owner);
}
