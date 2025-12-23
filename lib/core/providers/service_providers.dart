import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gps_service.dart';
import '../services/permission_service.dart';

/// Provider for PermissionService
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// Provider for GpsService
final gpsServiceProvider = Provider<GpsService>((ref) {
  final service = GpsService();
  ref.onDispose(() => service.dispose());
  return service;
});
