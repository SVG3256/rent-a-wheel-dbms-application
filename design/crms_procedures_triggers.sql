USE rentawheel_db;

DELIMITER $$

/* 1) Utility function: check car availability for interval (returns 1 available, 0 not) */
DROP FUNCTION IF EXISTS fn_is_car_available$$
CREATE FUNCTION fn_is_car_available(p_car_id INT, p_start DATETIME, p_end DATETIME)
RETURNS TINYINT DETERMINISTIC
BEGIN
  DECLARE v_cnt INT DEFAULT 0;

  SELECT COUNT(*) INTO v_cnt
  FROM Booking b
  WHERE b.car_id = p_car_id
    AND b.status IN ('Confirmed','Ongoing')
    AND NOT (p_end <= b.start_datetime OR p_start >= b.end_datetime);

  IF v_cnt > 0 THEN
    RETURN 0;
  END IF;

  SELECT COUNT(*) INTO v_cnt
  FROM MaintenanceLogs m
  WHERE m.car_id = p_car_id
    AND m.date_out IS NOT NULL
    AND NOT (p_end <= m.date_in OR p_start >= m.date_out);

  IF v_cnt > 0 THEN
    RETURN 0;
  END IF;

  RETURN 1;
END$$

/* 2) Create customer (signup) - enforces unique email/contact/license */
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

  -- check duplicates
  SELECT COUNT(*) INTO v_exists FROM Customer WHERE email = p_email OR contact_no = p_contact_no OR license_no = p_license_no;
  IF v_exists > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer with provided email/contact/license already exists';
  END IF;

  INSERT INTO Customer (first_name, last_name, dob, email, contact_no, license_no)
  VALUES (p_first_name, p_last_name, p_dob, p_email, p_contact_no, p_license_no);

  SET p_new_cust_id = LAST_INSERT_ID();
END$$

