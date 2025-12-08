from flask import Blueprint, request, jsonify
from .db import get_db, query_db, call_proc

api_bp = Blueprint('api', __name__)

# --- AUTHENTICATION ---

@api_bp.route('/login', methods=['POST'])
def login():
    """Simple login checking email existence."""
    data = request.json
    email = data.get('email')
    
    # Check if customer exists
    user = query_db("SELECT * FROM Customer WHERE email = %s", (email,), one=True)
    
    if user:
        return jsonify({"message": "Login successful", "user": user}), 200
    return jsonify({"error": "User not found"}), 404

@api_bp.route('/signup', methods=['POST'])
def signup():
    """Calls proc_create_customer"""
    data = request.json
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("""
            CALL proc_create_customer(%s, %s, %s, %s, %s, %s, @new_id)
        """, (
            data['first_name'], data['last_name'], data['dob'],
            data['email'], data['contact_no'], data['license_no']
        ))
        cur.execute("SELECT @new_id")
        new_id = cur.fetchone()['@new_id']
        cur.close()
        
        return jsonify({"message": "Signup successful", "cust_id": new_id}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# --- SEARCH & BROWSING ---

@api_bp.route('/cars/search', methods=['GET'])
def search_cars():
    """
    Search for cars based on Branch and Dates.
    Uses fn_is_car_available SQL function to filter.
    """
    branch_id = request.args.get('branch_id')
    start_date = request.args.get('start_date') 
    end_date = request.args.get('end_date')

    if not all([branch_id, start_date, end_date]):
        return jsonify({"error": "Missing search parameters"}), 400

    # Custom Query: Hides 'Retired' and 'Maintenance' cars
    sql = """
        SELECT c.car_id, c.car_make, c.car_model, c.year, ct.category, ct.daily_rate, c.license_plate
        FROM Car c
        JOIN CarType ct ON c.car_make = ct.car_make AND c.car_model = ct.car_model AND c.year = ct.year
        WHERE c.branch_id = %s 
        AND c.status != 'Retired'
        AND c.status != 'Maintenance'
        AND fn_is_car_available(c.car_id, %s, %s) = 1
    """
    results = query_db(sql, (branch_id, start_date, end_date))
    return jsonify(results), 200

@api_bp.route('/static_data', methods=['GET'])
def get_static_data():
    """Fetch Branches and Insurance options for dropdowns."""
    branches = query_db("SELECT * FROM Branch")
    insurance = query_db("SELECT * FROM Insurance")
    promotions = query_db("SELECT * FROM Promotion")
    return jsonify({"branches": branches, "insurance": insurance, "promotions": promotions}), 200

# --- BOOKING ---

@api_bp.route('/bookings', methods=['POST'])
def create_booking():
    """Calls proc_create_booking"""
    data = request.json
    try:
        conn = get_db()
        cur = conn.cursor()
        
        # Mapping arguments to proc_create_booking parameters
        # IN: cust_id, car_id, make, model, year, pickup, dropoff, start, end, insurance, promo
        args = (
            data['cust_id'], 
            data.get('car_id'), # Specific Car ID from frontend
            data['car_make'], 
            data['car_model'], 
            data['year'],
            data['pickup_branch_id'], 
            data['dropoff_branch_id'],
            data['start_datetime'], 
            data['end_datetime'],
            data.get('insurance_policy_id'), 
            data.get('promo_code')
        )
        
        cur.execute("""
            CALL proc_create_booking(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, @new_booking_id)
        """, args)
        
        cur.execute("SELECT @new_booking_id")
        result = cur.fetchone()
        cur.close()

        if result and result.get('@new_booking_id'):
            return jsonify({"message": "Booking created", "booking_id": result['@new_booking_id']}), 201
        else:
            return jsonify({"error": "Booking failed (Car likely unavailable)"}), 400
            
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@api_bp.route('/bookings/customer/<int:cust_id>', methods=['GET'])
def get_customer_bookings(cust_id):
    """View upcoming and past bookings."""
    sql = """
        SELECT b.*, 
               CASE WHEN b.status = 'Completed' AND f.feedback_id IS NULL THEN 1 ELSE 0 END as can_review
        FROM Booking b
        LEFT JOIN Feedback f ON b.booking_id = f.booking_id
        WHERE b.cust_id = %s
        ORDER BY b.start_datetime DESC
    """
    bookings = query_db(sql, (cust_id,))
    return jsonify(bookings), 200

@api_bp.route('/bookings/<int:booking_id>/cancel', methods=['POST'])
def cancel_booking(booking_id):
    """Calls proc_cancel_booking"""
    try:
        call_proc('proc_cancel_booking', (booking_id,))
        return jsonify({"message": "Booking cancelled successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@api_bp.route('/bookings/<int:booking_id>', methods=['PUT'])
def update_booking(booking_id):
    """Calls proc_update_booking to modify dates or options"""
    data = request.json
    try:
        # proc_update_booking params: id, start, end, promo, insurance
        call_proc('proc_update_booking', (
            booking_id,
            data.get('start_datetime'),
            data.get('end_datetime'),
            data.get('promo_code'),
            data.get('insurance_policy_id')
        ))
        return jsonify({"message": "Booking updated successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# --- PAYMENT (Simulated) ---

@api_bp.route('/payments', methods=['POST'])
def make_payment():
    """Calls proc_create_payment"""
    data = request.json
    try:
        conn = get_db()
        cur = conn.cursor()
        
        # IN: booking_id, amount, mode, transaction_ref | OUT: payment_id
        cur.execute("""
            CALL proc_create_payment(%s, %s, %s, %s, @pay_id)
        """, (
            data['booking_id'], data['amount'], 
            data['payment_mode'], "TXN_" + str(data['booking_id'])
        ))
        
        cur.execute("SELECT @pay_id")
        pay_id = cur.fetchone()['@pay_id']
        cur.close()
        
        return jsonify({"message": "Payment successful", "payment_id": pay_id}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@api_bp.route('/admin/login', methods=['POST'])
def admin_login():
    """Simple employee login."""
    data = request.json
    email = data.get('email')
    
    emp = query_db("SELECT * FROM Employee WHERE email = %s", (email,), one=True)
    
    if emp:
        return jsonify({"message": "Login successful", "employee": emp}), 200
    return jsonify({"error": "Employee not found"}), 404

@api_bp.route('/admin/cars', methods=['GET'])
def get_all_cars():
    """
    Get all cars with their current status and maintenance info.
    Useful for the fleet dashboard.
    """
    sql = """
        SELECT c.*, b.branch_name 
        FROM Car c
        JOIN Branch b ON c.branch_id = b.branch_id
        ORDER BY c.status, c.car_id
    """
    cars = query_db(sql)
    return jsonify(cars), 200

@api_bp.route('/admin/maintenance', methods=['POST'])
def add_maintenance_log():
    """
    Calls proc_add_maintenance_log to put a car into maintenance.
    """
    data = request.json
    try:
        # Args: car_id, logged_by_emp_id, date_in, date_out, description, cost
        call_proc('proc_add_maintenance_log', (
            data['car_id'],
            data['emp_id'],
            data['date_in'],
            data.get('date_out'), 
            data['description'],
            data['cost']
        ))
        return jsonify({"message": "Maintenance log added"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@api_bp.route('/admin/bookings/ml', methods=['GET'])
def get_bookings_with_scores():
    """
    Fetch bookings (Simplified version without ML).
    """
    sql = """
        SELECT b.booking_id, b.cust_id, b.status, b.car_make, b.car_model, 
               b.start_datetime, b.total_amount
        FROM Booking b
        ORDER BY b.created_at DESC
        LIMIT 50
    """
    bookings = query_db(sql)
    return jsonify(bookings), 200