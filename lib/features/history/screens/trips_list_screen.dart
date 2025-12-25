import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/trips_provider.dart';
import '../../../data/models/trip.dart';
import 'trip_detail_screen.dart';

/// Trips history list screen
class TripsListScreen extends ConsumerStatefulWidget {
  const TripsListScreen({super.key});

  @override
  ConsumerState<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends ConsumerState<TripsListScreen> {
  @override
  void initState() {
    super.initState();
    // Load trips when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripsHistoryProvider.notifier).loadTrips();
    });
  }

  Future<void> _refreshTrips() async {
    await ref.read(tripsHistoryProvider.notifier).refreshTrips();
  }

  Future<void> _deleteTrip(String tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(tripsHistoryProvider.notifier).deleteTrip(tripId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(tripsHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTrips,
          ),
        ],
      ),
      body: historyState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : historyState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        historyState.error!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshTrips,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : historyState.trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.route,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No trips recorded yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start recording to create your first trip',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshTrips,
                      child: ListView.builder(
                        itemCount: historyState.trips.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final trip = historyState.trips[index];
                          return _TripCard(
                            trip: trip,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TripDetailScreen(tripId: trip.id),
                                ),
                              );
                            },
                            onDelete: () => _deleteTrip(trip.id),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--';

    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(trip.startTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.shade400,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${timeFormat.format(trip.startTime)} - ${trip.endTime != null ? timeFormat.format(trip.endTime!) : 'In progress'}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatItem(
                    icon: Icons.route,
                    label: 'Distance',
                    value:
                        '${(trip.distance ?? 0 / 1000).toStringAsFixed(2)} km',
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    icon: Icons.timer,
                    label: 'Duration',
                    value: _formatDuration(trip.duration),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatItem(
                    icon: Icons.speed,
                    label: 'Avg Speed',
                    value:
                        '${((trip.avgSpeed ?? 0) * 3.6).toStringAsFixed(1)} km/h',
                  ),
                  const SizedBox(width: 24),
                  _StatItem(
                    icon: Icons.trending_up,
                    label: 'Max Speed',
                    value:
                        '${((trip.maxSpeed ?? 0) * 3.6).toStringAsFixed(1)} km/h',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
