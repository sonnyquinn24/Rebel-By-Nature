"""
MongoDB database configuration and setup for Mergington High School API
"""

from pymongo import MongoClient
from argon2 import PasswordHasher
import logging

# Initialize in-memory storage as fallback
in_memory_activities = {}
in_memory_teachers = {}
using_in_memory = False

try:
    # Connect to MongoDB
    client = MongoClient('mongodb://localhost:27017/', serverSelectionTimeoutMS=5000)
    # Test connection
    client.admin.command('ping')
    db = client['mergington_high']
    activities_collection = db['activities']
    teachers_collection = db['teachers']
    print("Connected to MongoDB successfully")
except Exception as e:
    print(f"MongoDB connection failed, using in-memory storage: {e}")
    using_in_memory = True
    
    # Mock collection classes for in-memory storage
    class InMemoryCollection:
        def __init__(self, storage):
            self.storage = storage
            
        def count_documents(self, filter_dict):
            return len(self.storage)
            
        def insert_one(self, document):
            doc_id = document.get('_id')
            if doc_id:
                self.storage[doc_id] = {k: v for k, v in document.items() if k != '_id'}
            return True
            
        def find_one(self, filter_dict):
            if '_id' in filter_dict:
                doc_id = filter_dict['_id']
                if doc_id in self.storage:
                    result = {'_id': doc_id}
                    result.update(self.storage[doc_id])
                    return result
            return None
            
        def find(self, filter_dict=None):
            if filter_dict is None:
                filter_dict = {}
            results = []
            for doc_id, doc_data in self.storage.items():
                doc = {'_id': doc_id}
                doc.update(doc_data)
                results.append(doc)
            return results
            
        def update_one(self, filter_dict, update_dict):
            if '_id' in filter_dict:
                doc_id = filter_dict['_id']
                if doc_id in self.storage:
                    if '$push' in update_dict:
                        for field, value in update_dict['$push'].items():
                            if field.startswith('sub_activities.$.'):
                                # Handle sub-activity updates
                                sub_field = field.split('.')[-1]
                                if 'sub_activities' in self.storage[doc_id]:
                                    for sub_activity in self.storage[doc_id]['sub_activities']:
                                        if 'sub_activities.id' in filter_dict:
                                            if sub_activity.get('id') == filter_dict['sub_activities.id']:
                                                if sub_field not in sub_activity:
                                                    sub_activity[sub_field] = []
                                                sub_activity[sub_field].append(value)
                                                return type('Result', (), {'modified_count': 1})()
                            else:
                                if field not in self.storage[doc_id]:
                                    self.storage[doc_id][field] = []
                                self.storage[doc_id][field].append(value)
                                return type('Result', (), {'modified_count': 1})()
                    elif '$pull' in update_dict:
                        for field, value in update_dict['$pull'].items():
                            if field.startswith('sub_activities.$.'):
                                # Handle sub-activity updates
                                sub_field = field.split('.')[-1]
                                if 'sub_activities' in self.storage[doc_id]:
                                    for sub_activity in self.storage[doc_id]['sub_activities']:
                                        if 'sub_activities.id' in filter_dict:
                                            if sub_activity.get('id') == filter_dict['sub_activities.id']:
                                                if sub_field in sub_activity and value in sub_activity[sub_field]:
                                                    sub_activity[sub_field].remove(value)
                                                    return type('Result', (), {'modified_count': 1})()
                            else:
                                if field in self.storage[doc_id] and value in self.storage[doc_id][field]:
                                    self.storage[doc_id][field].remove(value)
                                    return type('Result', (), {'modified_count': 1})()
            return type('Result', (), {'modified_count': 0})()
            
        def aggregate(self, pipeline):
            # Simple implementation for getting unique days
            results = []
            all_days = set()
            for doc_id, doc_data in self.storage.items():
                if 'schedule_details' in doc_data and 'days' in doc_data['schedule_details']:
                    for day in doc_data['schedule_details']['days']:
                        all_days.add(day)
            for day in sorted(all_days):
                results.append({'_id': day})
            return results
    
    activities_collection = InMemoryCollection(in_memory_activities)
    teachers_collection = InMemoryCollection(in_memory_teachers)

