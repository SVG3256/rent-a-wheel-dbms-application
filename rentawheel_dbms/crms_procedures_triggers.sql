USE rentawheel_db;

DELIMITER $$

-- Function to check car availability for interval
DROP FUNCTION IF EXISTS fn_is_car_available$$
CREATE FUNCTION fn_is_car_available(p_car_id INT, p_start DATETIME, p_end DATETIME)
RETURNS TINYINT DETERMINISTIC
BEGIN
  DECLARE v_cnt INT DEFAULT 0;

  SELECT COUNT(*) INTO v_cnt
  FROM booking b
  WHERE b.car_id = p_car_id
    AND b.status IN ('Confirmed')
    AND NOT (p_end <= b.start_datetime OR p_start >= b.end_datetime);

  IF v_cnt > 0 THEN
    RETURN 0;
  END IF;

  SELECT COUNT(*) INTO v_cnt
  FROM maintenancelogs m
  WHERE m.car_id = p_car_id
    AND m.date_out IS NOT NULL
    AND NOT (p_end <= m.date_in OR p_start >= m.date_out);

  IF v_cnt > 0 THEN
    RETURN 0;
  END IF;
  
  RETURN 1;
END$$

-- Procedure to create customer (signup) and enforces unique email/contact/license
DROP PROCEDURE IF EXISTS proc_create_customer$$
CREATE PROCEDURE proc_create_customer(
  IN p_first_name VARCHAR(64),
  IN p_last_name  VARCHAR(64),
  IN p_dob DATE,
  IN p_email VARCHAR(120),
  IN p_contact_no VARCHAR(40),
  IN p_license_no VARCHAR(60),
  OUT p_new_cust_id INT
)
main_block: BEGIN
  DECLARE v_exists INT DEFAULT 0;

  SELECT COUNT(*) INTO v_exists FROM Customer WHERE email = p_email OR contact_no = p_contact_no OR license_no = p_license_no;
  IF v_exists > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer with provided email/contact/license already exists';
  END IF;

  INSERT INTO Customer (first_name, last_name, dob, email, contact_no, license_no)
  VALUES (p_first_name, p_last_name, p_dob, p_email, p_contact_no, p_license_no);
  SET p_new_cust_id = LAST_INSERT_ID();
END$$

-- Procedure to create booking which attempts to assign available car of requested CarType
DROP PROCEDURE IF EXISTS proc_create_booking$$

CREATE PROCEDURE proc_create_booking(
  IN p_cust_id INT,
  IN p_car_id INT,
  IN p_car_make VARCHAR(80),
  IN p_car_model VARCHAR(80),
  IN p_year YEAR,
  IN p_pickup_branch_id INT,
  IN p_dropoff_branch_id INT,
  IN p_start_datetime DATETIME,
  IN p_end_datetime DATETIME,
  IN p_insurance_policy_id INT,
  IN p_promo_code VARCHAR(20),
  OUT p_booking_id INT
)
main_block: BEGIN
  DECLARE v_car_id INT DEFAULT NULL;
  DECLARE v_daily_rate DECIMAL(9,2) DEFAULT 0;
  DECLARE v_ins_daily DECIMAL(9,2) DEFAULT 0;
  DECLARE v_total DECIMAL(12,2) DEFAULT 0;
  DECLARE v_promo_pct DECIMAL(5,2) DEFAULT 0;
  DECLARE v_overlap INT DEFAULT 0;

  -- 1. Check for overlapping bookings for this customer
  SELECT COUNT(*) INTO v_overlap
  FROM Booking
  WHERE cust_id = p_cust_id
    AND status IN ('Confirmed')
    AND NOT (p_end_datetime <= start_datetime OR p_start_datetime >= end_datetime);

  IF v_overlap > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer has an overlapping active booking';
  END IF;

  -- 2. Find an available car matching criteria
  SELECT car_id INTO v_car_id
  FROM Car
  WHERE car_make = p_car_make 
    AND car_model = p_car_model 
    AND year = p_year
    AND branch_id = p_pickup_branch_id
    AND (p_car_id IS NULL OR car_id = p_car_id)
    AND status IN ('Available', 'Booked', 'Maintenance') 
    AND status != 'Retired'
    -- Uses the existing fn_is_car_available check
    AND fn_is_car_available(car_id, p_start_datetime, p_end_datetime) = 1
  LIMIT 1;

  IF v_car_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Selected car is no longer available for these dates';
  END IF;

  -- 3. Calculate Totals (Rate + Insurance - Promo)
  SELECT daily_rate INTO v_daily_rate FROM CarType WHERE car_make = p_car_make AND car_model = p_car_model AND year = p_year LIMIT 1;
  
  IF p_insurance_policy_id IS NOT NULL THEN
    SELECT daily_cost INTO v_ins_daily FROM Insurance WHERE policy_id = p_insurance_policy_id LIMIT 1;
  END IF;

  IF p_promo_code IS NOT NULL THEN
    SELECT discount_perc INTO v_promo_pct FROM Promotion WHERE promo_code = p_promo_code LIMIT 1;
  END IF;

  SET v_total = (v_daily_rate + IFNULL(v_ins_daily,0)) * GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, p_start_datetime, p_end_datetime)/24));
  IF v_promo_pct > 0 THEN
    SET v_total = v_total * (1 - v_promo_pct/100);
  END IF;

  -- 4. Insert the Booking
  INSERT INTO Booking (cust_id, car_id, car_make, car_model, year, pickup_branch_id, dropoff_branch_id, insurance_policy_id, promo_code, start_datetime, end_datetime, total_amount, status, created_at)
  VALUES (p_cust_id, v_car_id, p_car_make, p_car_model, p_year, p_pickup_branch_id, p_dropoff_branch_id, p_insurance_policy_id, p_promo_code, p_start_datetime, p_end_datetime, v_total, 'Confirmed', NOW());

  SET p_booking_id = LAST_INSERT_ID();

  -- 5. Update Car Status
  UPDATE Car SET status = 'Booked' WHERE car_id = v_car_id;

  -- 6. Refresh Customer Stats (REMOVED: proc_refresh_insurance_feature_for_booking)
  CALL proc_update_customer_features_for_customer(p_cust_id);
