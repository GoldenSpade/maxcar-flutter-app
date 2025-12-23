import '../models/trip.dart';
import '../models/location_point.dart';

/// Abstract repository for trip operations
abstract class TripRepository {
  /// Create a new trip
  Future<Trip> createTrip(Trip trip);

  /// Get trip by ID
  Future<Trip?> getTrip(String id);

  /// Get all trips for a user
  Future<List<Trip>> getAllTrips({
    required String userId,
    int? limit,
    int? offset,
  });

  /// Get active (in-progress) trip
  Future<Trip?> getActiveTrip({required String userId});

  /// Update a trip
  Future<Trip> updateTrip(Trip trip);

  /// Delete a trip
  Future<void> deleteTrip(String id);

  /// Add location to a trip
  Future<LocationPoint> addLocation(LocationPoint location);

  /// Add multiple locations (batch)
  Future<void> addLocationsBatch(List<LocationPoint> locations);

  /// Get locations for a trip
  Future<List<LocationPoint>> getLocationsByTrip(String tripId);

  /// Get location count for a trip
  Future<int> getLocationCount(String tripId);

  /// Delete all locations for a trip
  Future<void> deleteLocationsByTrip(String tripId);
}