/* 3) Create booking - simple; attempts to assign available car of requested CarType; enforces "one active booking at a time" */
DROP PROCEDURE IF EXISTS proc_create_booking$$
CREATE PROCEDURE proc_create_booking(
  IN p_cust_id INT,
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
  DECLARE v_cust_exists INT DEFAULT 0;
  DECLARE v_cartype_exists INT DEFAULT 0;
  DECLARE v_overlap INT DEFAULT 0;
  DECLARE v_duration_days INT DEFAULT 1;
  DECLARE v_car_id INT DEFAULT NULL;
  DECLARE v_daily_rate DECIMAL(9,2) DEFAULT 0;
  DECLARE v_ins_daily DECIMAL(9,2) DEFAULT 0;
  DECLARE v_total DECIMAL(12,2) DEFAULT 0;
  DECLARE v_promo_pct DECIMAL(5,2) DEFAULT 0;

  -- validations
  IF p_start_datetime >= p_end_datetime THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid rental period: start must be before end';
  END IF;

  SELECT COUNT(*) INTO v_cust_exists FROM Customer WHERE cust_id = p_cust_id;
  IF v_cust_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer does not exist';
  END IF;

  SELECT COUNT(*) INTO v_cartype_exists FROM CarType WHERE car_make = p_car_make AND car_model = p_car_model AND year = p_year;
  IF v_cartype_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Requested car type not found';
  END IF;

  -- enforce one active booking at a time: no overlapping Booked/Confirmed/Ongoing
  SELECT COUNT(*) INTO v_overlap
  FROM Booking
  WHERE cust_id = p_cust_id
    AND status IN ('Booked','Confirmed','Ongoing')
    AND NOT (p_end_datetime <= start_datetime OR p_start_datetime >= end_datetime);

  IF v_overlap > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer has an overlapping active booking';
  END IF;

  -- duration (in days)
  SET v_duration_days = GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, p_start_datetime, p_end_datetime)/24));

  -- try to find an available car of that type in pickup branch
  SELECT car_id INTO v_car_id
  FROM Car
  WHERE car_make = p_car_make AND car_model = p_car_model AND year = p_year
    AND branch_id = p_pickup_branch_id
    AND status = 'Available'
  LIMIT 1;

  IF v_car_id IS NOT NULL THEN
    -- double-check availability for those dates using fn_is_car_available
    IF fn_is_car_available(v_car_id, p_start_datetime, p_end_datetime) = 0 THEN
      SET v_car_id = NULL;
    END IF;
  END IF;

  -- compute total_amount: cartype.daily_rate * days + insurance.daily_cost * days - promo
  SELECT daily_rate INTO v_daily_rate FROM CarType WHERE car_make = p_car_make AND car_model = p_car_model AND year = p_year LIMIT 1;
  IF p_insurance_policy_id IS NOT NULL THEN
    SELECT daily_cost INTO v_ins_daily FROM Insurance WHERE policy_id = p_insurance_policy_id LIMIT 1;
  ELSE
    SET v_ins_daily = 0;
  END IF;

  IF p_promo_code IS NOT NULL THEN
    SELECT discount_perc, start_date, end_date INTO v_promo_pct, @p_start, @p_end FROM Promotion WHERE promo_code = p_promo_code LIMIT 1;
    IF v_promo_pct IS NULL THEN
      SET v_promo_pct = 0;
    ELSE
      IF NOT (p_start_datetime BETWEEN @p_start AND @p_end) THEN
        -- promo invalid for booking date
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Promo code not valid for booking dates';
      END IF;
    END IF;
  END IF;

  SET v_total = (v_daily_rate + v_ins_daily) * v_duration_days;
  IF v_promo_pct > 0 THEN
    SET v_total = v_total * (1 - v_promo_pct/100);
  END IF;

  -- insert booking (car_id may be NULL)
  INSERT INTO Booking (cust_id, car_id, car_make, car_model, year, pickup_branch_id, dropoff_branch_id, insurance_policy_id, promo_code, start_datetime, end_datetime, total_amount, status, created_at)
  VALUES (p_cust_id, v_car_id, p_car_make, p_car_model, p_year, p_pickup_branch_id, p_dropoff_branch_id, p_insurance_policy_id, p_promo_code, p_start_datetime, p_end_datetime, v_total, IF(v_car_id IS NULL,'Booked','Confirmed'), NOW());

  SET p_booking_id = LAST_INSERT_ID();

  -- if a car was assigned, update its status to Booked (prevents race)
  IF v_car_id IS NOT NULL THEN
    UPDATE Car SET status = 'Booked' WHERE car_id = v_car_id;
  END IF;

  -- refresh ML records for this booking and customer (procedures defined in ML section)
  CALL proc_refresh_insurance_feature_for_booking(p_booking_id);
  CALL proc_update_customer_features_for_customer(p_cust_id);
END$$

/* 4) Assign car to booking (explicit) */
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

  -- check car exists
  SELECT COUNT(*) INTO v_exists FROM Car WHERE car_id = p_car_id;
  IF v_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Car not found';
  END IF;

  -- check availability
  IF fn_is_car_available(p_car_id, v_start, v_end) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Car not available for the requested interval';
  END IF;

  -- assign the car (and mark it Booked) and set booking status -> Confirmed
  UPDATE Booking SET car_id = p_car_id, status = 'Confirmed' WHERE booking_id = p_booking_id;
  UPDATE Car SET status = 'Booked' WHERE car_id = p_car_id;

  -- if booking had previous car assigned, free that car
  IF v_current_car_id IS NOT NULL AND v_current_car_id <> p_car_id THEN
    UPDATE Car SET status = 'Available' WHERE car_id = v_current_car_id;
  END IF;

  -- update ML features
  CALL proc_refresh_insurance_feature_for_booking(p_booking_id);
  CALL proc_update_customer_features_for_customer((SELECT cust_id FROM Booking WHERE booking_id = p_booking_id));
END$$

