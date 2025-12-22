// Supabase configuration
//
// This file contains the configuration for connecting to Supabase.
// For security, these values should be moved to environment variables in production.

/// Supabase configuration class
class SupabaseConfig {
  // Supabase URL (self-hosted on VPS)
  static const String supabaseUrl = 'https://api.digitalunion.io';

  // Supabase Anon Key (public key for client-side access)
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzY0MTc5MDg4LCJleHAiOjIwNzk1MzkwODh9.oHdDuzd8WcHNvgHdslz8onSSEKJLYezfueB4rHM_Xd4';

  // Project ID (for reference)
  static const String projectId = 'default';

  /// Table names with maxcar_ prefix
  static const String tripsTable = 'maxcar_trips';
  static const String locationsTable = 'maxcar_locations';
  static const String migrationsTable = 'maxcar_migrations';
}
