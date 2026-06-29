import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/horse_avatar.dart';

final ownersProvider = FutureProvider<List<Owner>>((ref) {
  return ref.watch(databaseProvider).getAllOwners();
});

final ownerSearchProvider = StateProvider<String>((ref) => '');

class OwnersScreen extends ConsumerWidget {
  const OwnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(ownerSearchProvider);
    final ownersAsync = ref.watch(ownersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (v) => ref.read(ownerSearchProvider.notifier).state = v,
                decoration: const InputDecoration(
                  hintText: 'Kunde oder Pferd suchen...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ownersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Fehler: $e')),
                data: (owners) {
                  final filtered = search.isEmpty
                      ? owners
                      : owners.where((o) => o.name.toLowerCase().contains(search.toLowerCase())).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: AppColors.outlineVariant),
                          const SizedBox(height: 16),
                          Text(
                            search.isEmpty ? 'Noch keine Kunden angelegt.' : 'Kein Treffer für "$search".',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }

                  return _AlphaList(owners: filtered);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/owners/new').then((_) => ref.invalidate(ownersProvider)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AlphaList extends ConsumerWidget {
  final List<Owner> owners;
  const _AlphaList({required this.owners});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = <String, List<Owner>>{};
    for (final o in owners) {
      final letter = o.name.isEmpty ? '#' : o.name[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(o);
    }
    final keys = grouped.keys.toList()..sort();

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (ctx, i) {
        final letter = keys[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                letter,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            ...grouped[letter]!.map((o) => _OwnerTile(owner: o, onRefresh: () => ref.invalidate(ownersProvider))),
          ],
        );
      },
    );
  }
}

class _OwnerTile extends ConsumerWidget {
  final Owner owner;
  final VoidCallback onRefresh;
  const _OwnerTile({required this.owner, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return FutureBuilder(
      future: Future.wait([
        db.countHorsesForOwner(owner.id),
        _lastVisit(db, owner.id),
      ]),
      builder: (ctx, snap) {
        final horseCount = (snap.data?[0] as int?) ?? 0;
        final lastVisit = snap.data?[1] as DateTime?;

        return GestureDetector(
          onTap: () => context.push('/owners/${owner.id}').then((_) => onRefresh()),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const OwnerAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        owner.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$horseCount ${horseCount == 1 ? 'Pferd' : 'Pferde'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (lastVisit != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Letzter Termin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      Text(
                        _isToday(lastVisit) ? 'Heute' : DateFormat('dd. MMM', 'de_DE').format(lastVisit),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  Future<DateTime?> _lastVisit(AppDatabase db, int ownerId) async {
    final horses = await db.getHorsesForOwner(ownerId);
    DateTime? latest;
    for (final h in horses) {
      final t = await db.getLastTreatmentForHorse(h.id);
      if (t != null && (latest == null || t.date.isAfter(latest))) {
        latest = t.date;
      }
    }
    return latest;
  }
}
