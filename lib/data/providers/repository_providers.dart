import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/database_service.dart';
import '../repositories/trip_repository.dart';
import '../repositories/trip_local_repository.dart';
import '../repositories/trip_remote_repository.dart';

/// Provider for DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provider for Supabase client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for local trip repository
final tripLocalRepositoryProvider = Provider<TripRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return TripLocalRepository(dbService);
});

/// Provider for remote trip repository
final tripRemoteRepositoryProvider = Provider<TripRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TripRemoteRepository(supabase);
});

/// Provider for the main trip repository (currently uses local)
/// In the future, this could be a hybrid repository that syncs between local and remote
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  // For now, use local repository
  // Later, we can create a hybrid repository that uses both
  return ref.watch(tripLocalRepositoryProvider);
});
