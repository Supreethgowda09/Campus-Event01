from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import uuid

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///campus_events.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# -------------------
# Database Models
# -------------------
class College(db.Model):
    id = db.Column(db.String, primary_key=True)
    name = db.Column(db.String, nullable=False)
    domain = db.Column(db.String)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class User(db.Model):
    id = db.Column(db.String, primary_key=True)
    college_id = db.Column(db.String, db.ForeignKey('college.id'))
    name = db.Column(db.String, nullable=False)
    email = db.Column(db.String, unique=True, nullable=False)
    role = db.Column(db.String, nullable=False)  # student/staff/admin
    student_roll = db.Column(db.String)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Event(db.Model):
    id = db.Column(db.String, primary_key=True)
    college_id = db.Column(db.String, db.ForeignKey('college.id'))
    created_by = db.Column(db.String, db.ForeignKey('user.id'))
    title = db.Column(db.String, nullable=False)
    description = db.Column(db.String)
    type = db.Column(db.String)
    venue = db.Column(db.String)
    start_at = db.Column(db.DateTime)
    end_at = db.Column(db.DateTime)
    capacity = db.Column(db.Integer)
    status = db.Column(db.String, default='scheduled')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Registration(db.Model):
    id = db.Column(db.String, primary_key=True)
    event_id = db.Column(db.String, db.ForeignKey('event.id'))
    user_id = db.Column(db.String, db.ForeignKey('user.id'))
    status = db.Column(db.String, default='registered')
    registered_at = db.Column(db.DateTime, default=datetime.utcnow)

class Attendance(db.Model):
    id = db.Column(db.String, primary_key=True)
    event_id = db.Column(db.String, db.ForeignKey('event.id'))
    user_id = db.Column(db.String, db.ForeignKey('user.id'))
    checked_in_at = db.Column(db.DateTime, default=datetime.utcnow)
    method = db.Column(db.String)

class Feedback(db.Model):
    id = db.Column(db.String, primary_key=True)
    event_id = db.Column(db.String, db.ForeignKey('event.id'))
    user_id = db.Column(db.String, db.ForeignKey('user.id'))
    rating = db.Column(db.Integer)
    comment = db.Column(db.String)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# -------------------
# Utility Functions
# -------------------
def new_uuid():
    return str(uuid.uuid4())

# -------------------
# API Routes
# -------------------

# Create Event
@app.route('/events', methods=['POST'])
def create_event():
    data = request.json
    event = Event(
        id=new_uuid(),
        college_id=data['college_id'],
        created_by=data['created_by'],
        title=data['title'],
        description=data.get('description'),
        type=data.get('type'),
        venue=data.get('venue'),
        start_at=datetime.fromisoformat(data['start_at']),
        end_at=datetime.fromisoformat(data['end_at']),
        capacity=data.get('capacity'),
    )
    db.session.add(event)
    db.session.commit()
    return jsonify({"id": event.id, "title": event.title, "status": event.status}), 201

# Student Registration
@app.route('/events/<event_id>/register', methods=['POST'])
def register_student(event_id):
    data = request.json
    registration = Registration(
        id=new_uuid(),
        event_id=event_id,
        user_id=data['user_id']
    )
    db.session.add(registration)
    db.session.commit()
    return jsonify({"event_id": event_id, "user_id": data['user_id'], "status": registration.status}), 201

# Mark Attendance
@app.route('/events/<event_id>/checkin', methods=['POST'])
def checkin(event_id):
    data = request.json
    attendance = Attendance(
        id=new_uuid(),
        event_id=event_id,
        user_id=data['user_id'],
        method=data.get('method', 'manual')
    )
    db.session.add(attendance)
    db.session.commit()
    return jsonify({"event_id": event_id, "user_id": data['user_id'], "checked_in_at": attendance.checked_in_at.isoformat()}), 201

# Submit Feedback
@app.route('/events/<event_id>/feedback', methods=['POST'])
def submit_feedback(event_id):
    data = request.json
    feedback = Feedback(
        id=new_uuid(),
        event_id=event_id,
        user_id=data['user_id'],
        rating=data['rating'],
        comment=data.get('comment')
    )
    db.session.add(feedback)
    db.session.commit()
    return jsonify({"event_id": event_id, "user_id": data['user_id'], "rating": feedback.rating}), 201

# Reports: Total Registrations
@app.route('/reports/registrations', methods=['GET'])
def total_registrations():
    results = db.session.query(Event.title, db.func.count(Registration.id)).join(Registration, Registration.event_id==Event.id).group_by(Event.id).all()
    return jsonify([{"event": r[0], "total_registrations": r[1]} for r in results])

# Initialize DB
@app.before_first_request
def create_tables():
    db.create_all()

# Run App
if __name__ == '__main__':
    app.run(debug=True)
