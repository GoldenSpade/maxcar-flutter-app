import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';

/// Service for compass/magnetometer data
class CompassService {
  StreamSubscription<double>? _compassSubscription;

  /// Check if compass is available on device
  Future<bool> isCompassAvailable() async {
    try {
      final hasCompass = await FlutterCompass.events?.first;
      return hasCompass != null;
    } catch (e) {
      return false;
    }
  }

  /// Get compass heading stream
  /// Returns heading in degrees (0-360)
  /// 0 = North, 90 = East, 180 = South, 270 = West
  Stream<double>? getHeadingStream() {
    return FlutterCompass.events?.map((event) {
      // heading can be null if compass is not available
      if (event.heading == null) {
        return 0.0;
      }

      // Normalize heading to 0-360 range
      double heading = event.heading!;
      if (heading < 0) {
        heading += 360;
      }

      return heading;
    });
  }

  /// Start listening to compass heading
  void startListening({
    required Function(double heading) onHeadingUpdate,
    Function(Object)? onError,
  }) {
    // Cancel existing subscription if any
    stopListening();

    final headingStream = getHeadingStream();
    if (headingStream == null) {
      onError?.call('Compass not available on this device');
      return;
    }

    _compassSubscription = headingStream.listen(
      onHeadingUpdate,
      onError: onError,
      cancelOnError: false,
    );
  }

  /// Stop listening to compass
  void stopListening() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  /// Check if currently listening
  bool get isListening => _compassSubscription != null;

  /// Dispose resources
  void dispose() {
    stopListening();
  }
}
