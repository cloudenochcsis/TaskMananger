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

# Ensure the instance folder exists
try:
    os.makedirs(app.instance_path)
except OSError:
    pass

# Database connection functions
def get_db():
    if 'db' not in g:
        g.db = sqlite3.connect(
            app.config['DATABASE'],
            detect_types=sqlite3.PARSE_DECLTYPES
        )
        g.db.row_factory = sqlite3.Row
    return g.db

def close_db(e=None):
    db = g.pop('db', None)
    if db is not None:
        db.close()

# Initialize the database
def init_db():
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
    return hashlib.sha1(password.encode()).hexdigest()

# Authentication functions
def login_required(view):
    def wrapped_view(**kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return view(**kwargs)
    wrapped_view.__name__ = view.__name__
    return wrapped_view

# Routes
@app.route('/')
def index():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/register', methods=('GET', 'POST'))
def register():
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
    session.clear()
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
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
    title = request.form['title']
    description = request.form['description']
    assigned_to = request.form['assigned_to']
    status = request.form['status']
    
    if not title:
        flash('Title is required!')
        return redirect(url_for('dashboard'))
    
    db = get_db()
    db.execute(
        '''INSERT INTO tasks (title, description, status, created_by, assigned_to)
           VALUES (?, ?, ?, ?, ?)''',
        (title, description, status, session['user_id'], assigned_to)
    )
    db.commit()
    flash('Task created successfully!')
    return redirect(url_for('dashboard'))

@app.route('/task/<int:id>/update', methods=['POST'])
@login_required
def update_task(id):
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
    db = get_db()
    db.execute('DELETE FROM tasks WHERE id = ?', (id,))
    db.commit()
    flash('Task deleted successfully!')
    return redirect(url_for('dashboard'))

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    app.run(debug=True, host='0.0.0.0', port=5000) 