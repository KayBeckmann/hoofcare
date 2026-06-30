import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/db/database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/horse_avatar.dart';
import '../../shared/widgets/kategorie_badge.dart';

final _ownerDetailProvider = FutureProvider.family<Owner, int>((ref, id) {
  return ref.watch(databaseProvider).getOwner(id);
});

final _ownerHorsesProvider = FutureProvider.family<List<Horse>, int>((ref, ownerId) {
  return ref.watch(databaseProvider).getHorsesForOwner(ownerId);
});

class OwnerDetailScreen extends ConsumerWidget {
  final int ownerId;
  const OwnerDetailScreen({super.key, required this.ownerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerAsync = ref.watch(_ownerDetailProvider(ownerId));

    return ownerAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Fehler: $e'))),
      data: (owner) => _OwnerDetailView(owner: owner),
    );
  }
}

class _OwnerDetailView extends ConsumerWidget {
  final Owner owner;
  const _OwnerDetailView({required this.owner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horsesAsync = ref.watch(_ownerHorsesProvider(owner.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(owner.name, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            KategorieBadge(kategorie: owner.kategorie),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/owners/${owner.id}/edit', extra: owner)
                .then((_) {
                  ref.invalidate(_ownerDetailProvider(owner.id));
                  ref.invalidate(_ownerHorsesProvider(owner.id));
                }),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ContactCard(owner: owner),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tiere', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tier hinzufügen'),
                onPressed: () => context.push('/owners/${owner.id}/horses/new')
                    .then((_) => ref.invalidate(_ownerHorsesProvider(owner.id))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          horsesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Fehler: $e'),
            data: (horses) {
              if (horses.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Noch keine Tiere angelegt.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                );
              }
              return Column(
                children: horses.map((h) => _HorseTile(horse: h, onRefresh: () => ref.invalidate(_ownerHorsesProvider(owner.id)))).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Owner owner;
  const _ContactCard({required this.owner});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (owner.phone != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                title: Text(owner.phone!),
                trailing: IconButton(
                  icon: const Icon(Icons.call, color: AppColors.primary),
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: owner.phone)),
                ),
              ),
            if (owner.email != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                title: Text(owner.email!),
              ),
            if (owner.address != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                title: Text(owner.address!),
              ),
            if (owner.notes != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notes_outlined, color: AppColors.primary),
                title: Text(owner.notes!),
              ),
          ],
        ),
      ),
    );
  }
}

class _HorseTile extends StatelessWidget {
  final Horse horse;
  final VoidCallback onRefresh;
  const _HorseTile({required this.horse, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/horses/${horse.id}').then((_) => onRefresh()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            HorseAvatar(photoPath: horse.photoPath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(horse.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      KategorieBadge(kategorie: horse.kategorie),
                    ],
                  ),
                  Text(
                    [
                      if (horse.animalType != 'Pferd') horse.animalType,
                      if (horse.breed != null) horse.breed!,
                      if (horse.birthYear != null) '${horse.birthYear}',
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