/* 5) Update booking (simple; supports changing dates & promo/insurance; enforces validations) */
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

  SELECT COUNT(*) INTO v_exists FROM Booking WHERE booking_id = p_booking_id;
  IF v_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found';
  END IF;

  IF p_start_datetime IS NOT NULL AND p_end_datetime IS NOT NULL AND p_start_datetime >= p_end_datetime THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid rental period';
  END IF;

  SELECT cust_id, car_id INTO v_cust_id, v_car_id FROM Booking WHERE booking_id = p_booking_id LIMIT 1;

  -- if a car is assigned, verify it is still available for new dates
  IF v_car_id IS NOT NULL AND p_start_datetime IS NOT NULL AND p_end_datetime IS NOT NULL THEN
    IF fn_is_car_available(v_car_id, p_start_datetime, p_end_datetime) = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Assigned car not available for new dates';
    END IF;
  END IF;

  -- apply updates (only non-null parameters)
  UPDATE Booking
  SET start_datetime = COALESCE(p_start_datetime, start_datetime),
      end_datetime   = COALESCE(p_end_datetime, end_datetime),
      promo_code     = p_promo_code,
      insurance_policy_id = p_insurance_policy_id
  WHERE booking_id = p_booking_id;

  -- refresh ML
  CALL proc_refresh_insurance_feature_for_booking(p_booking_id);
  CALL proc_update_customer_features_for_customer(v_cust_id);
END$$

/* 6) Cancel booking */
DROP PROCEDURE IF EXISTS proc_cancel_booking$$
CREATE PROCEDURE proc_cancel_booking(IN p_booking_id INT)
main_block: BEGIN
  DECLARE v_exists INT DEFAULT 0;
  DECLARE v_car_id INT;
  DECLARE v_cust INT;

  SELECT COUNT(*) INTO v_exists FROM Booking WHERE booking_id = p_booking_id;
  IF v_exists = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found';
  END IF;

  SELECT car_id, cust_id INTO v_car_id, v_cust FROM Booking WHERE booking_id = p_booking_id LIMIT 1;

  UPDATE Booking SET status = 'Cancelled' WHERE booking_id = p_booking_id;

  -- free assigned car if any
  IF v_car_id IS NOT NULL THEN
    UPDATE Car SET status = 'Available' WHERE car_id = v_car_id;
  END IF;

  -- refresh ML
  CALL proc_update_customer_features_for_customer(v_cust);
  DELETE FROM ml_insurance_features WHERE booking_id = p_booking_id;
  DELETE FROM insurance_predictions WHERE booking_id = p_booking_id;
END$$

/* 7) Create Payment */
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

  -- optional: set booking to Confirmed if it was Booked
  UPDATE Booking SET status = CASE WHEN status = 'Booked' THEN 'Confirmed' ELSE status END WHERE booking_id = p_booking_id;
END$$

/* 8) Add feedback - only after booking completed and unique feedback per booking */
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
  DECLARE v_status ENUM('Booked','Confirmed','Ongoing','Completed','Cancelled');

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

/* 9) Add maintenance log (updates car status to Maintenance) */
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

  -- set car status
  UPDATE Car SET status = 'Maintenance' WHERE car_id = p_car_id;
END$$

/* 10) Trigger: when MaintenanceLogs inserted set car to Maintenance (defensive) */
DROP TRIGGER IF EXISTS trg_after_insert_maintenance$$
CREATE TRIGGER trg_after_insert_maintenance AFTER INSERT ON MaintenanceLogs
FOR EACH ROW
BEGIN
  UPDATE Car SET status = 'Maintenance' WHERE car_id = NEW.car_id;
END$$

/* 11) Triggers: Booking AFTER INSERT/UPDATE/DELETE to keep ML features updated (simple calls) */
DROP TRIGGER IF EXISTS trg_after_insert_booking$$
CREATE TRIGGER trg_after_insert_booking AFTER INSERT ON Booking
FOR EACH ROW
BEGIN
  CALL proc_refresh_insurance_feature_for_booking(NEW.booking_id);
  CALL proc_update_customer_features_for_customer(NEW.cust_id);
END$$

DROP TRIGGER IF EXISTS trg_after_update_booking$$
CREATE TRIGGER trg_after_update_booking AFTER UPDATE ON Booking
FOR EACH ROW
BEGIN
  CALL proc_refresh_insurance_feature_for_booking(NEW.booking_id);
  CALL proc_update_customer_features_for_customer(NEW.cust_id);
END$$

DROP TRIGGER IF EXISTS trg_after_delete_booking$$
CREATE TRIGGER trg_after_delete_booking AFTER DELETE ON Booking
FOR EACH ROW
BEGIN
  CALL proc_update_customer_features_for_customer(OLD.cust_id);
  DELETE FROM ml_insurance_features WHERE booking_id = OLD.booking_id;
  DELETE FROM insurance_predictions WHERE booking_id = OLD.booking_id;
