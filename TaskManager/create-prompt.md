Objective: Create a proof-of-concept task management application using Flask (latest version) with a SQLite database, relying on raw SQL (the sqlite3 module) for all database interactions. The application should:

Offer simple user authentication (no advanced security measures).
Enable users to create tasks, assign tasks to other users, and set/update a task’s status.
Present a main view that lists all tasks, shows each task’s status, and indicates the user to whom it’s assigned.
Include minimal front-end templates rendered through Flask (no JavaScript frameworks).

Requirements:

Use Python 3.13 (or the latest release).
Run within a virtual environment (self-hosted).
No advanced production-level security features are needed.

Implement user and task data storage with SQLite and the sqlite3 Python module (no SQLAlchemy).
A single table schema (or minimal set of tables) is sufficient; no migrations/versioning required.

User Authentication:

Implement a minimal username/password login system.
No multi-factor authentication or complex role-based access is required.
Store passwords in plain text or with a very simple hashing approach (e.g., MD5/SHA1) if desired (note that this is not secure for production).

Application Functionality:

User Account Creation (register a new user).
Login/Logout flow (session-based).

Task Management:
Create a new task (including assigning it to a user).
Set or change task status (e.g., “Not started,” “In progress,” “Complete,” “Blocked,” “Closed”).
Edit or delete tasks as needed (optional, but nice to include).

Main View:
Display a list of all tasks along with their statuses and assigned users.
Include basic filtering by status or assigned user

Front-End Templates:

Use basic HTML/CSS templates rendered directly by Flask’s templating system.
No JavaScript frameworks or external UI libraries.
Keep the UI layout lean and simple.

Deployment & Configuration:
Assume a self-hosted environment.
Provide (or describe) any basic setup and run instructions (e.g., how to install dependencies and start the Flask server).
