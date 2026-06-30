import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/database.dart';
import '../../core/db/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/status_chip.dart';

final _horseDetailProvider = FutureProvider.family<Horse, int>((ref, id) {
  return ref.watch(databaseProvider).getHorse(id);
});

final _horseTreatmentsProvider = FutureProvider.family<List<Treatment>, int>((ref, horseId) {
  return ref.watch(databaseProvider).getTreatmentsForHorse(horseId);
});

final _horseOwnerAppointmentsProvider = FutureProvider.family<List<Appointment>, int>((ref, horseId) async {
  final db = ref.watch(databaseProvider);
  final horse = await db.getHorse(horseId);
  return db.getAppointmentsForOwner(horse.ownerId);
});

final _horsePhotosProvider = FutureProvider.family<List<TreatmentPhoto>, int>((ref, horseId) {
  return ref.watch(databaseProvider).getPhotosForHorse(horseId);
});

class HorseDetailScreen extends ConsumerStatefulWidget {
  final int horseId;
  const HorseDetailScreen({super.key, required this.horseId});

  @override
  ConsumerState<HorseDetailScreen> createState() => _HorseDetailScreenState();
}

class _HorseDetailScreenState extends ConsumerState<HorseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horseAsync = ref.watch(_horseDetailProvider(widget.horseId));

    return horseAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Fehler: $e'))),
      data: (horse) => _HorseView(horse: horse, tabs: _tabs),
    );
  }
}

class _HorseView extends ConsumerWidget {
  final Horse horse;
  final TabController tabs;
  const _HorseView({required this.horse, required this.tabs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Text(horse.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/horses/${horse.id}/edit', extra: horse).then((_) {
                  ref.invalidate(_horseDetailProvider(horse.id));
                }),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroHeader(horse: horse),
            ),
            bottom: TabBar(
              controller: tabs,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Verlaufsakte'),
                Tab(text: 'Termine'),
                Tab(text: 'Fotos'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: tabs,
          children: [
            _TreatmentTab(horseId: horse.id),
            _AppointmentTab(horseId: horse.id),
            _PhotoTab(horseId: horse.id),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/horses/${horse.id}/treatments/new')
            .then((_) => ref.invalidate(_horseTreatmentsProvider(horse.id))),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final Horse horse;
  const _HeroHeader({required this.horse});

  @override
  Widget build(BuildContext context) {
    final photoPath = horse.photoPath;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photoPath != null && File(photoPath).existsSync())
          Image.file(File(photoPath), fit: BoxFit.cover)
        else
          Container(
            color: AppColors.primaryContainer,
            child: const Center(child: Icon(Icons.pets, size: 64, color: AppColors.onPrimaryContainer)),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
            ),
          ),
        ),
        Positioned(
          bottom: 56,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                horse.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                [
                  if (horse.animalType != 'Pferd') horse.animalType,
                  if (horse.breed != null) horse.breed!,
                  if (horse.birthYear != null) '${DateTime.now().year - horse.birthYear!} Jahre',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TreatmentTab extends ConsumerWidget {
  final int horseId;
  const _TreatmentTab({required this.horseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentsAsync = ref.watch(_horseTreatmentsProvider(horseId));

    return treatmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (treatments) {
        if (treatments.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.medical_services_outlined, size: 48, color: AppColors.outlineVariant),
                const SizedBox(height: 12),
                Text('Noch keine Einträge.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: treatments.length,
          itemBuilder: (ctx, i) => _TreatmentCard(
            treatment: treatments[i],
            onTap: () => context.push('/treatments/${treatments[i].id}/edit', extra: treatments[i])
                .then((_) => ref.invalidate(_horseTreatmentsProvider(horseId))),
          ),
        );
      },
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final Treatment treatment;
  final VoidCallback onTap;
  const _TreatmentCard({required this.treatment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAkut = treatment.treatmentType == 'Akutbehandlung';
    final status = isAkut ? TreatmentStatus.akut : TreatmentStatus.regular;
    final day = DateFormat('dd', 'de_DE').format(treatment.date);
    final month = DateFormat('MMM', 'de_DE').format(treatment.date).toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: isAkut ? AppColors.chipAkutText : AppColors.primary,
              width: 3,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    Text(day, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text(month, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            treatment.treatmentType,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusChip(label: isAkut ? 'AKUT' : 'REGULÄR', status: status),
                      ],
                    ),
                    if (treatment.findings != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        treatment.findings!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentTab extends ConsumerWidget {
  final int horseId;
  const _AppointmentTab({required this.horseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(_horseOwnerAppointmentsProvider(horseId));

    return apptAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (appts) {
        if (appts.isEmpty) {
          return Center(
            child: Text('Keine Termine für diesen Besitzer.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appts.length,
          itemBuilder: (ctx, i) {
            final a = appts[i];
            final fmt = DateFormat('dd.MM.yyyy HH:mm', 'de_DE');
            final total = a.einnahmeAnfahrt + a.einnahmeProTier + a.einnahmeTrinkgeld;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.event, color: AppColors.primary),
                title: Text(a.type),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmt.format(a.scheduledAt)),
                    if (total > 0)
                      Text('${total.toStringAsFixed(2)} €', style: const TextStyle(color: AppColors.secondary)),
                  ],
                ),
                trailing: StatusChip.fromString(a.isDone ? 'Regulär' : 'Geplant'),
              ),
            );
          },
        );
      },
    );
  }
}

class _PhotoTab extends ConsumerWidget {
  final int horseId;
  const _PhotoTab({required this.horseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(_horsePhotosProvider(horseId));

    return photosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (photos) {
        final existing = photos.where((p) => File(p.path).existsSync()).toList();
        if (existing.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library_outlined, size: 48, color: AppColors.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  'Noch keine Fotos vorhanden.\nFotos können beim Behandlungseintrag hinzugefügt werden.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: existing.length,
          itemBuilder: (ctx, i) => GestureDetector(
            onTap: () => _showFullscreen(context, existing, i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(existing[i].path),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFullscreen(BuildContext context, List<TreatmentPhoto> photos, int initial) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullscreenGallery(photos: photos, initialIndex: initial),
    ));
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<TreatmentPhoto> photos;
  final int initialIndex;
  const _FullscreenGallery({required this.photos, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${widget.initialIndex + 1} / ${widget.photos.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        itemBuilder: (ctx, i) => InteractiveViewer(
          child: Center(
            child: Image.file(File(widget.photos[i].path)),
          ),
        ),
      ),
    );
  }
}
