import 'package:permission_handler/permission_handler.dart';

/// Service for handling location permissions
class PermissionService {
  /// Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if location when in use permission is granted
  Future<bool> isLocationWhenInUseGranted() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  /// Check if location always permission is granted
  Future<bool> isLocationAlwaysGranted() async {
    final status = await Permission.locationAlways.status;
    return status.isGranted;
  }

  /// Request location when in use permission
  Future<PermissionStatus> requestLocationWhenInUse() async {
    return await Permission.locationWhenInUse.request();
  }

  /// Request location always permission (for background tracking)
  Future<PermissionStatus> requestLocationAlways() async {
    return await Permission.locationAlways.request();
  }

  /// Request location permission with explanation
  Future<LocationPermissionResult> requestLocationPermission({
    bool needsBackgroundAccess = false,
  }) async {
    // First check if already granted
    if (await isLocationWhenInUseGranted()) {
      if (needsBackgroundAccess && !await isLocationAlwaysGranted()) {
        final status = await requestLocationAlways();
        return _mapStatus(status, needsBackgroundAccess: true);
      }
      return LocationPermissionResult.granted;
    }

    // Request when in use permission first
    final status = await requestLocationWhenInUse();

    if (status.isGranted && needsBackgroundAccess) {
      // Request always permission if needed
      final alwaysStatus = await requestLocationAlways();
      return _mapStatus(alwaysStatus, needsBackgroundAccess: true);
    }

    return _mapStatus(status, needsBackgroundAccess: false);
  }

  /// Map permission status to result
  LocationPermissionResult _mapStatus(
    PermissionStatus status, {
    required bool needsBackgroundAccess,
  }) {
    if (status.isGranted) {
      return LocationPermissionResult.granted;
    } else if (status.isDenied) {
      return LocationPermissionResult.denied;
    } else if (status.isPermanentlyDenied) {
      return LocationPermissionResult.permanentlyDenied;
    } else if (status.isRestricted) {
      return LocationPermissionResult.restricted;
    } else {
      return LocationPermissionResult.denied;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Check if should show rationale
  Future<bool> shouldShowRationale() async {
    final status = await Permission.location.status;
    return status.isDenied && !status.isPermanentlyDenied;
  }

  /// Get detailed permission status
  Future<Map<String, PermissionStatus>> getDetailedStatus() async {
    return {
      'location': await Permission.location.status,
      'locationWhenInUse': await Permission.locationWhenInUse.status,
      'locationAlways': await Permission.locationAlways.status,
    };
  }
}

/// Result of location permission request
enum LocationPermissionResult {
  /// Permission granted
  granted,

  /// Permission denied (can request again)
  denied,

  /// Permission permanently denied (need to go to settings)
  permanentlyDenied,

  /// Permission restricted (parental controls, etc.)
  restricted,
}

/// Extension for LocationPermissionResult
extension LocationPermissionResultExtension on LocationPermissionResult {
  /// Check if permission is granted
  bool get isGranted => this == LocationPermissionResult.granted;

  /// Check if permission is denied
  bool get isDenied => this == LocationPermissionResult.denied;

  /// Check if permission is permanently denied
  bool get isPermanentlyDenied =>
      this == LocationPermissionResult.permanentlyDenied;

  /// Check if permission is restricted
  bool get isRestricted => this == LocationPermissionResult.restricted;

  /// Get user-friendly message
  String get message {
    switch (this) {
      case LocationPermissionResult.granted:
        return 'Location permission granted';
      case LocationPermissionResult.denied:
        return 'Location permission denied. Please grant permission to use this feature.';
      case LocationPermissionResult.permanentlyDenied:
        return 'Location permission permanently denied. Please enable it in app settings.';
      case LocationPermissionResult.restricted:
        return 'Location permission is restricted. Please check your device settings.';
    }
  }
}
