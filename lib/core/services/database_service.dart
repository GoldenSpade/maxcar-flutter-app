import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// SQLite database service for local data storage
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'maxcar_tracker.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tripsTable = 'trips_local';
  static const String locationsTable = 'locations_local';

  /// Get database instance (singleton)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables on first run
  Future<void> _onCreate(Database db, int version) async {
    // Create trips_local table
    await db.execute('''
      CREATE TABLE $tripsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        distance REAL,
        duration INTEGER,
        avg_speed REAL,
        max_speed REAL,
        transport_type TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced_at INTEGER,
        modified_at INTEGER
      )
    ''');

    // Create locations_local table
    await db.execute('''
      CREATE TABLE $locationsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        altitude REAL,
        speed REAL,
        bearing REAL,
        timestamp INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        synced_at INTEGER,
        FOREIGN KEY (trip_id) REFERENCES $tripsTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_trips_user_id ON $tripsTable(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_trips_start_time ON $tripsTable(start_time DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_trips_synced_at ON $tripsTable(synced_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_locations_trip_id ON $locationsTable(trip_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_locations_timestamp ON $locationsTable(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_locations_synced_at ON $locationsTable(synced_at)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations will be handled here
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE trips_local ADD COLUMN new_field TEXT');
    // }
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing or reset)
  Future<void> deleteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // ==================== TRIPS CRUD ====================

  /// Insert a trip
  Future<int> insertTrip(Map<String, dynamic> trip) async {
    final db = await database;
    return await db.insert(
      tripsTable,
      trip,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get trip by ID
  Future<Map<String, dynamic>?> getTrip(String id) async {
    final db = await database;
    final results = await db.query(
      tripsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Get all trips for a user
  Future<List<Map<String, dynamic>>> getTrips({
    required String userId,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      tripsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Get trips that need sync
  Future<List<Map<String, dynamic>>> getUnsyncedTrips({
    required String userId,
  }) async {
    final db = await database;
    return await db.query(
      tripsTable,
      where: 'user_id = ? AND (synced_at IS NULL OR modified_at > synced_at)',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
    );
  }

  /// Get active (in-progress) trip
  Future<Map<String, dynamic>?> getActiveTrip({
    required String userId,
  }) async {
    final db = await database;
    final results = await db.query(
      tripsTable,
      where: 'user_id = ? AND end_time IS NULL',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Update a trip
  Future<int> updateTrip(String id, Map<String, dynamic> trip) async {
    final db = await database;
    return await db.update(
      tripsTable,
      trip,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a trip (will cascade delete locations)
  Future<int> deleteTrip(String id) async {
    final db = await database;
    // First delete locations
    await db.delete(
      locationsTable,
      where: 'trip_id = ?',
      whereArgs: [id],
    );
    // Then delete trip
    return await db.delete(
      tripsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark trip as synced
  Future<int> markTripSynced(String id, int syncedAt) async {
    final db = await database;
    return await db.update(
      tripsTable,
      {'synced_at': syncedAt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== LOCATIONS CRUD ====================

  /// Insert a location
  Future<int> insertLocation(Map<String, dynamic> location) async {
    final db = await database;
    return await db.insert(
      locationsTable,
      location,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple locations (batch)
  Future<void> insertLocationsBatch(
      List<Map<String, dynamic>> locations) async {
    final db = await database;
    final batch = db.batch();
    for (final location in locations) {
      batch.insert(
        locationsTable,
        location,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get locations for a trip
  Future<List<Map<String, dynamic>>> getLocationsByTrip(String tripId) async {
    final db = await database;
    return await db.query(
      locationsTable,
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Get unsynced locations for a trip
  Future<List<Map<String, dynamic>>> getUnsyncedLocations(String tripId) async {
    final db = await database;
    return await db.query(
      locationsTable,
      where: 'trip_id = ? AND synced_at IS NULL',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Delete locations for a trip
  Future<int> deleteLocationsByTrip(String tripId) async {
    final db = await database;
    return await db.delete(
      locationsTable,
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
  }

  /// Mark locations as synced
  Future<int> markLocationsSynced(String tripId, int syncedAt) async {
    final db = await database;
    return await db.update(
      locationsTable,
      {'synced_at': syncedAt},
      where: 'trip_id = ? AND synced_at IS NULL',
      whereArgs: [tripId],
    );
  }

  /// Get location count for a trip
  Future<int> getLocationCount(String tripId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $locationsTable WHERE trip_id = ?',
      [tripId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== STATISTICS ====================

  /// Get total trips count
  Future<int> getTripsCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tripsTable WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total distance traveled
  Future<double> getTotalDistance(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(distance) as total FROM $tripsTable WHERE user_id = ? AND distance IS NOT NULL',
      [userId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total duration
  Future<int> getTotalDuration(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(duration) as total FROM $tripsTable WHERE user_id = ? AND duration IS NOT NULL',
      [userId],
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }
}
