import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../providers/location_provider.dart';
import '../providers/compass_provider.dart';
import '../providers/tracking_provider.dart';
import '../../history/screens/trips_list_screen.dart';
import '../../settings/screens/vehicle_settings_screen.dart';

/// Main tracking screen with map
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final MapController _mapController = MapController();
  bool _isTrackingStarted = false;
  bool _autoCenterEnabled = true;
  LatLng? _lastCenteredPosition;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    // Request location permission and get current position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).requestPermissionAndGetLocation();
    });

    // Start duration timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startContinuousTracking() {
    if (!_isTrackingStarted) {
      ref.read(locationProvider.notifier).startTracking();
      _isTrackingStarted = true;
    }
  }

  void _toggleRecording() async {
    final trackingState = ref.read(trackingProvider);

    if (trackingState.isRecording) {
      // Stop recording
      await ref.read(trackingProvider.notifier).stopTracking();
    } else {
      // Start recording
      await ref.read(trackingProvider.notifier).startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final compassState = ref.watch(compassProvider);
    final trackingState = ref.watch(trackingProvider);

    // Start continuous tracking when we have initial position
    if (locationState.currentPosition != null && !_isTrackingStarted) {
      _startContinuousTracking();
    }

    // Add GPS points to route when recording
    ref.listen<LocationState>(locationProvider, (previous, next) {
      if (trackingState.isRecording && next.currentPosition != null) {
        // Create Position object from location state
        final position = Position(
          latitude: next.currentPosition!.latitude,
          longitude: next.currentPosition!.longitude,
          timestamp: DateTime.now(),
          accuracy: next.accuracy ?? 0,
          altitude: next.altitude ?? 0,
          altitudeAccuracy: 0,
          heading: next.bearing ?? 0,
          headingAccuracy: 0,
          speed: next.speed ?? 0,
          speedAccuracy: 0,
        );
        ref.read(trackingProvider.notifier).addPoint(position);
      }
    });

    // Auto-center map ONLY when position changes (not on every compass update)
    if (locationState.currentPosition != null &&
        _autoCenterEnabled &&
        _lastCenteredPosition != locationState.currentPosition) {
      _lastCenteredPosition = locationState.currentPosition;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          locationState.currentPosition!,
          _mapController.camera.zoom, // Keep current zoom level
        );
      });
    }

    // Determine which heading to use:
    // - Use compass heading (instant response)
    // - Fall back to GPS heading if compass not available
    final heading = compassState.isAvailable
        ? compassState.heading
        : (locationState.bearing ?? 0.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MaxCar Tracker'),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VehicleSettingsScreen(),
                ),
              );
            },
            tooltip: 'Vehicle Settings',
          ),
          // History button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TripsListScreen(),
                ),
              );
            },
            tooltip: 'Trip History',
          ),
          // Auto-center toggle button
          IconButton(
            icon: Icon(_autoCenterEnabled ? Icons.gps_fixed : Icons.gps_not_fixed),
            onPressed: () {
              setState(() {
                _autoCenterEnabled = !_autoCenterEnabled;
              });
            },
            tooltip: _autoCenterEnabled ? 'Disable auto-center' : 'Enable auto-center',
          ),
          // Refresh location button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(locationProvider.notifier)
                  .requestPermissionAndGetLocation();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: locationState.currentPosition ??
                  const LatLng(50.0, 30.0), // Default center
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              // Tile layer (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.maxcar_tracker',
                maxNativeZoom: 19,
                maxZoom: 18,
              ),

              // Route polyline
              if (trackingState.currentRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: ref.read(trackingProvider.notifier).routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),

              // Current position marker
              if (locationState.currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: locationState.currentPosition!,
                      width: 80,
                      height: 80,
                      rotate: true, // Enable marker rotation
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              locationState.speedKmh?.toStringAsFixed(1) ??
                                  '0.0',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Transform.rotate(
                            angle: heading * (3.14159 / 180), // Convert degrees to radians
                            child: Icon(
                              Icons.navigation,
                              color: Colors.blue.shade700,
                              size: 40,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Loading indicator
          if (locationState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Recording indicator
          if (trackingState.isRecording)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fiber_manual_record, color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Recording • ${_formatDuration(trackingState.duration)}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(trackingState.totalDistance / 1000).toStringAsFixed(2)} km',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Error message
          if (locationState.error != null && !trackingState.isRecording)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          locationState.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Info panel
          if (locationState.currentPosition != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: trackingState.isRecording
                            ? [
                                _InfoItem(
                                  icon: Icons.speed,
                                  label: 'Speed',
                                  value:
                                      '${locationState.speedKmh?.toStringAsFixed(1) ?? '0.0'} km/h',
                                ),
                                _InfoItem(
                                  icon: Icons.trending_up,
                                  label: 'Avg Speed',
                                  value:
                                      '${trackingState.avgSpeedKmh.toStringAsFixed(1)} km/h',
                                ),
                                _InfoItem(
                                  icon: Icons.arrow_upward,
                                  label: 'Max Speed',
                                  value:
                                      '${trackingState.maxSpeedKmh.toStringAsFixed(1)} km/h',
                                ),
                              ]
                            : [
                                _InfoItem(
                                  icon: Icons.speed,
                                  label: 'Speed',
                                  value:
                                      '${locationState.speedKmh?.toStringAsFixed(1) ?? '0.0'} km/h',
                                ),
                                _InfoItem(
                                  icon: Icons.my_location,
                                  label: 'Accuracy',
                                  value:
                                      '${locationState.accuracy?.toStringAsFixed(0) ?? '0'} m',
                                ),
                                _InfoItem(
                                  icon: Icons.height,
                                  label: 'Altitude',
                                  value:
                                      '${locationState.altitude?.toStringAsFixed(0) ?? '0'} m',
                                ),
                              ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${locationState.currentPosition!.latitude.toStringAsFixed(6)}, '
                        'Lon: ${locationState.currentPosition!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Record button
          FloatingActionButton(
            heroTag: 'record_btn',
            onPressed: _toggleRecording,
            backgroundColor: trackingState.isRecording ? Colors.red : Colors.green,
            child: Icon(
              trackingState.isRecording ? Icons.stop : Icons.fiber_manual_record,
            ),
          ),
          const SizedBox(height: 16),
          // Center location button
          FloatingActionButton(
            heroTag: 'center_btn',
            onPressed: locationState.currentPosition != null
                ? () {
                    _mapController.move(
                      locationState.currentPosition!,
                      15.0,
                    );
                  }
                : null,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue.shade700),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