END$$

DELIMITER ;

-- 1) proc_update_customer_features_for_customer(cust_id)
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

-- 2) proc_update_customer_features_all()
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
    IF done THEN LEAVE read_loop; END IF;
    CALL proc_update_customer_features_for_customer(cur_cust);
  END LOOP;
  CLOSE cur;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS proc_refresh_insurance_feature_for_booking;
DELIMITER $$
CREATE PROCEDURE proc_refresh_insurance_feature_for_booking (IN p_booking_id INT)
main_block: BEGIN
  DECLARE v_not_found INT DEFAULT 0;
  DECLARE v_cust INT;
  DECLARE v_start DATETIME;
  DECLARE v_end DATETIME;
  DECLARE v_created DATETIME;
  DECLARE v_lead INT;
  DECLARE v_duration INT;
  DECLARE v_is_weekend TINYINT DEFAULT 0;
  DECLARE v_cust_ins_rate DECIMAL(6,4) DEFAULT 0;
  DECLARE v_car_make VARCHAR(80);
  DECLARE v_car_model VARCHAR(80);
  DECLARE v_year YEAR;
  DECLARE v_car_premium TINYINT DEFAULT 0;
  DECLARE v_promo_code VARCHAR(20);
  DECLARE v_promo_applied TINYINT DEFAULT 0;
  DECLARE v_total_est DECIMAL(10,2) DEFAULT 0;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = 1;

  SELECT cust_id, start_datetime, end_datetime, created_at, promo_code,
         car_make, car_model, year, total_amount
    INTO v_cust, v_start, v_end, v_created, v_promo_code,
         v_car_make, v_car_model, v_year, v_total_est
  FROM Booking
  WHERE booking_id = p_booking_id
  LIMIT 1;

  IF v_not_found = 1 OR v_start IS NULL THEN
    LEAVE main_block;
  END IF;

  SET v_lead = GREATEST(0, DATEDIFF(v_start, v_created));
  SET v_duration = GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, v_start, v_end)/24));
  SET v_is_weekend = IF(DAYOFWEEK(v_start) IN (1,7),1,0);

  SELECT COALESCE(
           SUM(CASE WHEN insurance_policy_id IS NOT NULL THEN 1 END) 
           / GREATEST(COUNT(*),1)
         ,0)
    INTO v_cust_ins_rate
    FROM Booking
    WHERE cust_id = v_cust AND booking_id <> p_booking_id;

  SELECT CASE WHEN ct.daily_rate > (SELECT AVG(daily_rate) FROM CarType) 
              THEN 1 ELSE 0 END
    INTO v_car_premium
    FROM CarType ct
    WHERE ct.car_make = v_car_make 
      AND ct.car_model = v_car_model 
      AND ct.year = v_year
    LIMIT 1;

  SET v_promo_applied = IF(v_promo_code IS NULL, 0, 1);
  SET v_total_est = COALESCE(v_total_est, 0);

  INSERT INTO ml_insurance_features
      (booking_id, cust_id, lead_days, duration_days, is_weekend_start,
       cust_past_insurance_rate, car_type_premium, promo_applied,
       total_estimate, created_at)
  VALUES
      (p_booking_id, v_cust, v_lead, v_duration, v_is_weekend,
       v_cust_ins_rate, COALESCE(v_car_premium,0), v_promo_applied,
       v_total_est, NOW())
  ON DUPLICATE KEY UPDATE
      lead_days = VALUES(lead_days),
      duration_days = VALUES(duration_days),
      is_weekend_start = VALUES(is_weekend_start),
      cust_past_insurance_rate = VALUES(cust_past_insurance_rate),
      car_type_premium = VALUES(car_type_premium),
      promo_applied = VALUES(promo_applied),
      total_estimate = VALUES(total_estimate),
      created_at = CURRENT_TIMESTAMP;

