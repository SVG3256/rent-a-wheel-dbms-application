import pymysql
from flask import current_app, g

def get_db():
    """Opens a new database connection if there is none for the current context."""
    if 'db' not in g:
        g.db = pymysql.connect(
            host=current_app.config['MYSQL_HOST'],
            user=current_app.config['MYSQL_USER'],
            password=current_app.config['MYSQL_PASSWORD'],
            db=current_app.config['MYSQL_DB'],
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=True 
        )
    return g.db

def close_db(e=None):
    """Closes the database again at the end of the request."""
    db = g.pop('db', None)
    if db is not None:
        db.close()

def query_db(query, args=(), one=False):
    """Helper to execute a raw SQL query (SELECT)."""
    cur = get_db().cursor()
    cur.execute(query, args)
    rv = cur.fetchall()
    cur.close()
    return (rv[0] if rv else None) if one else rv

def call_proc(proc_name, args=()):
    """Helper to call a Stored Procedure."""
    conn = get_db()
    cur = conn.cursor()
    try:
        cur.callproc(proc_name, args)
        # If the procedure returns a SELECT result (like a search), fetch it
        result = cur.fetchall()
        return result
    except Exception as e:
        raise e
    finally:
        cur.close()