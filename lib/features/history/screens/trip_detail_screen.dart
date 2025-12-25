import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../providers/trips_provider.dart';
import '../../../core/utils/currency_utils.dart';

/// Trip detail screen showing map and statistics
class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Load trip details when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripDetailProvider(widget.tripId).notifier).loadTripDetails();
    });
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--';

    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    }
    return '${minutes}m ${secs}s';
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLon),
      LatLng(maxLat, maxLon),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(tripDetailProvider(widget.tripId));

    if (detailState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (detailState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                detailState.error!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final trip = detailState.trip;
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: const Center(child: Text('Trip not found')),
      );
    }

    final routePoints = detailState.points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    // Fit bounds after map is built
    if (routePoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds(routePoints);
      });
    }

    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: Text(dateFormat.format(trip.startTime)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Export trip
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming soon'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 2,
            child: routePoints.isEmpty
                ? Center(
                    child: Text(
                      'No route data available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: routePoints.isNotEmpty
                          ? routePoints.first
                          : const LatLng(50.0, 30.0),
                      initialZoom: 15.0,
                      minZoom: 3.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.maxcar_tracker',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: Colors.blue,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                      // Start marker
                      if (routePoints.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: routePoints.first,
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.play_circle,
                                color: Colors.green.shade700,
                                size: 40,
                              ),
                            ),
                            // End marker
                            if (routePoints.length > 1)
                              Marker(
                                point: routePoints.last,
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.stop_circle,
                                  color: Colors.red.shade700,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
          ),

          // Statistics
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: 'Started',
                      value: timeFormat.format(trip.startTime),
                    ),
                    _DetailRow(
                      icon: Icons.access_time_filled,
                      label: 'Ended',
                      value: trip.endTime != null
                          ? timeFormat.format(trip.endTime!)
                          : 'In progress',
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.route,
                      label: 'Distance',
                      value: '${(trip.distance ?? 0 / 1000).toStringAsFixed(2)} km',
                    ),
                    _DetailRow(
                      icon: Icons.timer,
                      label: 'Duration',
                      value: _formatDuration(trip.duration),
                    ),
                    const Divider(height: 24),
                    _DetailRow(
                      icon: Icons.speed,
                      label: 'Average Speed',
                      value:
                          '${((trip.avgSpeed ?? 0) * 3.6).toStringAsFixed(1)} km/h',
                    ),
                    _DetailRow(
                      icon: Icons.trending_up,
                      label: 'Maximum Speed',
                      value:
                          '${((trip.maxSpeed ?? 0) * 3.6).toStringAsFixed(1)} km/h',
                    ),
                    _DetailRow(
                      icon: Icons.location_on,
                      label: 'GPS Points',
                      value: '${detailState.points.length}',
                    ),
                    if (trip.fuelCost != null && trip.fuelCost! > 0) ...[
                      const Divider(height: 24),
                      Text(
                        'Fuel Consumption',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(
                        icon: Icons.local_gas_station,
                        label: 'Fuel Used',
                        value: '${trip.fuelUsed?.toStringAsFixed(2) ?? '0'} L',
                      ),
                      _DetailRow(
                        icon: Icons.attach_money,
                        label: 'Fuel Cost',
                        value: CurrencyUtils.formatPrice(
                            trip.fuelCost ?? 0, trip.currency ?? 'USD'),
                      ),
                      _DetailRow(
                        icon: Icons.speed,
                        label: 'Consumption Rate',
                        value:
                            '${trip.fuelConsumption?.toStringAsFixed(1) ?? '0'} L/100km',
                      ),
                      _DetailRow(
                        icon: Icons.info_outline,
                        label: 'Fuel Type',
                        value: trip.fuelType ?? 'Unknown',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
