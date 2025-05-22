# Task Manager

A Flask-based web application for managing tasks and projects. This application provides a simple yet powerful interface for users to create, assign, and track tasks within their team.

[![Version](https://img.shields.io/badge/version-v1.0.1-blue.svg)](https://github.com/cloudenochcsis/TaskMananger/releases/tag/v1.0.1)

## Recent Changes (v1.0.1)

- 🛠️ Fixed database path mismatch that was causing "no such table: users" error
- 🔒 Enhanced security with PBKDF2 password hashing and salting
- 🔑 Moved sensitive configuration to environment variables
- 🐳 Improved Docker configuration for better consistency and reliability
- 📝 Updated documentation with detailed setup instructions

## Features

- 🔐 User Authentication
  - Secure user registration and login
  - Advanced password hashing with PBKDF2
  - Session management

- 📋 Task Management
  - Create new tasks with title and description
  - Assign tasks to team members
  - Update task status
  - Delete tasks when needed

- 👥 User Management
  - User registration
  - User profiles
  - Task assignment capabilities

- 📊 Dashboard
  - Overview of all tasks
  - Filter tasks by status
  - View tasks assigned to you
  - View tasks created by you

## Tech Stack

- **Backend**: Python/Flask
- **Database**: SQLite
- **Frontend**: HTML, CSS, JavaScript
- **Authentication**: Flask session management
- **Templates**: Jinja2
- **Containerization**: Docker, Docker Compose

## Prerequisites

You can run this application in two ways:

### Option 1: Local Development
- Python 3.8 or higher
- pip (Python package installer)
- Git

### Option 2: Docker (Recommended)
- Docker
- Docker Compose

## Quick Start with Docker (Recommended)

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd TaskMananger
   ```

2. Build and start the application:
   ```bash
   docker-compose up --build
   ```

3. Access the application at: http://localhost:5001

4. To stop the application:
   ```bash
   docker-compose down
   ```

## Local Development Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd TaskMananger
   ```

2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Initialize the database:
   ```bash
   flask --app KodeKloudTaskMan/app.py init-db
   ```

## Running the Application

1. Start the Flask development server:
   ```bash
   flask --app KodeKloudTaskMan/app.py run
   ```

2. Open your web browser and navigate to:
   ```
   http://localhost:5000
   ```

## Project Structure

```
TaskMananger/
├── KodeKloudTaskMan/
│   ├── app.py              # Main application file
│   ├── schema.sql          # Database schema
│   ├── requirements.txt    # Python dependencies
│   ├── static/            # Static files (CSS, JS)
│   └── templates/         # HTML templates
├── Dockerfile            # Docker container configuration
├── docker-compose.yml    # Docker Compose configuration
├── .dockerignore         # Docker ignore file
├── tests/                # Test files
└── .gitignore            # Git ignore file
```

## Database Schema

The application uses SQLite with two main tables:

1. **users**
   - id (PRIMARY KEY)
   - username (UNIQUE)
   - password (hashed)

2. **tasks**
   - id (PRIMARY KEY)
   - title
   - description
   - status
   - created_at
   - created_by (FOREIGN KEY)
   - assigned_to (FOREIGN KEY)

## Contributing

1. Fork the repository
2. Create a new branch for your feature
3. Make your changes
4. Submit a pull request
