import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database_service.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/location_point.dart';

/// State for trips history
class TripsHistoryState {
  final List<Trip> trips;
  final bool isLoading;
  final String? error;

  TripsHistoryState({
    this.trips = const [],
    this.isLoading = false,
    this.error,
  });

  TripsHistoryState copyWith({
    List<Trip>? trips,
    bool? isLoading,
    String? error,
  }) {
    return TripsHistoryState(
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Trips history provider
class TripsHistoryNotifier extends StateNotifier<TripsHistoryState> {
  final DatabaseService _dbService;

  TripsHistoryNotifier(this._dbService) : super(TripsHistoryState());

  /// Load all trips from database
  Future<void> loadTrips() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tripsData = await _dbService.getTrips(
        userId: 'local_user',
        limit: null,
        offset: null,
      );

      final trips = tripsData.map((data) => Trip.fromLocalDb(data)).toList();

      state = TripsHistoryState(
        trips: trips,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load trips: ${e.toString()}',
      );
    }
  }

  /// Refresh trips list
  Future<void> refreshTrips() async {
    await loadTrips();
  }

  /// Delete a trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _dbService.deleteTrip(tripId);

      // Remove from local state
      state = state.copyWith(
        trips: state.trips.where((trip) => trip.id != tripId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete trip: ${e.toString()}',
      );
    }
  }
}

/// Trips history provider
final tripsHistoryProvider =
    StateNotifierProvider<TripsHistoryNotifier, TripsHistoryState>((ref) {
  final dbService = DatabaseService();
  return TripsHistoryNotifier(dbService);
});

/// State for single trip detail
class TripDetailState {
  final Trip? trip;
  final List<LocationPoint> points;
  final bool isLoading;
  final String? error;

  TripDetailState({
    this.trip,
    this.points = const [],
    this.isLoading = false,
    this.error,
  });

  TripDetailState copyWith({
    Trip? trip,
    List<LocationPoint>? points,
    bool? isLoading,
    String? error,
  }) {
    return TripDetailState(
      trip: trip ?? this.trip,
      points: points ?? this.points,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Trip detail provider
class TripDetailNotifier extends StateNotifier<TripDetailState> {
  final DatabaseService _dbService;
  final String tripId;

  TripDetailNotifier(this._dbService, this.tripId) : super(TripDetailState());

  /// Load trip details with all location points
  Future<void> loadTripDetails() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load trip
      final tripData = await _dbService.getTrip(tripId);
      if (tripData == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Trip not found',
        );
        return;
      }

      final trip = Trip.fromLocalDb(tripData);

      // Load locations
      final locationsData = await _dbService.getLocationsByTrip(tripId);

      final points = locationsData
          .map((data) => LocationPoint.fromLocalDb(data))
          .toList();

      state = TripDetailState(
        trip: trip,
        points: points,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load trip details: ${e.toString()}',
      );
    }
  }
}

/// Trip detail provider factory
final tripDetailProvider = StateNotifierProvider.family<TripDetailNotifier,
    TripDetailState, String>((ref, tripId) {
  final dbService = DatabaseService();
  return TripDetailNotifier(dbService, tripId);
});
