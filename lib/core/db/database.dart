import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Owners, Horses, Treatments, TreatmentPhotos, Appointments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(owners, owners.kategorie);
        await m.addColumn(horses, horses.animalType);
        await m.addColumn(horses, horses.kategorie);
        // Appointments changed horseId → ownerId and added income columns
        await m.drop(appointments);
        await m.create(appointments);
      }
    },
  );

  // --- Owners ---
  Future<List<Owner>> getAllOwners() =>
      (select(owners)..where((o) => o.isArchived.equals(false))
        ..orderBy([(o) => OrderingTerm.asc(o.name)])).get();

  Future<Owner> getOwner(int id) =>
      (select(owners)..where((o) => o.id.equals(id))).getSingle();

  Future<int> insertOwner(OwnersCompanion entry) => into(owners).insert(entry);

  Future<bool> updateOwner(OwnersCompanion entry) => update(owners).replace(entry);

  Future<void> archiveOwner(int id) =>
      (update(owners)..where((o) => o.id.equals(id)))
          .write(const OwnersCompanion(isArchived: Value(true)));

  // --- Horses ---
  Future<List<Horse>> getHorsesForOwner(int ownerId) =>
      (select(horses)
            ..where((h) => h.ownerId.equals(ownerId) & h.isArchived.equals(false))
            ..orderBy([(h) => OrderingTerm.asc(h.name)]))
          .get();

  Future<Horse> getHorse(int id) =>
      (select(horses)..where((h) => h.id.equals(id))).getSingle();

  Future<int> countHorsesForOwner(int ownerId) async {
    final count = horses.id.count();
    final query = selectOnly(horses)
      ..addColumns([count])
      ..where(horses.ownerId.equals(ownerId) & horses.isArchived.equals(false));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> countAllHorses() async {
    final count = horses.id.count();
    final query = selectOnly(horses)
      ..addColumns([count])
      ..where(horses.isArchived.equals(false));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> insertHorse(HorsesCompanion entry) => into(horses).insert(entry);

  Future<bool> updateHorse(HorsesCompanion entry) => update(horses).replace(entry);

  Future<void> archiveHorse(int id) =>
      (update(horses)..where((h) => h.id.equals(id)))
          .write(const HorsesCompanion(isArchived: Value(true)));

  // --- Treatments ---
  Future<List<Treatment>> getTreatmentsForHorse(int horseId) =>
      (select(treatments)
            ..where((t) => t.horseId.equals(horseId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Future<Treatment?> getLastTreatmentForHorse(int horseId) =>
      (select(treatments)
            ..where((t) => t.horseId.equals(horseId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(1))
          .getSingleOrNull();

  Future<int> insertTreatment(TreatmentsCompanion entry) =>
      into(treatments).insert(entry);

  Future<bool> updateTreatment(TreatmentsCompanion entry) =>
      update(treatments).replace(entry);

  // --- Treatment Photos ---
  Future<List<TreatmentPhoto>> getPhotosForTreatment(int treatmentId) =>
      (select(treatmentPhotos)
            ..where((p) => p.treatmentId.equals(treatmentId)))
          .get();

  Future<List<TreatmentPhoto>> getPhotosForHorse(int horseId) async {
    final horseTreatments = await getTreatmentsForHorse(horseId);
    final result = <TreatmentPhoto>[];
    for (final t in horseTreatments) {
      final photos = await getPhotosForTreatment(t.id);
      result.addAll(photos);
    }
    return result;
  }

  Future<int> insertTreatmentPhoto(TreatmentPhotosCompanion entry) =>
      into(treatmentPhotos).insert(entry);

  Future<void> deleteTreatmentPhoto(int id) =>
      (delete(treatmentPhotos)..where((p) => p.id.equals(id))).go();

  // --- Appointments ---
  Future<List<Appointment>> getAppointmentsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(appointments)
          ..where((a) =>
              a.scheduledAt.isBiggerOrEqualValue(start) &
              a.scheduledAt.isSmallerThanValue(end))
          ..orderBy([(a) => OrderingTerm.asc(a.scheduledAt)]))
        .get();
  }

  Future<List<Appointment>> getAppointmentsForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return (select(appointments)
          ..where((a) =>
              a.scheduledAt.isBiggerOrEqualValue(start) &
              a.scheduledAt.isSmallerThanValue(end))
          ..orderBy([(a) => OrderingTerm.asc(a.scheduledAt)]))
        .get();
  }

  Future<List<Appointment>> getAppointmentsForOwner(int ownerId) =>
      (select(appointments)
            ..where((a) => a.ownerId.equals(ownerId))
            ..orderBy([(a) => OrderingTerm.desc(a.scheduledAt)]))
          .get();

  Future<List<Appointment>> getUpcomingAppointments({int limit = 5}) {
    final now = DateTime.now();
    return (select(appointments)
          ..where((a) => a.scheduledAt.isBiggerOrEqualValue(now) & a.isDone.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.scheduledAt)])
          ..limit(limit))
        .get();
  }

  Future<int> countAppointmentsThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final count = appointments.id.count();
    final query = selectOnly(appointments)
      ..addColumns([count])
      ..where(appointments.scheduledAt.isBiggerOrEqualValue(start) &
          appointments.scheduledAt.isSmallerThanValue(end));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> insertAppointment(AppointmentsCompanion entry) =>
      into(appointments).insert(entry);

  Future<bool> updateAppointment(AppointmentsCompanion entry) =>
      update(appointments).replace(entry);

  Future<void> deleteAppointment(int id) =>
      (delete(appointments)..where((a) => a.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hufpflege.db'));
    return NativeDatabase.createInBackground(file);
  });
}
