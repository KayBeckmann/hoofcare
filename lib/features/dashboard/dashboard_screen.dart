import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/status_chip.dart';

final _dashboardStatsProvider = FutureProvider<_DashStats>((ref) async {
  final db = ref.watch(databaseProvider);
  final ownerCount = (await db.getAllOwners()).length;
  final horseCount = await db.countAllHorses();
  final apptCount = await db.countAppointmentsThisMonth();
  return _DashStats(ownerCount, horseCount, apptCount);
});

final _nextAppointmentProvider = FutureProvider<_NextApptInfo?>((ref) async {
  final db = ref.watch(databaseProvider);
  final appts = await db.getUpcomingAppointments(limit: 1);
  if (appts.isEmpty) return null;
  final appt = appts.first;
  final horse = await db.getHorse(appt.horseId);
  final owner = await db.getOwner(horse.ownerId);
  return _NextApptInfo(appt, horse, owner);
});

final _recentActivityProvider = FutureProvider<List<_ActivityItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  final owners = await db.getAllOwners();
  final items = <_ActivityItem>[];

  for (final owner in owners) {
    final horses = await db.getHorsesForOwner(owner.id);
    for (final horse in horses) {
      final last = await db.getLastTreatmentForHorse(horse.id);
      if (last != null) {
        items.add(_ActivityItem(horse: horse, owner: owner, treatment: last));
      }
    }
  }

  items.sort((a, b) => b.treatment.date.compareTo(a.treatment.date));
  return items.take(5).toList();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _NextAppointmentCard()),
            SliverToBoxAdapter(child: _StatsRow()),
            SliverToBoxAdapter(child: _RecentActivity()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Guten Morgen' : hour < 18 ? 'Guten Tag' : 'Guten Abend';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                Text(
                  'Hufpflege',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: AppColors.primaryContainer,
            child: const Icon(Icons.person, color: AppColors.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _NextAppointmentCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_nextAppointmentProvider);

    return async.when(
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        if (info == null) return _EmptyNextAppt();
        return _buildCard(context, info);
      },
    );
  }

  Widget _buildCard(BuildContext context, _NextApptInfo info) {
    final fmt = DateFormat('dd.MM.yyyy, HH:mm');
    final isToday = _isToday(info.appt.scheduledAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nächster Termin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusChip.fromString('Geplant'),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                text: isToday ? 'Heute, ${DateFormat('HH:mm').format(info.appt.scheduledAt)} Uhr' : fmt.format(info.appt.scheduledAt),
              ),
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.pets, text: info.horse.name),
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.person_outline, text: info.owner.name),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/horses/${info.horse.id}'),
                  child: const Text('Details ansehen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}

class _EmptyNextAppt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.event_available, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                'Keine bevorstehenden Termine',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(_dashboardStatsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: stats.when(
        loading: () => const SizedBox(height: 80),
        error: (_, __) => const SizedBox.shrink(),
        data: (s) => Row(
          children: [
            Expanded(child: _StatCard(label: 'Kunden', value: s.ownerCount, icon: Icons.people_outline, onTap: () => context.go('/owners'))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Pferde', value: s.horseCount, icon: Icons.pets, color: AppColors.secondary)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Termine (Monat)', value: s.apptCount, icon: Icons.calendar_month_outlined, onTap: () => context.go('/appointments'))),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, size: 16, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(_recentActivityProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Letzte Aktivität',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => context.go('/owners'),
                child: const Text('Alle ansehen ›'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Noch keine Behandlungseinträge.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                );
              }
              return Column(
                children: list.map((item) => _ActivityTile(item: item)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd. MMM', 'de_DE');
    final status = statusFromString(
      item.treatment.treatmentType == 'Akutbehandlung' ? 'Akut' : 'Regulär',
    );
    final chipLabel = item.treatment.treatmentType == 'Akutbehandlung' ? 'Notfall' : item.treatment.treatmentType;

    return GestureDetector(
      onTap: () => context.push('/horses/${item.horse.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            left: BorderSide(
              color: status == TreatmentStatus.akut ? AppColors.chipAkutText : AppColors.primary,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.horse.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 12, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        fmt.format(item.treatment.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(label: chipLabel, status: status),
                const SizedBox(height: 4),
                Text(
                  item.treatment.measures?.split('\n').first ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashStats {
  final int ownerCount;
  final int horseCount;
  final int apptCount;
  _DashStats(this.ownerCount, this.horseCount, this.apptCount);
}

class _NextApptInfo {
  final Appointment appt;
  final Horse horse;
  final Owner owner;
  _NextApptInfo(this.appt, this.horse, this.owner);
}

class _ActivityItem {
  final Horse horse;
  final Owner owner;
  final Treatment treatment;
  _ActivityItem({required this.horse, required this.owner, required this.treatment});
}
