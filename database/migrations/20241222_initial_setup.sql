-- ============================================
-- MaxCar Tracker - Database Setup Script
-- Supabase Self-hosted on VPS
-- ============================================
-- This script creates the database schema for MaxCar GPS tracking application
-- All tables use 'maxcar_' prefix to avoid conflicts with other projects

-- ============================================
-- 1. Enable PostGIS Extension (for geospatial queries)
-- ============================================
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================
-- 2. Create Migrations Tracking Table
-- ============================================
CREATE TABLE IF NOT EXISTS maxcar_migrations (
    id SERIAL PRIMARY KEY,
    migration_name TEXT NOT NULL UNIQUE,
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    description TEXT
);

-- ============================================
-- 3. Create Tables
-- ============================================

-- Table: maxcar_trips
-- Stores information about individual trips/journeys
CREATE TABLE IF NOT EXISTS maxcar_trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Timing
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,

    -- Statistics
    distance DOUBLE PRECISION, -- in meters
    duration INTEGER, -- in seconds
    avg_speed DOUBLE PRECISION, -- in km/h
    max_speed DOUBLE PRECISION, -- in km/h

    -- Classification
    transport_type TEXT, -- 'car', 'bike', 'walk', 'unknown'

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CHECK (end_time IS NULL OR end_time >= start_time),
    CHECK (distance IS NULL OR distance >= 0),
    CHECK (duration IS NULL OR duration >= 0),
    CHECK (avg_speed IS NULL OR avg_speed >= 0),
    CHECK (max_speed IS NULL OR max_speed >= 0)
);

-- Table: maxcar_locations
-- Stores individual GPS points for each trip
CREATE TABLE IF NOT EXISTS maxcar_locations (
    id BIGSERIAL PRIMARY KEY,
    trip_id UUID REFERENCES maxcar_trips(id) ON DELETE CASCADE,

    -- GPS data
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION, -- in meters
    altitude DOUBLE PRECISION, -- in meters
    speed DOUBLE PRECISION, -- in m/s
    bearing DOUBLE PRECISION, -- degrees from north (0-360)

    -- Timestamp
    timestamp TIMESTAMPTZ NOT NULL,

    -- PostGIS geography point (for spatial queries)
    geom GEOGRAPHY(Point, 4326),

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CHECK (latitude >= -90 AND latitude <= 90),
    CHECK (longitude >= -180 AND longitude <= 180),
    CHECK (accuracy IS NULL OR accuracy >= 0),
    CHECK (speed IS NULL OR speed >= 0),
    CHECK (bearing IS NULL OR (bearing >= 0 AND bearing < 360))
);

-- ============================================
-- 3. Create Indexes
-- ============================================

-- Trips indexes
CREATE INDEX IF NOT EXISTS idx_maxcar_trips_user_id ON maxcar_trips(user_id);
CREATE INDEX IF NOT EXISTS idx_maxcar_trips_start_time ON maxcar_trips(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_maxcar_trips_created_at ON maxcar_trips(created_at DESC);

-- Locations indexes
CREATE INDEX IF NOT EXISTS idx_maxcar_locations_trip_id ON maxcar_locations(trip_id);
CREATE INDEX IF NOT EXISTS idx_maxcar_locations_timestamp ON maxcar_locations(timestamp);

-- Geospatial index (GIST) for PostGIS geography queries
CREATE INDEX IF NOT EXISTS idx_maxcar_locations_geom ON maxcar_locations USING GIST(geom);

-- ============================================
-- 4. Create Function to Update geom from lat/lon
-- ============================================
CREATE OR REPLACE FUNCTION maxcar_update_location_geom()
RETURNS TRIGGER AS $$
BEGIN
    NEW.geom := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. Create Triggers
-- ============================================

-- Automatically update geom field when location is inserted/updated
DROP TRIGGER IF EXISTS trigger_maxcar_update_geom ON maxcar_locations;
CREATE TRIGGER trigger_maxcar_update_geom
    BEFORE INSERT OR UPDATE OF latitude, longitude ON maxcar_locations
    FOR EACH ROW
    EXECUTE FUNCTION maxcar_update_location_geom();

-- Update updated_at timestamp on trips table
CREATE OR REPLACE FUNCTION maxcar_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_maxcar_trips_updated_at ON maxcar_trips;
CREATE TRIGGER trigger_maxcar_trips_updated_at
    BEFORE UPDATE ON maxcar_trips
    FOR EACH ROW
    EXECUTE FUNCTION maxcar_update_updated_at();

-- ============================================
-- 6. Enable Row Level Security (RLS)
-- ============================================

-- Enable RLS on tables
ALTER TABLE maxcar_trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE maxcar_locations ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 7. Create RLS Policies
-- ============================================

-- Trips policies: users can only access their own trips
DROP POLICY IF EXISTS "Users can view their own trips" ON maxcar_trips;
CREATE POLICY "Users can view their own trips"
    ON maxcar_trips FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own trips" ON maxcar_trips;
CREATE POLICY "Users can insert their own trips"
    ON maxcar_trips FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own trips" ON maxcar_trips;
CREATE POLICY "Users can update their own trips"
    ON maxcar_trips FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own trips" ON maxcar_trips;
CREATE POLICY "Users can delete their own trips"
    ON maxcar_trips FOR DELETE
    USING (auth.uid() = user_id);

-- Locations policies: users can only access locations from their own trips
DROP POLICY IF EXISTS "Users can view locations from their trips" ON maxcar_locations;
CREATE POLICY "Users can view locations from their trips"
    ON maxcar_locations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM maxcar_trips
            WHERE maxcar_trips.id = maxcar_locations.trip_id
            AND maxcar_trips.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert locations to their trips" ON maxcar_locations;
CREATE POLICY "Users can insert locations to their trips"
    ON maxcar_locations FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM maxcar_trips
            WHERE maxcar_trips.id = maxcar_locations.trip_id
            AND maxcar_trips.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update locations from their trips" ON maxcar_locations;
CREATE POLICY "Users can update locations from their trips"
    ON maxcar_locations FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM maxcar_trips
            WHERE maxcar_trips.id = maxcar_locations.trip_id
            AND maxcar_trips.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete locations from their trips" ON maxcar_locations;
CREATE POLICY "Users can delete locations from their trips"
    ON maxcar_locations FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM maxcar_trips
            WHERE maxcar_trips.id = maxcar_locations.trip_id
            AND maxcar_trips.user_id = auth.uid()
        )
    );

