import 'package:uuid/uuid.dart';

/// Model representing a trip/journey
class Trip {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final double? distance; // in meters
  final int? duration; // in seconds
  final double? avgSpeed; // in km/h
  final double? maxSpeed; // in km/h
  final String? transportType; // 'car', 'bike', 'walk', 'unknown'
  final DateTime createdAt;
  final DateTime updatedAt;

  // For local sync tracking
  final DateTime? syncedAt;
  final DateTime? modifiedAt;

  Trip({
    String? id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.distance,
    this.duration,
    this.avgSpeed,
    this.maxSpeed,
    this.transportType,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncedAt,
    this.modifiedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a copy of this trip with some fields replaced
  Trip copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    double? distance,
    int? duration,
    double? avgSpeed,
    double? maxSpeed,
    String? transportType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
    DateTime? modifiedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      transportType: transportType ?? this.transportType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'distance': distance,
      'duration': duration,
      'avg_speed': avgSpeed,
      'max_speed': maxSpeed,
      'transport_type': transportType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON (from Supabase)
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
      duration: json['duration'] as int?,
      avgSpeed: json['avg_speed'] != null
          ? (json['avg_speed'] as num).toDouble()
          : null,
      maxSpeed: json['max_speed'] != null
          ? (json['max_speed'] as num).toDouble()
          : null,
      transportType: json['transport_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to Map for SQLite (local database)
  Map<String, dynamic> toLocalDb() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'distance': distance,
      'duration': duration,
      'avg_speed': avgSpeed,
      'max_speed': maxSpeed,
      'transport_type': transportType,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'synced_at': syncedAt?.millisecondsSinceEpoch,
      'modified_at': modifiedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from SQLite Map
  factory Trip.fromLocalDb(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      startTime:
          DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      distance: map['distance'] != null
          ? (map['distance'] as num).toDouble()
          : null,
      duration: map['duration'] as int?,
      avgSpeed: map['avg_speed'] != null
          ? (map['avg_speed'] as num).toDouble()
          : null,
      maxSpeed: map['max_speed'] != null
          ? (map['max_speed'] as num).toDouble()
          : null,
      transportType: map['transport_type'] as String?,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      syncedAt: map['synced_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['synced_at'] as int)
          : null,
      modifiedAt: map['modified_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['modified_at'] as int)
          : null,
    );
  }

  /// Check if trip is in progress
  bool get isInProgress => endTime == null;

  /// Check if trip needs sync
  bool get needsSync =>
      syncedAt == null ||
      (modifiedAt != null && modifiedAt!.isAfter(syncedAt!));

  @override
  String toString() {
    return 'Trip(id: $id, startTime: $startTime, endTime: $endTime, distance: $distance, duration: $duration)';
  }
}
