import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Service for GPS location tracking
class GpsService {
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Listen to GPS service status changes
  void listenToServiceStatus({
    required Function(ServiceStatus) onStatusChange,
  }) {
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
      onStatusChange,
      cancelOnError: false,
    );
  }

  /// Stop listening to service status
  void stopListeningToServiceStatus() {
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      if (!await isLocationServiceEnabled()) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  /// Get position stream for continuous tracking
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
    int? timeLimit, // milliseconds
  }) {
    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit != null ? Duration(milliseconds: timeLimit) : null,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Start tracking position
  void startTracking({
    required Function(Position) onPositionUpdate,
    Function(Object)? onError,
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    // Cancel existing subscription if any
    stopTracking();

    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      onPositionUpdate,
      onError: onError,
      cancelOnError: false,
    );
  }

  /// Stop tracking position
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Check if currently tracking
  bool get isTracking => _positionStreamSubscription != null;

  /// Calculate distance between two positions (in meters)
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two positions (in degrees)
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
    stopListeningToServiceStatus();
  }
}

/// GPS tracking configuration
class GpsTrackingConfig {
  final LocationAccuracy accuracy;
  final int distanceFilter; // meters
  final int? timeLimit; // milliseconds

  const GpsTrackingConfig({
    this.accuracy = LocationAccuracy.high,
    this.distanceFilter = 10,
    this.timeLimit,
  });

  /// High accuracy config (for recording)
  static const recording = GpsTrackingConfig(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  /// Medium accuracy config (for display)
  static const display = GpsTrackingConfig(
    accuracy: LocationAccuracy.medium,
    distanceFilter: 50,
  );

  /// Low accuracy config (for battery saving)
  static const batterySaving = GpsTrackingConfig(
    accuracy: LocationAccuracy.low,
    distanceFilter: 100,
  );
}