END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS proc_score_insurance_for_booking;
DELIMITER $$
CREATE PROCEDURE proc_score_insurance_for_booking (IN p_booking_id INT, OUT p_probability DOUBLE)
BEGIN
  DECLARE v_not_found INT DEFAULT 0;
  DECLARE v_lead INT DEFAULT 0;
  DECLARE v_duration INT DEFAULT 0;
  DECLARE v_is_weekend INT DEFAULT 0;
  DECLARE v_cust_ins_rate DOUBLE DEFAULT 0;
  DECLARE v_car_premium INT DEFAULT 0;
  DECLARE v_promo_applied INT DEFAULT 0;
  DECLARE v_total_est DOUBLE DEFAULT 0;
  DECLARE c_intercept DOUBLE DEFAULT 0;
  DECLARE c_lead DOUBLE DEFAULT 0;
  DECLARE c_duration DOUBLE DEFAULT 0;
  DECLARE c_weekend DOUBLE DEFAULT 0;
  DECLARE c_custins DOUBLE DEFAULT 0;
  DECLARE c_premium DOUBLE DEFAULT 0;
  DECLARE c_promo DOUBLE DEFAULT 0;
  DECLARE c_totalest DOUBLE DEFAULT 0;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = 1;

  -- Try to read features from ml_insurance_features
  IF EXISTS (SELECT 1 FROM ml_insurance_features WHERE booking_id = p_booking_id) THEN
    SELECT lead_days, duration_days, is_weekend_start, cust_past_insurance_rate, car_type_premium, promo_applied, total_estimate
      INTO v_lead, v_duration, v_is_weekend, v_cust_ins_rate, v_car_premium, v_promo_applied, v_total_est
    FROM ml_insurance_features
    WHERE booking_id = p_booking_id
    LIMIT 1;

    -- if no row found for some reason, try to refresh
    IF v_not_found = 1 THEN
      SET v_not_found = 0;
      CALL proc_refresh_insurance_feature_for_booking(p_booking_id);
      SELECT lead_days, duration_days, is_weekend_start, cust_past_insurance_rate, car_type_premium, promo_applied, total_estimate
        INTO v_lead, v_duration, v_is_weekend, v_cust_ins_rate, v_car_premium, v_promo_applied, v_total_est
      FROM ml_insurance_features
      WHERE booking_id = p_booking_id
      LIMIT 1;
    END IF;
  ELSE
    -- compute features on the fly and insert into ml_insurance_features
    CALL proc_refresh_insurance_feature_for_booking(p_booking_id);
    SELECT lead_days, duration_days, is_weekend_start, cust_past_insurance_rate, car_type_premium, promo_applied, total_estimate
      INTO v_lead, v_duration, v_is_weekend, v_cust_ins_rate, v_car_premium, v_promo_applied, v_total_est
    FROM ml_insurance_features
    WHERE booking_id = p_booking_id
    LIMIT 1;
  END IF;

  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='__intercept__' LIMIT 1),0) INTO c_intercept;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='lead_days' LIMIT 1),0) INTO c_lead;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='duration_days' LIMIT 1),0) INTO c_duration;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='is_weekend_start' LIMIT 1),0) INTO c_weekend;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='cust_past_insurance_rate' LIMIT 1),0) INTO c_custins;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='car_type_premium' LIMIT 1),0) INTO c_premium;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='promo_applied' LIMIT 1),0) INTO c_promo;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='total_estimate' LIMIT 1),0) INTO c_totalest;

  -- logistic linear combination then sigmoid
  SET @lin = c_intercept
    + c_lead * COALESCE(v_lead,0)
    + c_duration * COALESCE(v_duration,0)
    + c_weekend * COALESCE(v_is_weekend,0)
    + c_custins * COALESCE(v_cust_ins_rate,0)
    + c_premium * COALESCE(v_car_premium,0)
    + c_promo * COALESCE(v_promo_applied,0)
    + c_totalest * COALESCE(v_total_est,0);

  SET p_probability = 1.0 / (1.0 + EXP(-@lin));

  -- persist the score for quick UI read
  INSERT INTO insurance_predictions (booking_id, probability, scored_at)
  VALUES (p_booking_id, p_probability, NOW())
  ON DUPLICATE KEY UPDATE probability = VALUES(probability), scored_at = VALUES(scored_at);
END$$
DELIMITER ;

-- 5) TRIGGERS: Booking AFTER INSERT / UPDATE / DELETE
DROP TRIGGER IF EXISTS trg_after_insert_booking;
DELIMITER $$
CREATE TRIGGER trg_after_insert_booking AFTER INSERT ON Booking
FOR EACH ROW
BEGIN
  CALL proc_refresh_insurance_feature_for_booking(NEW.booking_id);
  CALL proc_update_customer_features_for_customer(NEW.cust_id);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_after_update_booking;