END$$

-- Procedure to assign car to booking
DROP PROCEDURE IF EXISTS proc_assign_car_to_booking$$
CREATE PROCEDURE proc_assign_car_to_booking(
  IN p_booking_id INT,
  IN p_car_id INT
)
main_block: BEGIN
  DECLARE v_exists INT DEFAULT 0;
  DECLARE v_start DATETIME;
  DECLARE v_end DATETIME;
  DECLARE v_current_car_id INT;

  SELECT COUNT(*) INTO v_exists FROM Booking WHERE booking_id = p_booking_id;
  IF v_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found';
  END IF;

  SELECT start_datetime, end_datetime, car_id INTO v_start, v_end, v_current_car_id FROM Booking WHERE booking_id = p_booking_id LIMIT 1;

  IF p_car_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'car_id cannot be NULL';
  END IF;

  SELECT COUNT(*) INTO v_exists FROM Car WHERE car_id = p_car_id;
  IF v_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Car not found';
  END IF;

  IF fn_is_car_available(p_car_id, v_start, v_end) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Car not available for the requested interval';
  END IF;

  UPDATE Booking SET car_id = p_car_id, status = 'Confirmed' WHERE booking_id = p_booking_id;
  UPDATE Car SET status = 'Booked' WHERE car_id = p_car_id;

  IF v_current_car_id IS NOT NULL AND v_current_car_id <> p_car_id THEN
    UPDATE Car SET status = 'Available' WHERE car_id = v_current_car_id;
  END IF;

  CALL proc_update_customer_features_for_customer((SELECT cust_id FROM Booking WHERE booking_id = p_booking_id));
END$$

-- Procedure to update booking
DROP PROCEDURE IF EXISTS proc_update_booking$$
CREATE PROCEDURE proc_update_booking(
  IN p_booking_id INT,
  IN p_start_datetime DATETIME,
  IN p_end_datetime DATETIME,
  IN p_promo_code VARCHAR(20),
  IN p_insurance_policy_id INT
)
main_block: BEGIN
  DECLARE v_exists INT DEFAULT 0;
  DECLARE v_cust_id INT;
  DECLARE v_car_id INT;
  DECLARE v_current_start DATETIME;
  DECLARE v_current_end DATETIME;

  SELECT cust_id, car_id, start_datetime, end_datetime 
  INTO v_cust_id, v_car_id, v_current_start, v_current_end 
  FROM Booking WHERE booking_id = p_booking_id LIMIT 1;

  IF v_cust_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found';
  END IF;

  SET p_start_datetime = COALESCE(p_start_datetime, v_current_start);
  SET p_end_datetime = COALESCE(p_end_datetime, v_current_end);

  IF p_start_datetime >= p_end_datetime THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid rental period';
  END IF;

  IF v_car_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_exists
    FROM Booking
    WHERE car_id = v_car_id
      AND booking_id != p_booking_id
      AND status IN ('Confirmed')
      AND NOT (p_end_datetime <= start_datetime OR p_start_datetime >= end_datetime);

    IF v_exists > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Assigned car not available for new dates';
    END IF;

    SELECT COUNT(*) INTO v_exists
    FROM MaintenanceLogs
    WHERE car_id = v_car_id
      AND date_out IS NOT NULL
      AND NOT (p_end_datetime <= date_in OR p_start_datetime >= date_out);

    IF v_exists > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Car is scheduled for maintenance';
    END IF;
  END IF;

  UPDATE Booking
  SET start_datetime = p_start_datetime,
      end_datetime   = p_end_datetime,
      promo_code     = p_promo_code,
      insurance_policy_id = p_insurance_policy_id
  WHERE booking_id = p_booking_id;

  CALL proc_update_customer_features_for_customer(v_cust_id);
