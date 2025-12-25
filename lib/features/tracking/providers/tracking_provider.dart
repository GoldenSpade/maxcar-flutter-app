import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database_service.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/location_point.dart';

/// Recording state enum
enum RecordingState {
  idle,
  recording,
  paused,
}

/// Tracking state
class TrackingState {
  final RecordingState recordingState;
  final Trip? currentTrip;
  final List<LocationPoint> currentRoute;
  final double totalDistance; // meters
  final DateTime? startTime;
  final Duration duration;
  final double? maxSpeed; // m/s
  final String? error;

  TrackingState({
    this.recordingState = RecordingState.idle,
    this.currentTrip,
    this.currentRoute = const [],
    this.totalDistance = 0.0,
    this.startTime,
    this.duration = Duration.zero,
    this.maxSpeed,
    this.error,
  });

  bool get isRecording => recordingState == RecordingState.recording;
  bool get isPaused => recordingState == RecordingState.paused;
  bool get isIdle => recordingState == RecordingState.idle;

  double get avgSpeed {
    if (duration.inSeconds == 0) return 0.0;
    return totalDistance / duration.inSeconds; // m/s
  }

  double get avgSpeedKmh => avgSpeed * 3.6;
  double get maxSpeedKmh => (maxSpeed ?? 0) * 3.6;

  TrackingState copyWith({
    RecordingState? recordingState,
    Trip? currentTrip,
    List<LocationPoint>? currentRoute,
    double? totalDistance,
    DateTime? startTime,
    Duration? duration,
    double? maxSpeed,
    String? error,
  }) {
    return TrackingState(
      recordingState: recordingState ?? this.recordingState,
      currentTrip: currentTrip ?? this.currentTrip,
      currentRoute: currentRoute ?? this.currentRoute,
      totalDistance: totalDistance ?? this.totalDistance,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      error: error,
    );
  }
}

/// Tracking provider
class TrackingNotifier extends StateNotifier<TrackingState> {
  final DatabaseService _dbService;
  final Uuid _uuid = const Uuid();

  TrackingNotifier(this._dbService) : super(TrackingState());

  /// Start tracking/recording
  Future<void> startTracking() async {
    if (state.isRecording) return;

    try {
      final now = DateTime.now();
      final tripId = _uuid.v4();

      // Create new trip
      final trip = Trip(
        id: tripId,
        userId: 'local_user', // TODO: Replace with actual user ID from auth
        startTime: now,
        endTime: null,
        distance: 0.0,
        duration: 0,
        avgSpeed: 0.0,
        maxSpeed: 0.0,
        transportType: 'car',
        createdAt: now,
        updatedAt: now,
        syncedAt: null,
        modifiedAt: now,
      );

      // Save trip to database
      final tripMap = trip.toLocalDb();
      await _dbService.insertTrip(tripMap);

      state = TrackingState(
        recordingState: RecordingState.recording,
        currentTrip: trip,
        currentRoute: [],
        totalDistance: 0.0,
        startTime: now,
        duration: Duration.zero,
        maxSpeed: 0.0,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start tracking: ${e.toString()}',
      );
    }
  }

  /// Add GPS point to current route
  Future<void> addPoint(Position position) async {
    if (!state.isRecording || state.currentTrip == null) return;

    try {
      final point = LocationPoint(
        id: null, // Auto-increment in SQLite
        tripId: state.currentTrip!.id,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        bearing: position.heading,
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Save point to database
      final pointMap = point.toLocalDb();
      await _dbService.insertLocation(pointMap);

      // Calculate distance from last point
      double additionalDistance = 0.0;
      if (state.currentRoute.isNotEmpty) {
        final lastPoint = state.currentRoute.last;
        additionalDistance = Geolocator.distanceBetween(
          lastPoint.latitude,
          lastPoint.longitude,
          point.latitude,
          point.longitude,
        );
      }

      // Update max speed
      final newMaxSpeed = state.maxSpeed != null
          ? (position.speed > state.maxSpeed! ? position.speed : state.maxSpeed)
          : position.speed;

      // Update duration
      final duration = DateTime.now().difference(state.startTime!);

      // Update state
      state = state.copyWith(
        currentRoute: [...state.currentRoute, point],
        totalDistance: state.totalDistance + additionalDistance,
        duration: duration,
        maxSpeed: newMaxSpeed,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to add point: ${e.toString()}',
      );
    }
  }

  /// Stop tracking/recording
  Future<void> stopTracking() async {
    if (!state.isRecording || state.currentTrip == null) return;

    try {
      final endTime = DateTime.now();
      final duration = endTime.difference(state.startTime!);

      // Update trip with final statistics
      final updatedTrip = state.currentTrip!.copyWith(
        endTime: endTime,
        distance: state.totalDistance,
        duration: duration.inSeconds,
        avgSpeed: state.avgSpeed,
        maxSpeed: state.maxSpeed ?? 0.0,
        updatedAt: endTime,
        modifiedAt: endTime,
      );

      // Update trip in database
      final updatedTripMap = updatedTrip.toLocalDb();
      await _dbService.updateTrip(updatedTrip.id, updatedTripMap);

      // Reset state
      state = TrackingState();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to stop tracking: ${e.toString()}',
      );
    }
  }

  /// Pause tracking
  void pauseTracking() {
    if (!state.isRecording) return;
    state = state.copyWith(recordingState: RecordingState.paused);
  }

  /// Resume tracking
  void resumeTracking() {
    if (!state.isPaused) return;
    state = state.copyWith(recordingState: RecordingState.recording);
  }

  /// Get current route as LatLng list for polyline
  List<LatLng> get routePoints {
    return state.currentRoute
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }
}

/// Tracking provider
final trackingProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  final dbService = DatabaseService();
  return TrackingNotifier(dbService);
});