DELIMITER $$
CREATE TRIGGER trg_after_update_booking AFTER UPDATE ON Booking
FOR EACH ROW
BEGIN
  CALL proc_refresh_insurance_feature_for_booking(NEW.booking_id);
  CALL proc_update_customer_features_for_customer(NEW.cust_id);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_after_delete_booking;
DELIMITER $$
CREATE TRIGGER trg_after_delete_booking AFTER DELETE ON Booking
FOR EACH ROW
BEGIN
  CALL proc_update_customer_features_for_customer(OLD.cust_id);
END$$
DELIMITER ;

-- 6) TRIGGER: when a MaintenanceLogs row inserted -> set Car.status = 'Maintenance'
DROP TRIGGER IF EXISTS trg_after_insert_maintenance;
DELIMITER $$
CREATE TRIGGER trg_after_insert_maintenance AFTER INSERT ON MaintenanceLogs
FOR EACH ROW
BEGIN
  UPDATE Car SET status = 'Maintenance' WHERE car_id = NEW.car_id;
END$$
DELIMITER ;

-- 7) Utility function: fn_is_car_available(car_id, start, end)
DROP FUNCTION IF EXISTS fn_is_car_available;
DELIMITER $$
CREATE FUNCTION fn_is_car_available(p_car_id INT, p_start DATETIME, p_end DATETIME)
RETURNS TINYINT DETERMINISTIC
BEGIN
  DECLARE cnt INT DEFAULT 0;

  SELECT COUNT(*) INTO cnt
  FROM Booking b
  WHERE b.car_id = p_car_id
    AND b.status IN ('Confirmed','Ongoing')
    AND NOT (p_end <= b.start_datetime OR p_start >= b.end_datetime);

  IF cnt > 0 THEN
    RETURN 0;
  END IF;

  SELECT COUNT(*) INTO cnt
  FROM MaintenanceLogs m
  WHERE m.car_id = p_car_id
    AND m.date_out IS NOT NULL
    AND NOT (p_end <= m.date_in OR p_start >= m.date_out);

  IF cnt > 0 THEN
    RETURN 0;
  END IF;

  RETURN 1;
END$$
DELIMITER ;

DELIMITER $$

/* 1) Refresh single customer's aggregated features (already used above) */
DROP PROCEDURE IF EXISTS proc_update_customer_features_for_customer$$
CREATE PROCEDURE proc_update_customer_features_for_customer(IN p_cust_id INT)
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

/* 2) Refresh all customers' aggregated features (bulk) */
DROP PROCEDURE IF EXISTS proc_update_customer_features_all$$
CREATE PROCEDURE proc_update_customer_features_all()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE cur_cust INT;
  DECLARE cur CURSOR FOR SELECT cust_id FROM Customer;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO cur_cust;
    IF done = 1 THEN
      LEAVE read_loop;
    END IF;
    CALL proc_update_customer_features_for_customer(cur_cust);
  END LOOP;
  CLOSE cur;
END$$

