# Task Manager

A Flask-based web application for managing tasks and projects. This application provides a simple yet powerful interface for users to create, assign, and track tasks within their team.

[![Version](https://img.shields.io/badge/version-v1.0.1-blue.svg)](https://github.com/cloudenochcsis/TaskMananger/releases/tag/v1.0.1)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

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

## Environment Variables

The application can be configured using the following environment variables:

| Variable | Description | Default |
|----------|-------------|--------|
| `SECRET_KEY` | Flask secret key for session security | `a_secure_random_key_for_development` |
| `FLASK_APP` | Flask application path | `KodeKloudTaskMan/app.py` |
| `FLASK_ENV` | Flask environment (development/production) | `production` |
| `DATABASE` | SQLite database path | `/app/instance/task_manager.sqlite` |

> **Note:** For production deployments, always set a strong, unique `SECRET_KEY`.

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

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Security

- Passwords are securely hashed using PBKDF2 with SHA-512 and salt
- Backward compatibility for existing SHA-1 hashed passwords
- Secret keys and sensitive configuration stored in environment variables
- Session management is handled by Flask with secure cookies
- SQL injection protection through parameterized queries
- Proper file permissions and user isolation in Docker containers

## Future Improvements

- [ ] Add email notifications for task assignments and updates
- [ ] Implement task categories and tags
- [ ] Add file attachments to tasks
- [ ] Implement task comments and discussion threads
- [ ] Add user roles and permissions (admin, manager, user)
- [ ] Implement task deadlines and reminders
- [ ] Add multi-stage Docker builds to reduce image size
- [ ] Implement CI/CD pipeline for automated testing and deployment
- [ ] Add health monitoring and logging
- [ ] Implement database migrations for schema changes