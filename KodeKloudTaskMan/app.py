"""
Task Manager Flask Application.

This module implements a simple task management web application using Flask.
It provides features for user authentication, task creation, updating, and deletion.
Tasks can be assigned to different users and filtered by status.
"""

import csv
import sqlite3
import os
from flask import Flask, render_template, request, redirect, url_for, flash, session, g
from datetime import datetime
import hashlib
import logging

# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = 'dev'  # Change this to a random secret key in production
app.config['DATABASE'] = os.path.join(app.instance_path, 'task_manager.sqlite')

def read_csv(file_path):
    """
    Read data from a CSV file and print each row.
    
    Args:
        file_path (str): Path to the CSV file to be read
        
    Returns:
        None: This function prints each row to the console but doesn't return any value
        
    Example:
        >>> read_csv('data.csv')
        ['header1', 'header2', 'header3']
        ['value1', 'value2', 'value3']
        ...
    """
    with open(file_path, 'r') as f:
        csvreader = csv.reader(f)
        for row in csvreader:
            print(row)

# Ensure the instance folder exists
try:
    os.makedirs(app.instance_path)
except OSError:
    pass

# Database connection functions
def get_db():
    """
    Get a database connection from the Flask application context.
    
    Returns:
        sqlite3.Connection: Database connection with row factory set to sqlite3.Row
    """
    if 'db' not in g:
        g.db = sqlite3.connect(
            app.config['DATABASE'],
            detect_types=sqlite3.PARSE_DECLTYPES
        )
        g.db.row_factory = sqlite3.Row
    return g.db

def close_db(e=None):
    """
    Close the database connection if it exists.
    
    Args:
        e: Exception that might have occurred (default: None)
    """
    db = g.pop('db', None)
    if db is not None:
        db.close()

# Initialize the database
def init_db():
    """
    Initialize the database with schema from schema.sql.
    """
    db = get_db()
    with app.open_resource('schema.sql') as f:
        db.executescript(f.read().decode('utf8'))

@app.cli.command('init-db')
def init_db_command():
    """Clear the existing data and create new tables."""
    init_db()
    print('Initialized the database.')

# Register close_db function with app
app.teardown_appcontext(close_db)

# Simple password hashing (not secure for production)
def hash_password(password):
    """
    Hash a password using SHA-1 (not secure for production).
    
    Args:
        password (str): Plain text password
        
    Returns:
        str: Hexadecimal digest of the hashed password
    """
    return hashlib.sha1(password.encode()).hexdigest()


# Authentication functions
def login_required(view):
    """
    Decorator to require login for views.
    
    Args:
        view (function): The view function to be decorated
        
    Returns:
        function: The wrapped view function
    """
    def wrapped_view(**kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return view(**kwargs)
    wrapped_view.__name__ = view.__name__
    return wrapped_view

# Routes
@app.route('/')
def index():
    """
    Route for the homepage.
    
    Returns:
        Response: Redirect to dashboard if logged in, otherwise redirect to login
    """
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/register', methods=('GET', 'POST'))
def register():
    """
    User registration route.
    
    Returns:
        Response: Rendered register template or redirect to login
    """
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        db = get_db()
        error = None

        if not username:
            error = 'Username is required.'
        elif not password:
            error = 'Password is required.'
        elif db.execute(
            'SELECT id FROM users WHERE username = ?', (username,)
        ).fetchone() is not None:
            error = f"User {username} is already registered."

        if error is None:
            db.execute(
                'INSERT INTO users (username, password) VALUES (?, ?)',
                (username, hash_password(password))
            )
            db.commit()
            return redirect(url_for('login'))

        flash(error)

    return render_template('register.html')

@app.route('/login', methods=('GET', 'POST'))
def login():
    """
    User login route.
    
    Returns:
        Response: Rendered login template or redirect to dashboard
    """
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        db = get_db()
        error = None
        user = db.execute(
            'SELECT * FROM users WHERE username = ?', (username,)
        ).fetchone()

        if user is None:
            error = 'Incorrect username.'
        elif user['password'] != hash_password(password):
            error = 'Incorrect password.'

        if error is None:
            session.clear()
            session['user_id'] = user['id']
            session['username'] = user['username']
            return redirect(url_for('dashboard'))

        flash(error)

    return render_template('login.html')

@app.route('/logout')
def logout():
    """
    User logout route.
    
    Returns:
        Response: Redirect to login page
    """
    session.clear()
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
    """
    Dashboard route showing all tasks with optional filtering.
    
    Returns:
        Response: Rendered dashboard template with tasks, users, and statuses
    """
    db = get_db()
    status_filter = request.args.get('status', '')
    user_filter = request.args.get('user', '')

    query = '''
        SELECT t.id, t.title, t.description, t.status, t.created_at, 
               creator.username as created_by, assignee.username as assigned_to
        FROM tasks t
        JOIN users creator ON t.created_by = creator.id
        JOIN users assignee ON t.assigned_to = assignee.id
        WHERE 1=1
    '''
    params = []

    if status_filter:
        query += ' AND t.status = ?'
        params.append(status_filter)
    
    if user_filter:
        query += ' AND assignee.username = ?'
        params.append(user_filter)
    
    query += ' ORDER BY t.created_at DESC'
    
    tasks = db.execute(query, params).fetchall()
    
    # Get all users for the assignment dropdown
    users = db.execute('SELECT id, username FROM users').fetchall()
    
    # Get all statuses for the filter dropdown
    statuses = ['Not started', 'In progress', 'Complete', 'Blocked', 'Closed']
    
    return render_template('dashboard.html', 
                          tasks=tasks, 
                          users=users, 
                          statuses=statuses,
                          current_status=status_filter,
                          current_user=user_filter)

@app.route('/task/create', methods=['POST'])
@login_required
def create_task():
    """
    Create a new task.
    
    Returns:
        Response: Redirect to dashboard with success or error message
    """
    title = request.form['title']
    description = request.form['description']
    assigned_to = request.form['assigned_to']
    status = request.form['status']
    
    if not title:
        flash('Title is required!')
        return redirect(url_for('dashboard'))
    
    db = get_db()
    db.execute(
        'INSERT INTO tasks (title, description, status, created_by, assigned_to) VALUES (?, ?, ?, ?, ?)',
        (title, description, status, session['user_id'], assigned_to)
    )
    db.commit()
    flash('Task created successfully!')
    return redirect(url_for('dashboard'))

@app.route('/task/<int:id>/update', methods=['POST'])
@login_required
def update_task(id):
    """
    Update an existing task's status and assignment.
    
    Args:
        id (int): Task ID
        
    Returns:
        Response: Redirect to dashboard with success message
    """
    status = request.form['status']
    assigned_to = request.form['assigned_to']
    
    db = get_db()
    db.execute(
        'UPDATE tasks SET status = ?, assigned_to = ? WHERE id = ?',
        (status, assigned_to, id)
    )
    db.commit()
    flash('Task updated successfully!')
    return redirect(url_for('dashboard'))

@app.route('/task/<int:id>/delete', methods=['POST'])
@login_required
def delete_task(id):
    """
    Delete a task.
    
    Args:
        id (int): Task ID
        
    Returns:
        Response: Redirect to dashboard with success message
    """
    db = get_db()
    db.execute('DELETE FROM tasks WHERE id = ?', (id,))
    db.commit()
    flash('Task deleted successfully!')
    return redirect(url_for('dashboard'))

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    app.run(debug=True, host='0.0.0.0', port=5000)