/* 3) Refresh ml_insurance_features for a single booking (safe) */
DROP PROCEDURE IF EXISTS proc_refresh_insurance_feature_for_booking$$
CREATE PROCEDURE proc_refresh_insurance_feature_for_booking (IN p_booking_id INT)
main_block: BEGIN
  DECLARE v_not_found INT DEFAULT 0;
  DECLARE v_cust INT;
  DECLARE v_start DATETIME;
  DECLARE v_end DATETIME;
  DECLARE v_created DATETIME;
  DECLARE v_lead INT;
  DECLARE v_duration INT;
  DECLARE v_is_weekend TINYINT DEFAULT 0;
  DECLARE v_cust_ins_rate DECIMAL(6,4) DEFAULT 0;
  DECLARE v_car_make VARCHAR(80);
  DECLARE v_car_model VARCHAR(80);
  DECLARE v_year YEAR;
  DECLARE v_car_premium TINYINT DEFAULT 0;
  DECLARE v_promo_code VARCHAR(20);
  DECLARE v_promo_applied TINYINT DEFAULT 0;
  DECLARE v_total_est DECIMAL(10,2) DEFAULT 0;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = 1;

  SELECT cust_id, start_datetime, end_datetime, created_at, promo_code, car_make, car_model, year, total_amount
    INTO v_cust, v_start, v_end, v_created, v_promo_code, v_car_make, v_car_model, v_year, v_total_est
  FROM Booking
  WHERE booking_id = p_booking_id
  LIMIT 1;

  IF v_not_found = 1 OR v_start IS NULL THEN
    LEAVE main_block;
  END IF;

  SET v_lead = GREATEST(0, DATEDIFF(v_start, v_created));
  SET v_duration = GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, v_start, v_end) / 24));
  SET v_is_weekend = IF(DAYOFWEEK(v_start) IN (1,7),1,0);

  SELECT COALESCE(SUM(CASE WHEN insurance_policy_id IS NOT NULL THEN 1 ELSE 0 END)/GREATEST(COUNT(*),1),0)
    INTO v_cust_ins_rate
    FROM Booking
    WHERE cust_id = v_cust AND booking_id <> p_booking_id;

  SELECT CASE WHEN ct.daily_rate > (SELECT AVG(daily_rate) FROM CarType) THEN 1 ELSE 0 END
    INTO v_car_premium
    FROM CarType ct
    WHERE ct.car_make = v_car_make AND ct.car_model = v_car_model AND ct.year = v_year
    LIMIT 1;

  SET v_promo_applied = IF(v_promo_code IS NULL, 0, 1);
  SET v_total_est = COALESCE(v_total_est, 0);

  INSERT INTO ml_insurance_features (booking_id, cust_id, lead_days, duration_days, is_weekend_start, cust_past_insurance_rate, car_type_premium, promo_applied, total_estimate, created_at)
  VALUES (p_booking_id, v_cust, v_lead, v_duration, v_is_weekend, v_cust_ins_rate, COALESCE(v_car_premium,0), v_promo_applied, v_total_est, NOW())
  ON DUPLICATE KEY UPDATE
    lead_days = VALUES(lead_days),
    duration_days = VALUES(duration_days),
    is_weekend_start = VALUES(is_weekend_start),
    cust_past_insurance_rate = VALUES(cust_past_insurance_rate),
    car_type_premium = VALUES(car_type_premium),
    promo_applied = VALUES(promo_applied),
    total_estimate = VALUES(total_estimate),
    created_at = CURRENT_TIMESTAMP;
END$$

/* 4) Score insurance for a booking using stored raw coefficients (proc_score_insurance_for_booking) */
DROP PROCEDURE IF EXISTS proc_score_insurance_for_booking$$
CREATE PROCEDURE proc_score_insurance_for_booking (IN p_booking_id INT, OUT p_probability DOUBLE)
BEGIN
  DECLARE v_not_found INT DEFAULT 0;
  DECLARE v_lead INT DEFAULT 0;
  DECLARE v_duration INT DEFAULT 0;
  DECLARE v_is_weekend INT DEFAULT 0;
  DECLARE v_cust_ins_rate DOUBLE DEFAULT 0;
  DECLARE v_car_premium INT DEFAULT 0;
  DECLARE v_promo_applied INT DEFAULT 0;
  DECLARE v_total_est DOUBLE DEFAULT 0;
  DECLARE c_intercept DOUBLE DEFAULT 0;
  DECLARE c_lead DOUBLE DEFAULT 0;
  DECLARE c_duration DOUBLE DEFAULT 0;
  DECLARE c_weekend DOUBLE DEFAULT 0;
  DECLARE c_custins DOUBLE DEFAULT 0;
  DECLARE c_premium DOUBLE DEFAULT 0;
  DECLARE c_promo DOUBLE DEFAULT 0;
  DECLARE c_totalest DOUBLE DEFAULT 0;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = 1;

  -- Ensure features exist
  IF NOT EXISTS (SELECT 1 FROM ml_insurance_features WHERE booking_id = p_booking_id) THEN
    CALL proc_refresh_insurance_feature_for_booking(p_booking_id);
  END IF;

  SELECT lead_days, duration_days, is_weekend_start, cust_past_insurance_rate, car_type_premium, promo_applied, total_estimate
    INTO v_lead, v_duration, v_is_weekend, v_cust_ins_rate, v_car_premium, v_promo_applied, v_total_est
  FROM ml_insurance_features
  WHERE booking_id = p_booking_id
  LIMIT 1;

  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='__intercept__' LIMIT 1),0) INTO c_intercept;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='lead_days' LIMIT 1),0) INTO c_lead;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='duration_days' LIMIT 1),0) INTO c_duration;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='is_weekend_start' LIMIT 1),0) INTO c_weekend;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='cust_past_insurance_rate' LIMIT 1),0) INTO c_custins;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='car_type_premium' LIMIT 1),0) INTO c_premium;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='promo_applied' LIMIT 1),0) INTO c_promo;
  SELECT COALESCE((SELECT coefficient FROM insurance_model_coeffs WHERE feature_name='total_estimate' LIMIT 1),0) INTO c_totalest;

  SET @lin = c_intercept
    + c_lead * COALESCE(v_lead,0)
    + c_duration * COALESCE(v_duration,0)
    + c_weekend * COALESCE(v_is_weekend,0)
    + c_custins * COALESCE(v_cust_ins_rate,0)
    + c_premium * COALESCE(v_car_premium,0)
    + c_promo * COALESCE(v_promo_applied,0)
    + c_totalest * COALESCE(v_total_est,0);

  SET p_probability = 1.0 / (1.0 + EXP(-@lin));

  INSERT INTO insurance_predictions (booking_id, probability, scored_at)
  VALUES (p_booking_id, p_probability, NOW())
  ON DUPLICATE KEY UPDATE probability = VALUES(probability), scored_at = VALUES(scored_at);