END$$

-- Procedure to  cancel booking
DROP PROCEDURE IF EXISTS proc_cancel_booking$$

CREATE PROCEDURE proc_cancel_booking(IN p_booking_id INT)
main_block: BEGIN
  DECLARE v_exists INT DEFAULT 0;
  DECLARE v_car_id INT;
  DECLARE v_cust INT;

  -- 1. Check if booking exists
  SELECT COUNT(*) INTO v_exists FROM Booking WHERE booking_id = p_booking_id;
  IF v_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found';
  END IF;

  -- 2. Get booking details
  SELECT car_id, cust_id INTO v_car_id, v_cust FROM Booking WHERE booking_id = p_booking_id LIMIT 1;
  
  -- 3. Mark booking as Cancelled
  UPDATE Booking SET status = 'Cancelled' WHERE booking_id = p_booking_id;

  -- 4. Make the car available again
  IF v_car_id IS NOT NULL THEN
    UPDATE Car SET status = 'Available' WHERE car_id = v_car_id;
  END IF;

  -- 5. Update customer stats
  CALL proc_update_customer_features_for_customer(v_cust);

END$$

-- Procedure to create payment
DROP PROCEDURE IF EXISTS proc_create_payment$$
CREATE PROCEDURE proc_create_payment(
  IN p_booking_id INT,
  IN p_amount DECIMAL(12,2),
  IN p_payment_mode ENUM('card','cash','wallet','online'),
  IN p_transaction_ref VARCHAR(150),
  OUT p_payment_id INT
)
main_block: BEGIN
  DECLARE v_exists INT DEFAULT 0;

  SELECT COUNT(*) INTO v_exists FROM Booking WHERE booking_id = p_booking_id;
  IF v_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found';
  END IF;

  INSERT INTO Payment (booking_id, amount, payment_mode, payment_status, transaction_ref)
  VALUES (p_booking_id, p_amount, p_payment_mode, 'Successful', p_transaction_ref);

  SET p_payment_id = LAST_INSERT_ID();
END$$

-- Procdure to  add feedback - only after booking completed and unique feedback per booking
DROP PROCEDURE IF EXISTS proc_add_feedback$$
CREATE PROCEDURE proc_add_feedback(
  IN p_cust_id INT,
  IN p_booking_id INT,
  IN p_rating TINYINT,
  IN p_comment TEXT
)
main_block: BEGIN
  DECLARE v_exists INT DEFAULT 0;
  DECLARE v_booking_owner INT;
  DECLARE v_status ENUM('Confirmed','Completed','Cancelled');

  SELECT COUNT(*) INTO v_exists FROM Booking WHERE booking_id = p_booking_id;
  IF v_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found';
  END IF;

  SELECT cust_id, status INTO v_booking_owner, v_status FROM Booking WHERE booking_id = p_booking_id LIMIT 1;
  IF v_booking_owner <> p_cust_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Feedback must be provided by booking customer';
  END IF;

  IF v_status <> 'Completed' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Feedback allowed only for completed bookings';
  END IF;

  -- ensure no existing feedback for booking
  SELECT COUNT(*) INTO v_exists FROM Feedback WHERE booking_id = p_booking_id;
  IF v_exists > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Feedback already submitted for this booking';
  END IF;

  INSERT INTO Feedback (cust_id, booking_id, rating, comment, submission_date)
  VALUES (p_cust_id, p_booking_id, p_rating, p_comment, NOW());
END$$

-- Procedure to add maintenance log and sets car status to 'Maintenance'
DROP PROCEDURE IF EXISTS proc_add_maintenance_log$$
CREATE PROCEDURE proc_add_maintenance_log(
  IN p_car_id INT,
  IN p_logged_by_emp_id INT,
  IN p_date_in DATETIME,
  IN p_date_out DATETIME,
  IN p_description TEXT,
  IN p_cost DECIMAL(10,2)
)
main_block: BEGIN
  DECLARE v_car_exists INT DEFAULT 0;
  DECLARE v_emp_exists INT DEFAULT 0;

  SELECT COUNT(*) INTO v_car_exists FROM Car WHERE car_id = p_car_id;
  IF v_car_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Car not found';
  END IF;

  IF p_logged_by_emp_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_emp_exists FROM Employee WHERE emp_id = p_logged_by_emp_id;
    IF v_emp_exists = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Logging employee not found';
    END IF;
  END IF;

  INSERT INTO MaintenanceLogs (car_id, logged_by_emp_id, date_in, date_out, description, cost)
  VALUES (p_car_id, p_logged_by_emp_id, p_date_in, p_date_out, p_description, p_cost);
  UPDATE Car SET status = 'Maintenance' WHERE car_id = p_car_id;
