import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/compass_service.dart';

/// State for compass heading
class CompassState {
  final double heading; // 0-360 degrees
  final bool isAvailable;
  final String? error;

  CompassState({
    this.heading = 0.0,
    this.isAvailable = true,
    this.error,
  });

  CompassState copyWith({
    double? heading,
    bool? isAvailable,
    String? error,
  }) {
    return CompassState(
      heading: heading ?? this.heading,
      isAvailable: isAvailable ?? this.isAvailable,
      error: error,
    );
  }
}

/// Compass provider
class CompassNotifier extends StateNotifier<CompassState> {
  final CompassService _compassService;

  CompassNotifier(this._compassService) : super(CompassState()) {
    _startListening();
  }

  /// Start listening to compass
  void _startListening() async {
    // Check if compass is available
    final isAvailable = await _compassService.isCompassAvailable();

    if (!isAvailable) {
      state = state.copyWith(
        isAvailable: false,
        error: 'Compass not available on this device',
      );
      return;
    }

    // Start listening to heading updates
    _compassService.startListening(
      onHeadingUpdate: (double heading) {
        state = CompassState(
          heading: heading,
          isAvailable: true,
          error: null,
        );
      },
      onError: (error) {
        state = state.copyWith(
          error: 'Compass error: ${error.toString()}',
        );
      },
    );
  }

  @override
  void dispose() {
    _compassService.dispose();
    super.dispose();
  }
}

/// Compass provider
final compassProvider =
    StateNotifierProvider<CompassNotifier, CompassState>((ref) {
  final compassService = ref.watch(compassServiceProvider);
  return CompassNotifier(compassService);
});
