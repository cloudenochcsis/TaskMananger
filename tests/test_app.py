"""Test suite for the KodeKloud Task Manager application.

This module contains integration tests for the Flask-based task management application.
It tests core functionality including user authentication, task management operations,
and proper database handling.

Test Coverage:
-------------
- User registration and authentication (login/logout)
- Task operations (create, update, delete)
- Index page redirection
- Database initialization and cleanup

Fixtures:
---------
client : flask.testing.FlaskClient
    A test client for making requests to the application. The fixture handles
    database initialization and cleanup between tests.

Example Usage:
-------------
    $ pytest tests/test_app.py

Note:
-----
The tests use a temporary SQLite database that is created and destroyed for each
test session to ensure test isolation.
"""

import os
import tempfile
import pytest
from TaskManager.app import app, init_db


@pytest.fixture
def client():
    db_fd, app.config['DATABASE'] = tempfile.mkstemp()
    app.config['TESTING'] = True
    
    with app.test_client() as client:
        with app.app_context():
            init_db()
        yield client
    
    os.close(db_fd)
    os.unlink(app.config['DATABASE'])


def test_index_redirect(client):
    """Test the index page redirection behavior.
    
    Verifies that unauthenticated users are redirected to the login page
    when accessing the root URL.
    
    Args:
        client: Flask test client fixture
    
    Assertions:
        - Response status code should be 302 (redirect)
        - Redirect location should contain '/login'
    """
    response = client.get('/')
    assert response.status_code == 302
    assert '/login' in response.headers['Location']


def test_register(client):
    """Test user registration functionality.
    
    Verifies that new users can successfully register with valid credentials
    and receive a confirmation message.
    
    Args:
        client: Flask test client fixture
    
    Assertions:
        - Response status code should be 200
        - Response should contain success message
    """
    response = client.post('/register', data={
        'username': 'testuser',
        'password': 'testpass'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Account created successfully!' in response.data


def test_login_logout(client):
    """Test user authentication workflow.
    
    Verifies the complete login and logout process:
    1. User registration
    2. Successful login with correct credentials
    3. Successful logout
    
    Args:
        client: Flask test client fixture
    
    Assertions:
        - After login: Dashboard should be accessible
        - After logout: Logout message should be displayed
    """
    # Register a user first
    client.post('/register', data={
        'username': 'testuser',
        'password': 'testpass'
    })
    
    # Test login
    response = client.post('/login', data={
        'username': 'testuser',
        'password': 'testpass'
    }, follow_redirects=True)
    assert response.status_code == 200
    assert b'Dashboard' in response.data
    
    # Test logout
    response = client.get('/logout', follow_redirects=True)
    assert response.status_code == 200
    assert b'You have been logged out.' in response.data


def test_create_task(client):
    """Test task creation functionality.
    
    Verifies that authenticated users can create new tasks with:
    - Title
    - Description
    - Status
    - Assignment
    
    Args:
        client: Flask test client fixture
    
    Assertions:
        - Response status code should be 200
        - Success message should be displayed
        - New task should appear in response
    """
    # Register and login
    client.post('/register', data={
        'username': 'testuser',
        'password': 'testpass'
    })
    client.post('/login', data={
        'username': 'testuser',
        'password': 'testpass'
    })
    
    # Create a task
    response = client.post('/task/create', data={
        'title': 'Test Task',
        'description': 'This is a test task',
        'status': 'todo',
        'assigned_to': '1'  # Assign to self (user id 1)
    }, follow_redirects=True)
    
    assert response.status_code == 200
    assert b'Task created successfully!' in response.data
    assert b'Test Task' in response.data


def test_update_task(client):
    """Test task update functionality.
    
    Verifies that users can modify existing tasks by:
    - Changing the status
    - Reassigning the task
    
    Args:
        client: Flask test client fixture
    
    Assertions:
        - Response status code should be 200
        - Success message should be displayed
        - Updated status should be visible
    """
    # Register, login, and create a task
    client.post('/register', data={
        'username': 'testuser',
        'password': 'testpass'
    })
    client.post('/login', data={
        'username': 'testuser',
        'password': 'testpass'
    })
    client.post('/task/create', data={
        'title': 'Test Task',
        'description': 'This is a test task',
        'status': 'todo',
        'assigned_to': '1'
    })
    
    # Update the task
    response = client.post('/task/1/update', data={
        'status': 'in-progress',
        'assigned_to': '1'
    }, follow_redirects=True)
    
    assert response.status_code == 200
    assert b'Task updated successfully!' in response.data
    assert b'in-progress' in response.data


def test_delete_task(client):
    """Test task deletion functionality.
    
    Verifies that users can successfully delete their tasks and that
    deleted tasks are removed from the view.
    
    Args:
        client: Flask test client fixture
    
    Assertions:
        - Response status code should be 200
        - Success message should be displayed
        - Deleted task should not appear in response
    """
    # Register, login, and create a task
    client.post('/register', data={
        'username': 'testuser',
        'password': 'testpass'
    })
    client.post('/login', data={
        'username': 'testuser',
        'password': 'testpass'
    })
    client.post('/task/create', data={
        'title': 'Test Task',
        'description': 'This is a test task',
        'status': 'todo',
        'assigned_to': '1'
    })
    
    # Delete the task
    response = client.post('/task/1/delete', follow_redirects=True)
    
    assert response.status_code == 200
    assert b'Task deleted successfully!' in response.data
    assert b'Test Task' not in response.data
