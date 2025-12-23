import '../../core/services/database_service.dart';
import '../models/trip.dart';
import '../models/location_point.dart';
import 'trip_repository.dart';

/// Local (SQLite) implementation of TripRepository
class TripLocalRepository implements TripRepository {
  final DatabaseService _dbService;

  TripLocalRepository(this._dbService);

  @override
  Future<Trip> createTrip(Trip trip) async {
    await _dbService.insertTrip(trip.toLocalDb());
    return trip;
  }

  @override
  Future<Trip?> getTrip(String id) async {
    final map = await _dbService.getTrip(id);
    if (map == null) return null;
    return Trip.fromLocalDb(map);
  }

  @override
  Future<List<Trip>> getAllTrips({
    required String userId,
    int? limit,
    int? offset,
  }) async {
    final maps = await _dbService.getTrips(
      userId: userId,
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Trip.fromLocalDb(map)).toList();
  }

  @override
  Future<Trip?> getActiveTrip({required String userId}) async {
    final map = await _dbService.getActiveTrip(userId: userId);
    if (map == null) return null;
    return Trip.fromLocalDb(map);
  }

  @override
  Future<Trip> updateTrip(Trip trip) async {
    // Update modified_at timestamp
    final updatedTrip = trip.copyWith(
      modifiedAt: DateTime.now(),
    );
    await _dbService.updateTrip(trip.id, updatedTrip.toLocalDb());
    return updatedTrip;
  }

  @override
  Future<void> deleteTrip(String id) async {
    await _dbService.deleteTrip(id);
  }

  @override
  Future<LocationPoint> addLocation(LocationPoint location) async {
    final id = await _dbService.insertLocation(location.toLocalDb());
    return location.copyWith(id: id);
  }

  @override
  Future<void> addLocationsBatch(List<LocationPoint> locations) async {
    final maps = locations.map((loc) => loc.toLocalDb()).toList();
    await _dbService.insertLocationsBatch(maps);
  }

  @override
  Future<List<LocationPoint>> getLocationsByTrip(String tripId) async {
    final maps = await _dbService.getLocationsByTrip(tripId);
    return maps.map((map) => LocationPoint.fromLocalDb(map)).toList();
  }

  @override
  Future<int> getLocationCount(String tripId) async {
    return await _dbService.getLocationCount(tripId);
  }

  @override
  Future<void> deleteLocationsByTrip(String tripId) async {
    await _dbService.deleteLocationsByTrip(tripId);
  }

  // Additional local-specific methods

  /// Get trips that need to be synced
  Future<List<Trip>> getUnsyncedTrips({required String userId}) async {
    final maps = await _dbService.getUnsyncedTrips(userId: userId);
    return maps.map((map) => Trip.fromLocalDb(map)).toList();
  }

  /// Mark trip as synced
  Future<void> markTripSynced(String id) async {
    await _dbService.markTripSynced(id, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get unsynced locations for a trip
  Future<List<LocationPoint>> getUnsyncedLocations(String tripId) async {
    final maps = await _dbService.getUnsyncedLocations(tripId);
    return maps.map((map) => LocationPoint.fromLocalDb(map)).toList();
  }

  /// Mark locations as synced
  Future<void> markLocationsSynced(String tripId) async {
    await _dbService.markLocationsSynced(
        tripId, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    final tripsCount = await _dbService.getTripsCount(userId);
    final totalDistance = await _dbService.getTotalDistance(userId);
    final totalDuration = await _dbService.getTotalDuration(userId);

    return {
      'tripsCount': tripsCount,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
    };
  }
}
