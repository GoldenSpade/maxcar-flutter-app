import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/trip.dart';
import '../models/location_point.dart';
import 'trip_repository.dart';

/// Remote (Supabase) implementation of TripRepository
class TripRemoteRepository implements TripRepository {
  final SupabaseClient _supabase;

  TripRemoteRepository(this._supabase);

  @override
  Future<Trip> createTrip(Trip trip) async {
    final response = await _supabase
        .from(SupabaseConfig.tripsTable)
        .insert(trip.toJson())
        .select()
        .single();

    return Trip.fromJson(response);
  }

  @override
  Future<Trip?> getTrip(String id) async {
    final response = await _supabase
        .from(SupabaseConfig.tripsTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Trip.fromJson(response);
  }

  @override
  Future<List<Trip>> getAllTrips({
    required String userId,
    int? limit,
    int? offset,
  }) async {
    var query = _supabase
        .from(SupabaseConfig.tripsTable)
        .select()
        .eq('user_id', userId)
        .order('start_time', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (offset != null) {
      query = query.range(offset, offset + (limit ?? 10) - 1);
    }

    final response = await query;
    return (response as List).map((json) => Trip.fromJson(json)).toList();
  }

  @override
  Future<Trip?> getActiveTrip({required String userId}) async {
    final response = await _supabase
        .from(SupabaseConfig.tripsTable)
        .select()
        .eq('user_id', userId)
        .isFilter('end_time', null)
        .order('start_time', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Trip.fromJson(response);
  }

  @override
  Future<Trip> updateTrip(Trip trip) async {
    final response = await _supabase
        .from(SupabaseConfig.tripsTable)
        .update(trip.toJson())
        .eq('id', trip.id)
        .select()
        .single();

    return Trip.fromJson(response);
  }

  @override
  Future<void> deleteTrip(String id) async {
    await _supabase.from(SupabaseConfig.tripsTable).delete().eq('id', id);
  }

  @override
  Future<LocationPoint> addLocation(LocationPoint location) async {
    final response = await _supabase
        .from(SupabaseConfig.locationsTable)
        .insert(location.toJson())
        .select()
        .single();

    return LocationPoint.fromJson(response);
  }

  @override
  Future<void> addLocationsBatch(List<LocationPoint> locations) async {
    final jsonList = locations.map((loc) => loc.toJson()).toList();

    // Supabase supports batch inserts
    await _supabase.from(SupabaseConfig.locationsTable).insert(jsonList);
  }

  @override
  Future<List<LocationPoint>> getLocationsByTrip(String tripId) async {
    final response = await _supabase
        .from(SupabaseConfig.locationsTable)
        .select()
        .eq('trip_id', tripId)
        .order('timestamp', ascending: true);

    return (response as List)
        .map((json) => LocationPoint.fromJson(json))
        .toList();
  }

  @override
  Future<int> getLocationCount(String tripId) async {
    final response = await _supabase
        .from(SupabaseConfig.locationsTable)
        .select('id')
        .eq('trip_id', tripId);

    return (response as List).length;
  }

  @override
  Future<void> deleteLocationsByTrip(String tripId) async {
    await _supabase
        .from(SupabaseConfig.locationsTable)
        .delete()
        .eq('trip_id', tripId);
  }

  // Additional remote-specific methods

  /// Sync trip from local to remote
  Future<Trip> syncTrip(Trip trip) async {
    // Check if trip exists
    final existing = await getTrip(trip.id);

    if (existing == null) {
      // Create new trip
      return await createTrip(trip);
    } else {
      // Update existing trip
      return await updateTrip(trip);
    }
  }

  /// Sync locations from local to remote
  Future<void> syncLocations(List<LocationPoint> locations) async {
    if (locations.isEmpty) return;

    // Batch insert (Supabase handles upsert automatically with unique constraints)
    await addLocationsBatch(locations);
  }

  /// Get trips by date range
  Future<List<Trip>> getTripsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _supabase
        .from(SupabaseConfig.tripsTable)
        .select()
        .eq('user_id', userId)
        .gte('start_time', startDate.toIso8601String())
        .lte('start_time', endDate.toIso8601String())
        .order('start_time', ascending: false);

    return (response as List).map((json) => Trip.fromJson(json)).toList();
  }

  /// Calculate trip statistics using Supabase function
  Future<Map<String, dynamic>?> calculateTripStats(String tripId) async {
    try {
      final response = await _supabase.rpc(
        'maxcar_calculate_trip_stats',
        params: {'trip_uuid': tripId},
      ).single();

      return response;
    } catch (e) {
      // Function might not exist or other error
      return null;
    }
  }
}