END$$

/* 5) Bulk recompute all ML tables (customer features, ml_insurance_features) */
DROP PROCEDURE IF EXISTS proc_recompute_all_ml$$
CREATE PROCEDURE proc_recompute_all_ml()
BEGIN
  -- recompute booking-level features
  DELETE FROM ml_insurance_features;
  INSERT INTO ml_insurance_features (booking_id, cust_id, lead_days, duration_days, is_weekend_start, cust_past_insurance_rate, car_type_premium, promo_applied, total_estimate, created_at)
  SELECT b.booking_id, b.cust_id,
         GREATEST(0, DATEDIFF(b.start_datetime, b.created_at)),
         GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, b.start_datetime, b.end_datetime)/24)),
         IF(DAYOFWEEK(b.start_datetime) IN (1,7),1,0),
         COALESCE((SELECT SUM(CASE WHEN bx.insurance_policy_id IS NOT NULL THEN 1 ELSE 0 END)/GREATEST(COUNT(*),1) FROM Booking bx WHERE bx.cust_id = b.cust_id AND bx.booking_id <> b.booking_id),0),
         IF((SELECT ct.daily_rate FROM CarType ct WHERE ct.car_make = b.car_make AND ct.car_model = b.car_model AND ct.year = b.year) > (SELECT AVG(daily_rate) FROM CarType),1,0),
         IF(b.promo_code IS NULL,0,1),
         COALESCE(b.total_amount,0),
         NOW()
  FROM Booking b;

  -- recompute customer aggregates
  CALL proc_update_customer_features_all();
END$$

/* 6) Trigger: after update of insurance_model_coeffs -> rescore recent bookings (light touch) */
DROP TRIGGER IF EXISTS trg_after_update_coeffs$$
CREATE TRIGGER trg_after_update_coeffs AFTER UPDATE ON insurance_model_coeffs
FOR EACH ROW
BEGIN
  -- naive: rescore top 50 recent bookings (keeps UI up-to-date)
  CALL proc_score_insurance_for_booking((SELECT booking_id FROM Booking ORDER BY created_at DESC LIMIT 1), @p_dummy);
END$$

DELIMITER ;
-- 8) Optional daily event: rebuild customer_features (if event scheduler is enabled)
-- DROP EVENT IF EXISTS evt_daily_customer_features;
-- DELIMITER $$
-- CREATE EVENT evt_daily_customer_features
-- ON SCHEDULE EVERY 1 DAY
-- DO
--   CALL proc_update_customer_features_all();
-- $$
-- DELIMITER ;
