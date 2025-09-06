
-- =====================================================
-- Campus Event Management Platform - SQL Schema
-- =====================================================

-- Colleges table
CREATE TABLE colleges (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    domain TEXT,
    created_at TIMESTAMP DEFAULT now()
);

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY,
    college_id UUID REFERENCES colleges(id),
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('student','staff','admin')),
    student_roll TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT now()
);

-- Events table
CREATE TABLE events (
    id UUID PRIMARY KEY,
    college_id UUID REFERENCES colleges(id),
    created_by UUID REFERENCES users(id),
    title TEXT NOT NULL,
    description TEXT,
    type TEXT, -- workshop, hackathon, seminar, etc.
    venue TEXT,
    start_at TIMESTAMP,
    end_at TIMESTAMP,
    capacity INT,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','cancelled','completed','draft')),
    allow_waitlist BOOLEAN DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT now()
);

-- Registrations table
CREATE TABLE registrations (
    id UUID PRIMARY KEY,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'registered' CHECK (status IN ('registered','cancelled','waitlisted')),
    registered_at TIMESTAMP DEFAULT now(),
    UNIQUE (event_id, user_id)
);

-- Attendance table
CREATE TABLE attendances (
    id UUID PRIMARY KEY,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    checked_in_at TIMESTAMP DEFAULT now(),
    method TEXT, -- qr/manual/geofence
    device_info JSONB,
    UNIQUE (event_id, user_id)
);

-- Feedback table
CREATE TABLE feedbacks (
    id UUID PRIMARY KEY,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating SMALLINT CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT now(),
    UNIQUE (event_id, user_id)
);

-- Optional: Audit logs table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY,
    who UUID REFERENCES users(id),
    action TEXT NOT NULL,
    payload JSONB,
    created_at TIMESTAMP DEFAULT now()
);
