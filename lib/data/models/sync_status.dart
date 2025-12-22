/// Enum for sync status
enum SyncStatus {
  /// Not yet synced to remote
  pending,

  /// Currently syncing
  syncing,

  /// Successfully synced
  synced,

  /// Sync failed
  failed,

  /// Modified after sync (needs re-sync)
  modified,
}

/// Extension for SyncStatus helpers
extension SyncStatusExtension on SyncStatus {
  /// Check if needs sync
  bool get needsSync {
    return this == SyncStatus.pending ||
        this == SyncStatus.failed ||
        this == SyncStatus.modified;
  }

  /// Check if can sync
  bool get canSync {
    return this != SyncStatus.syncing;
  }

  /// Get display string
  String get displayName {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
      case SyncStatus.modified:
        return 'Modified';
    }
  }

  /// Convert to int for database storage
  int toInt() {
    switch (this) {
      case SyncStatus.pending:
        return 0;
      case SyncStatus.syncing:
        return 1;
      case SyncStatus.synced:
        return 2;
      case SyncStatus.failed:
        return 3;
      case SyncStatus.modified:
        return 4;
    }
  }

  /// Create from int (from database)
  static SyncStatus fromInt(int value) {
    switch (value) {
      case 0:
        return SyncStatus.pending;
      case 1:
        return SyncStatus.syncing;
      case 2:
        return SyncStatus.synced;
      case 3:
        return SyncStatus.failed;
      case 4:
        return SyncStatus.modified;
      default:
        return SyncStatus.pending;
    }
  }
}

/// Model for tracking sync information
class SyncInfo {
  final SyncStatus status;
  final DateTime? lastSyncAttempt;
  final DateTime? lastSyncSuccess;
  final String? errorMessage;
  final int retryCount;

  const SyncInfo({
    this.status = SyncStatus.pending,
    this.lastSyncAttempt,
    this.lastSyncSuccess,
    this.errorMessage,
    this.retryCount = 0,
  });

  /// Create a copy with some fields replaced
  SyncInfo copyWith({
    SyncStatus? status,
    DateTime? lastSyncAttempt,
    DateTime? lastSyncSuccess,
    String? errorMessage,
    int? retryCount,
  }) {
    return SyncInfo(
      status: status ?? this.status,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      lastSyncSuccess: lastSyncSuccess ?? this.lastSyncSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'status': status.toInt(),
      'last_sync_attempt': lastSyncAttempt?.millisecondsSinceEpoch,
      'last_sync_success': lastSyncSuccess?.millisecondsSinceEpoch,
      'error_message': errorMessage,
      'retry_count': retryCount,
    };
  }

  /// Create from SQLite Map
  factory SyncInfo.fromMap(Map<String, dynamic> map) {
    return SyncInfo(
      status: SyncStatusExtension.fromInt(map['status'] as int),
      lastSyncAttempt: map['last_sync_attempt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['last_sync_attempt'] as int)
          : null,
      lastSyncSuccess: map['last_sync_success'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['last_sync_success'] as int)
          : null,
      errorMessage: map['error_message'] as String?,
      retryCount: map['retry_count'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'SyncInfo(status: ${status.displayName}, lastSync: $lastSyncSuccess, errors: $errorMessage)';
  }
}
