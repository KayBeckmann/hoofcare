import 'package:drift/drift.dart';

class Owners extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  // A = Freundlich, B = Neutral, C = Schwierig
  TextColumn get kategorie => text().withDefault(const Constant('B'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Horses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ownerId => integer().references(Owners, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  // Pferd, Pony, Esel, Ziege, Schaf, Sonstiges
  TextColumn get animalType => text().withDefault(const Constant('Pferd'))();
  TextColumn get breed => text().nullable()();
  IntColumn get birthYear => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  // A = Freundlich, B = Neutral, C = Schwierig
  TextColumn get kategorie => text().withDefault(const Constant('B'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Treatments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get horseId => integer().references(Horses, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get treatmentType => text()();
  TextColumn get findings => text().nullable()();
  TextColumn get measures => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TreatmentPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get treatmentId => integer().references(Treatments, #id)();
  TextColumn get path => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Termine sind pro Besitzer, nicht pro Tier
  IntColumn get ownerId => integer().references(Owners, #id)();
  DateTimeColumn get scheduledAt => dateTime()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(60))();
  TextColumn get type => text().withDefault(const Constant('Folgebesuch'))();
  TextColumn get notes => text().nullable()();
  RealColumn get einnahmeAnfahrt => real().withDefault(const Constant(0.0))();
  RealColumn get einnahmeProTier => real().withDefault(const Constant(0.0))();
  RealColumn get einnahmeTrinkgeld => real().withDefault(const Constant(0.0))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