END$$

-- Trigger when MaintenanceLogs inserted set car to Maintenance
DROP TRIGGER IF EXISTS trg_after_insert_maintenance$$
CREATE TRIGGER trg_after_insert_maintenance AFTER INSERT ON MaintenanceLogs
FOR EACH ROW
BEGIN
  UPDATE Car SET status = 'Maintenance' WHERE car_id = NEW.car_id;
END$$

-- Trigger Booking AFTER INSERT/UPDATE/DELETE to keep ML features updated
DROP TRIGGER IF EXISTS trg_after_insert_booking$$
CREATE TRIGGER trg_after_insert_booking AFTER INSERT ON Booking
FOR EACH ROW
BEGIN
  CALL proc_update_customer_features_for_customer(NEW.cust_id);
END$$

DROP TRIGGER IF EXISTS trg_after_update_booking$$
CREATE TRIGGER trg_after_update_booking AFTER UPDATE ON Booking
FOR EACH ROW
BEGIN
  CALL proc_update_customer_features_for_customer(NEW.cust_id);
END$$

DROP TRIGGER IF EXISTS trg_after_delete_booking$$
CREATE TRIGGER trg_after_delete_booking AFTER DELETE ON Booking
FOR EACH ROW
BEGIN
  CALL proc_update_customer_features_for_customer(OLD.cust_id);
END$$

DELIMITER ;

-- Procedure to update customer features for specific customer
DROP PROCEDURE IF EXISTS proc_update_customer_features_for_customer;
DELIMITER $$
CREATE PROCEDURE proc_update_customer_features_for_customer (IN p_cust_id INT)
BEGIN
  DECLARE v_total INT DEFAULT 0;
  DECLARE v_avg_days DECIMAL(6,2) DEFAULT 0;
  DECLARE v_avg_spend DECIMAL(10,2) DEFAULT 0;
  DECLARE v_ins_rate DECIMAL(6,4) DEFAULT 0;
  DECLARE v_cancel_rate DECIMAL(6,4) DEFAULT 0;
  DECLARE v_last_dt DATETIME;

  SELECT COUNT(*) INTO v_total FROM Booking WHERE cust_id = p_cust_id;

  SELECT COALESCE(AVG(CEIL(TIMESTAMPDIFF(HOUR, start_datetime, end_datetime)/24)),0)
    INTO v_avg_days
    FROM Booking WHERE cust_id = p_cust_id AND start_datetime IS NOT NULL AND end_datetime IS NOT NULL;

  SELECT COALESCE(AVG(total_amount),0) INTO v_avg_spend FROM Booking WHERE cust_id = p_cust_id AND total_amount > 0;

  SELECT COALESCE(SUM(CASE WHEN insurance_policy_id IS NOT NULL THEN 1 ELSE 0 END)/GREATEST(COUNT(*),1),0)
    INTO v_ins_rate
    FROM Booking WHERE cust_id = p_cust_id;

  SELECT COALESCE(SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END)/GREATEST(COUNT(*),1),0)
    INTO v_cancel_rate
    FROM Booking WHERE cust_id = p_cust_id;

  SELECT MAX(start_datetime) INTO v_last_dt FROM Booking WHERE cust_id = p_cust_id;

  INSERT INTO customer_features (cust_id, total_bookings, avg_rental_days, avg_spend, insurance_accept_rate, cancel_rate, last_booking_date)
  VALUES (p_cust_id, v_total, v_avg_days, v_avg_spend, v_ins_rate, v_cancel_rate, v_last_dt)
  ON DUPLICATE KEY UPDATE
    total_bookings = VALUES(total_bookings),
    avg_rental_days = VALUES(avg_rental_days),
    avg_spend = VALUES(avg_spend),
    insurance_accept_rate = VALUES(insurance_accept_rate),
    cancel_rate = VALUES(cancel_rate),
    last_booking_date = VALUES(last_booking_date),
    updated_at = CURRENT_TIMESTAMP;
END$$
DELIMITER ;

-- Procedure to update customer features for all customers
DROP PROCEDURE IF EXISTS proc_update_customer_features_all;
DELIMITER $$
CREATE PROCEDURE proc_update_customer_features_all()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE cur_cust INT;
  DECLARE cur CURSOR FOR SELECT cust_id FROM Customer;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO cur_cust;
    IF done=1 THEN 
		LEAVE read_loop; 
	END IF;
    CALL proc_update_customer_features_for_customer(cur_cust);
  END LOOP;
  CLOSE cur;
END$$
DELIMITER ;