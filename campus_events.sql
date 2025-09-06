
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

{
  "title": "AI Workshop",
  "description": "Hands-on session on machine learning basics",
  "type": "workshop",
  "venue": "Seminar Hall 2",
  "start_at": "2025-09-15T10:00:00Z",
  "end_at": "2025-09-15T13:00:00Z",
  "capacity": 100,
  "allow_waitlist": true,
  "metadata": {
    "qr_enabled": true
  }
}
{
  "id": "e8d2d6f4-6d56-4a3e-90ad-23bc89e12d11",
  "college_id": "c1234",
  "title": "AI Workshop",
  "status": "scheduled",
  "capacity": 100,
  "created_by": "u5678",
  "created_at": "2025-09-06T12:30:00Z"
}
(b) Student Registration

Request (POST /colleges/{college_id}/events/{event_id}/register)

{
  "user_id": "u5678"
}
Response

{
  "event_id": "e8d2d6f4-6d56-4a3e-90ad-23bc89e12d11",
  "user_id": "u5678",
  "status": "registered",
  "registered_at": "2025-09-06T12:35:00Z"
}



(d) Submit Feedback

Request (POST /colleges/{college_id}/events/{event_id}/feedback)

{
  "user_id": "u5678",
  "rating": 5,
  "comment": "Very informative and well-organized workshop!"
}



Response

{
  "event_id": "e8d2d6f4-6d56-4a3e-90ad-23bc89e12d11",
  "user_id": "u5678",
  "rating": 5,
  "comment": "Very informative and well-organized workshop!",
  "created_at": "2025-09-06T15:00:00Z"
}



3. Example SQL Queries

    
(a) Total registrations per event
SELECT e.id, e.title, COUNT(r.id) AS total_registrations
FROM events e
LEFT JOIN registrations r ON e.id = r.event_id AND r.status = 'registered'
GROUP BY e.id, e.title
ORDER BY total_registrations DESC;

(b) Attendance percentage (per event)
SELECT e.id, e.title,
       COUNT(DISTINCT a.user_id) * 100.0 / NULLIF(COUNT(DISTINCT r.user_id), 0) AS attendance_percentage
FROM events e
LEFT JOIN registrations r ON e.id = r.event_id AND r.status = 'registered'
LEFT JOIN attendances a ON e.id = a.event_id
GROUP BY e.id, e.title
ORDER BY attendance_percentage DESC;

(c) Average feedback score per event
SELECT e.id, e.title, ROUND(AVG(f.rating), 2) AS avg_feedback_score
FROM events e
LEFT JOIN feedbacks f ON e.id = f.event_id
GROUP BY e.id, e.title
ORDER BY avg_feedback_score DESC;

(d) Top 3 most active students (by attendance)
SELECT u.id, u.name, COUNT(a.event_id) AS events_attended
FROM users u
JOIN attendances a ON u.id = a.user_id
GROUP BY u.id, u.name
ORDER BY events_attended DESC
LIMIT 3;
