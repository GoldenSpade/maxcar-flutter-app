import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/gps_service.dart';
import '../../../core/services/permission_service.dart';

/// State for location
class LocationState {
  final LatLng? currentPosition;
  final double? accuracy;
  final double? altitude;
  final double? speed; // m/s
  final double? bearing;
  final bool isLoading;
  final String? error;

  LocationState({
    this.currentPosition,
    this.accuracy,
    this.altitude,
    this.speed,
    this.bearing,
    this.isLoading = false,
    this.error,
  });

  /// Get speed in km/h
  double? get speedKmh => speed != null ? speed! * 3.6 : null;

  LocationState copyWith({
    LatLng? currentPosition,
    double? accuracy,
    double? altitude,
    double? speed,
    double? bearing,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Location provider
class LocationNotifier extends StateNotifier<LocationState> {
  final GpsService _gpsService;
  final PermissionService _permissionService;

  LocationNotifier(this._gpsService, this._permissionService)
      : super(LocationState());

  /// Request permission and get current location
  Future<void> requestPermissionAndGetLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check permission
      final permissionResult =
          await _permissionService.requestLocationPermission();

      if (!permissionResult.isGranted) {
        state = state.copyWith(
          isLoading: false,
          error: permissionResult.message,
        );
        return;
      }

      // Check if location service is enabled
      if (!await _gpsService.isLocationServiceEnabled()) {
        state = state.copyWith(
          isLoading: false,
          error: 'Location service is disabled. Please enable it in settings.',
        );
        return;
      }

      // Get current position
      final position = await _gpsService.getCurrentPosition();

      if (position == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to get current location',
        );
        return;
      }

      // Update state
      state = LocationState(
        currentPosition: LatLng(position.latitude, position.longitude),
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        bearing: position.heading,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error: ${e.toString()}',
      );
    }
  }

  /// Start tracking location updates
  void startTracking() {
    _gpsService.startTracking(
      onPositionUpdate: (Position position) {
        state = LocationState(
          currentPosition: LatLng(position.latitude, position.longitude),
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          bearing: position.heading,
          isLoading: false,
          error: null,
        );
      },
      onError: (error) {
        state = state.copyWith(
          error: 'Tracking error: ${error.toString()}',
        );
      },
    );
  }

  /// Stop tracking
  void stopTracking() {
    _gpsService.stopTracking();
  }

  @override
  void dispose() {
    _gpsService.stopTracking();
    super.dispose();
  }
}

/// Location provider
final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  return LocationNotifier(gpsService, permissionService);
});