# Methods
def hash_password(password):
    """Hash password using Argon2"""
    ph = PasswordHasher()
    return ph.hash(password)

def init_database():
    """Initialize database if empty"""

    # Initialize activities if empty
    if activities_collection.count_documents({}) == 0:
        for name, details in initial_activities.items():
            activities_collection.insert_one({"_id": name, **details})
            
    # Initialize teacher accounts if empty
    if teachers_collection.count_documents({}) == 0:
        for teacher in initial_teachers:
            teachers_collection.insert_one({"_id": teacher["username"], **teacher})

# Initial database if empty
initial_activities = {
    "Chess Club": {
        "description": "Learn strategies and compete in chess tournaments",
        "schedule": "Mondays and Fridays, 3:15 PM - 4:45 PM",
        "schedule_details": {
            "days": ["Monday", "Friday"],
            "start_time": "15:15",
            "end_time": "16:45"
        },
        "max_participants": 12,
        "participants": ["michael@mergington.edu", "daniel@mergington.edu"],
        "sub_activities": [
            {
                "id": "chess_practice",
                "name": "Chess Practice",
                "description": "Regular practice sessions for all skill levels",
                "schedule": "Mondays, 3:15 PM - 4:45 PM",
                "schedule_details": {
                    "days": ["Monday"],
                    "start_time": "15:15",
                    "end_time": "16:45"
                },
                "max_participants": 12,
                "participants": ["michael@mergington.edu"]
            },
            {
                "id": "chess_tournament",
                "name": "Chess Tournament",
                "description": "Competitive chess matches",
                "schedule": "Fridays, 3:15 PM - 4:45 PM",
                "schedule_details": {
                    "days": ["Friday"],
                    "start_time": "15:15",
                    "end_time": "16:45"
                },
                "max_participants": 8,
                "participants": ["daniel@mergington.edu"]
            }
        ]
    },
    "Programming Class": {
        "description": "Learn programming fundamentals and build software projects",
        "schedule": "Tuesdays and Thursdays, 7:00 AM - 8:00 AM",
        "schedule_details": {
            "days": ["Tuesday", "Thursday"],
            "start_time": "07:00",
            "end_time": "08:00"
        },
        "max_participants": 20,
        "participants": ["emma@mergington.edu", "sophia@mergington.edu"]
    },
    "Morning Fitness": {
        "description": "Early morning physical training and exercises",
        "schedule": "Mondays, Wednesdays, Fridays, 6:30 AM - 7:45 AM",
        "schedule_details": {
            "days": ["Monday", "Wednesday", "Friday"],
            "start_time": "06:30",
            "end_time": "07:45"
        },
        "max_participants": 30,
        "participants": ["john@mergington.edu", "olivia@mergington.edu"]
    },
    "Soccer Team": {
        "description": "Join the school soccer team and compete in matches",
        "schedule": "Tuesdays and Thursdays, 3:30 PM - 5:30 PM",
        "schedule_details": {
            "days": ["Tuesday", "Thursday"],
            "start_time": "15:30",
            "end_time": "17:30"
        },
        "max_participants": 22,
        "participants": ["liam@mergington.edu", "noah@mergington.edu"]
    },
    "Basketball Team": {
        "description": "Practice and compete in basketball tournaments",
        "schedule": "Wednesdays and Fridays, 3:15 PM - 5:00 PM",
        "schedule_details": {
            "days": ["Wednesday", "Friday"],
            "start_time": "15:15",
            "end_time": "17:00"
        },
        "max_participants": 15,
        "participants": ["ava@mergington.edu", "mia@mergington.edu"]
    },
    "Art Club": {
        "description": "Explore various art techniques and create masterpieces",
        "schedule": "Thursdays, 3:15 PM - 5:00 PM",
        "schedule_details": {
            "days": ["Thursday"],
            "start_time": "15:15",
            "end_time": "17:00"
        },
        "max_participants": 15,
        "participants": ["amelia@mergington.edu", "harper@mergington.edu"]
    },
    "Drama Club": {
        "description": "Act, direct, and produce plays and performances",
        "schedule": "Mondays and Wednesdays, 3:30 PM - 5:30 PM",
        "schedule_details": {
            "days": ["Monday", "Wednesday"],
            "start_time": "15:30",
            "end_time": "17:30"
        },
        "max_participants": 20,
        "participants": ["ella@mergington.edu", "scarlett@mergington.edu"],
        "sub_activities": [
            {
                "id": "drama_auditions",
                "name": "Auditions",
                "description": "Try out for our upcoming spring play",
                "schedule": "Mondays, 3:30 PM - 5:30 PM",
                "schedule_details": {
                    "days": ["Monday"],
                    "start_time": "15:30",
                    "end_time": "17:30"
                },
                "max_participants": 20,
                "participants": ["ella@mergington.edu"]
            },
            {
                "id": "drama_rehearsals",
                "name": "Rehearsals",
                "description": "Practice for the spring play performance",
                "schedule": "Wednesdays, 3:30 PM - 5:30 PM",
                "schedule_details": {
                    "days": ["Wednesday"],
                    "start_time": "15:30",
                    "end_time": "17:30"
                },
                "max_participants": 15,
                "participants": ["scarlett@mergington.edu"]
            }
        ]
    },
    "Math Club": {
        "description": "Solve challenging problems and prepare for math competitions",
        "schedule": "Tuesdays, 7:15 AM - 8:00 AM",
        "schedule_details": {
            "days": ["Tuesday"],
            "start_time": "07:15",
            "end_time": "08:00"
        },
        "max_participants": 10,
        "participants": ["james@mergington.edu", "benjamin@mergington.edu"]
    },
    "Debate Team": {
        "description": "Develop public speaking and argumentation skills",
        "schedule": "Fridays, 3:30 PM - 5:30 PM",
        "schedule_details": {
            "days": ["Friday"],
            "start_time": "15:30",
            "end_time": "17:30"
        },
        "max_participants": 12,
        "participants": ["charlotte@mergington.edu", "amelia@mergington.edu"]
    },
    "Weekend Robotics Workshop": {
        "description": "Build and program robots in our state-of-the-art workshop",
        "schedule": "Saturdays, 10:00 AM - 2:00 PM",
        "schedule_details": {
            "days": ["Saturday"],
            "start_time": "10:00",
            "end_time": "14:00"
        },
        "max_participants": 15,
        "participants": ["ethan@mergington.edu", "oliver@mergington.edu"]
    },
    "Science Olympiad": {
        "description": "Weekend science competition preparation for regional and state events",
        "schedule": "Saturdays, 1:00 PM - 4:00 PM",
        "schedule_details": {
            "days": ["Saturday"],
            "start_time": "13:00",
            "end_time": "16:00"
        },
        "max_participants": 18,
        "participants": ["isabella@mergington.edu", "lucas@mergington.edu"]
    },
    "Sunday Chess Tournament": {
        "description": "Weekly tournament for serious chess players with rankings",
        "schedule": "Sundays, 2:00 PM - 5:00 PM",
        "schedule_details": {
            "days": ["Sunday"],
            "start_time": "14:00",
            "end_time": "17:00"
        },
        "max_participants": 16,
        "participants": ["william@mergington.edu", "jacob@mergington.edu"]
    }
}

initial_teachers = [
    {
        "username": "mrodriguez",
        "display_name": "Ms. Rodriguez",
        "password": hash_password("art123"),
        "role": "teacher"
     },
    {
        "username": "mchen",
        "display_name": "Mr. Chen",
        "password": hash_password("chess456"),
        "role": "teacher"
    },
    {
        "username": "principal",
        "display_name": "Principal Martinez",
        "password": hash_password("admin789"),
        "role": "admin"
    }
]

