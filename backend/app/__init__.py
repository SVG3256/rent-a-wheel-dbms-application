from flask import Flask
from flask_cors import CORS
from .db import close_db

def create_app():
    app = Flask(__name__)
    
    # Configuration 
    app.config['MYSQL_HOST'] = 'localhost'
    app.config['MYSQL_USER'] = 'root'      # Your MySQL Username
    app.config['MYSQL_PASSWORD'] = 'indian123' # Your MySQL Password
    
    app.config['MYSQL_DB'] = 'rentawheel_db'
    # Enable CORS for all routes (allows React to connect)
    CORS(app)

    # Register Database Teardown
    app.teardown_appcontext(close_db)

    # Register Blueprints (Routes)
    from .routes import api_bp
    app.register_blueprint(api_bp, url_prefix='/api')

    return app