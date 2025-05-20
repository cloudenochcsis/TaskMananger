# Task Manager

A Flask-based web application for managing tasks and projects. This application provides a simple yet powerful interface for users to create, assign, and track tasks within their team.

## Features

- 🔐 User Authentication
  - Secure user registration and login
  - Password hashing for security
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

## Prerequisites

- Python 3.8 or higher
- pip (Python package installer)
- Git

## Installation

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
├── tests/                 # Test files
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

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Security

- Passwords are hashed using SHA-1 (Note: Consider upgrading to a more secure hashing algorithm for production)
- Session management is handled by Flask
- SQL injection protection through parameterized queries

## Future Improvements

- [ ] Add email notifications
- [ ] Implement task categories
- [ ] Add file attachments to tasks
- [ ] Implement task comments
- [ ] Add user roles and permissions
- [ ] Implement task deadlines and reminders 