-- ============================================
-- 8. Create Helper Functions (Optional)
-- ============================================

-- Function to calculate trip statistics
CREATE OR REPLACE FUNCTION maxcar_calculate_trip_stats(trip_uuid UUID)
RETURNS TABLE (
    total_distance DOUBLE PRECISION,
    total_duration INTEGER,
    avg_speed DOUBLE PRECISION,
    max_speed DOUBLE PRECISION
) AS $$
DECLARE
    trip_start TIMESTAMPTZ;
    trip_end TIMESTAMPTZ;
BEGIN
    -- Get trip start and end times
    SELECT start_time, end_time INTO trip_start, trip_end
    FROM maxcar_trips WHERE id = trip_uuid;

    RETURN QUERY
    SELECT
        -- Total distance (sum of distances between consecutive points)
        COALESCE(SUM(
            ST_Distance(
                lag_geom,
                geom
            )
        ), 0.0) AS total_distance,

        -- Duration in seconds
        EXTRACT(EPOCH FROM (trip_end - trip_start))::INTEGER AS total_duration,

        -- Average speed (excluding zero speeds)
        COALESCE(AVG(speed * 3.6), 0.0) AS avg_speed, -- convert m/s to km/h

        -- Max speed
        COALESCE(MAX(speed * 3.6), 0.0) AS max_speed -- convert m/s to km/h
    FROM (
        SELECT
            geom,
            speed,
            LAG(geom) OVER (ORDER BY timestamp) AS lag_geom
        FROM maxcar_locations
        WHERE trip_id = trip_uuid
        ORDER BY timestamp
    ) subquery
    WHERE lag_geom IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 9. Grant Permissions (if needed)
-- ============================================
-- Uncomment if you need to grant specific permissions
-- GRANT ALL ON maxcar_trips TO authenticated;
-- GRANT ALL ON maxcar_locations TO authenticated;

-- ============================================
-- Setup Complete!
-- ============================================
-- You can now use the following tables:
-- - maxcar_trips: Store trip information
-- - maxcar_locations: Store GPS points
--
-- Helper function:
-- - maxcar_calculate_trip_stats(trip_id): Calculate statistics for a trip
--
-- Notes:
-- - All tables have Row Level Security (RLS) enabled
-- - Users can only access their own data
-- - PostGIS extension is enabled for geospatial queries
-- - Automatic triggers update geom field and updated_at timestamp

-- ============================================
-- Mark Migration as Applied
-- ============================================
INSERT INTO maxcar_migrations (migration_name, description)
VALUES ('20241222_initial_setup', 'Initial database setup: trips and locations tables, PostGIS, RLS policies')
ON CONFLICT (migration_name) DO NOTHING;
