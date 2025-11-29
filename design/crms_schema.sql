DROP DATABASE IF EXISTS rentawheel_db;
CREATE DATABASE rentawheel_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE rentawheel_db;

-- Branch
CREATE TABLE Branch (
  branch_id INT AUTO_INCREMENT PRIMARY KEY,
  branch_name VARCHAR(120) NOT NULL,
  street VARCHAR(150) NOT NULL,
  city VARCHAR(80) NOT NULL,
  state VARCHAR(80) NOT NULL,
  zip_code VARCHAR(20) NOT NULL,
  phone_number VARCHAR(40) UNIQUE NOT NULL,
  UNIQUE (street, city, state, zip_code)
);

-- Employee
CREATE TABLE Employee (
  emp_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  job_role VARCHAR(60) NOT NULL,
  email VARCHAR(120) UNIQUE NOT NULL,
  branch_id INT NOT NULL,
  hired_on DATE DEFAULT NULL,
  FOREIGN KEY (branch_id) REFERENCES Branch(branch_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CarType
CREATE TABLE CarType (
  car_make VARCHAR(80) NOT NULL,
  car_model VARCHAR(80) NOT NULL,
  year YEAR NOT NULL,
  category VARCHAR(80)  NOT NULL,
  daily_rate DECIMAL(9,2) NOT NULL DEFAULT 12.00,
  PRIMARY KEY (car_make, car_model, year)
);

-- Car
CREATE TABLE Car (
  car_id INT AUTO_INCREMENT PRIMARY KEY,
  license_plate VARCHAR(40) NOT NULL UNIQUE,
  mileage INT DEFAULT 0,
  status ENUM('Available','Booked','Maintenance','Retired') NOT NULL DEFAULT 'Available',
  car_make VARCHAR(80) NOT NULL,
  car_model VARCHAR(80) NOT NULL,
  year YEAR NOT NULL,
  branch_id INT NOT NULL,
  FOREIGN KEY (car_make, car_model, year) REFERENCES CarType(car_make, car_model, year) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (branch_id) REFERENCES Branch(branch_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Customer (user signs up here)
CREATE TABLE Customer (
  cust_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(64) NOT NULL,
  last_name VARCHAR(64) NOT NULL,
  dob DATE NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  contact_no VARCHAR(40) NOT NULL UNIQUE,
  license_no VARCHAR(60) NOT NULL UNIQUE
);
-- customer address (1..* table)
CREATE TABLE customer_address(
	cust_id INT PRIMARY KEY,
    street VARCHAR(150) NOT NULL,
    city VARCHAR(80) NOT NULL,
	state VARCHAR(80) NOT NULL,
	zip_code VARCHAR(20) NOT NULL,
    UNIQUE(street,city,state,zip_code),
    FOREIGN KEY (cust_id) REFERENCES customer(cust_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Insurance
CREATE TABLE Insurance (
  policy_id INT AUTO_INCREMENT PRIMARY KEY,
  package_name VARCHAR(120) NOT NULL,
  daily_cost DECIMAL(9,2) NOT NULL DEFAULT 5.00,
  coverage_details TEXT NOT NULL
);

-- Promotion
CREATE TABLE Promotion (
  promo_code VARCHAR(20) PRIMARY KEY,
  discount_perc DECIMAL(5,2) NOT NULL CHECK (discount_perc >= 0 AND discount_perc <= 100),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  CHECK (start_date <= end_date)
);

-- Booking
CREATE TABLE Booking (
  booking_id INT AUTO_INCREMENT PRIMARY KEY,
  cust_id INT NOT NULL,
  car_id INT NULL, -- assigned when confirmed; each booking is associated with exactly one car (we allow assignment later)
  car_make VARCHAR(80) NOT NULL,
  car_model VARCHAR(80) NOT NULL,
  year YEAR NOT NULL,
  pickup_branch_id INT NOT NULL,
  dropoff_branch_id INT NOT NULL,
  insurance_policy_id INT NULL,
  promo_code VARCHAR(20) NULL,
  start_datetime DATETIME NOT NULL,
  end_datetime DATETIME NOT NULL,
  total_amount DECIMAL(12,2) DEFAULT 0.00,
  status ENUM('Booked','Confirmed','Ongoing','Completed','Cancelled') NOT NULL DEFAULT 'Booked',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (cust_id) REFERENCES Customer(cust_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (car_id) REFERENCES Car(car_id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (car_make, car_model, year) REFERENCES CarType(car_make, car_model, year) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (pickup_branch_id) REFERENCES Branch(branch_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (dropoff_branch_id) REFERENCES Branch(branch_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (insurance_policy_id) REFERENCES Insurance(policy_id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (promo_code) REFERENCES Promotion(promo_code) ON DELETE SET NULL ON UPDATE CASCADE,
  CHECK (start_datetime < end_datetime)
);

-- Payment
CREATE TABLE Payment (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  booking_id INT NOT NULL,
  payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  amount DECIMAL(12,2) NOT NULL,
  payment_mode ENUM('card','cash','wallet','online') NOT NULL,
  payment_status ENUM('Successful','Failed','Pending') NOT NULL DEFAULT 'Pending',
  transaction_ref VARCHAR(150) NOT NULL,
  FOREIGN KEY (booking_id) REFERENCES Booking(booking_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Feedback
CREATE TABLE Feedback (
  feedback_id INT AUTO_INCREMENT PRIMARY KEY,
  cust_id INT NOT NULL,
  booking_id INT NOT NULL,
  rating TINYINT UNSIGNED CHECK (rating >=1 AND rating <=5),
  comment TEXT,
  submission_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (cust_id) REFERENCES customer(cust_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (booking_id) REFERENCES Booking(booking_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- MaintenanceLogs
CREATE TABLE MaintenanceLogs (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  car_id INT NOT NULL,
  logged_by_emp_id INT NULL,
  date_in DATETIME NOT NULL,
  date_out DATETIME NULL,
  description TEXT,
  cost DECIMAL(10,2) DEFAULT 0.00,
  FOREIGN KEY (car_id) REFERENCES Car(car_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (logged_by_emp_id) REFERENCES Employee(emp_id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- --------------------------
-- ML SUPPORT TABLES (minimal, only what is required)
-- --------------------------

-- aggregated customer features (KMeans)
CREATE TABLE customer_features (
  cust_id INT PRIMARY KEY,
  total_bookings INT NOT NULL DEFAULT 0,
  avg_rental_days DECIMAL(6,2) NOT NULL DEFAULT 0,
  avg_spend DECIMAL(10,2) NOT NULL DEFAULT 0,
  insurance_accept_rate DECIMAL(6,4) NOT NULL DEFAULT 0,
  cancel_rate DECIMAL(6,4) NOT NULL DEFAULT 0,
  last_booking_date DATETIME NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (cust_id) REFERENCES Customer(cust_id) ON DELETE CASCADE
);

-- kmeans result
CREATE TABLE customer_clusters (
  cust_id INT PRIMARY KEY,
  cluster_id INT NOT NULL,
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (cust_id) REFERENCES Customer(cust_id) ON DELETE CASCADE
);

-- booking-level features for insurance model
CREATE TABLE ml_insurance_features (
  booking_id INT PRIMARY KEY,
  cust_id INT NOT NULL,
  lead_days INT NOT NULL,
  duration_days INT NOT NULL,
  is_weekend_start TINYINT(1) NOT NULL DEFAULT 0,
  cust_past_insurance_rate DECIMAL(6,4) NOT NULL DEFAULT 0,
  car_type_premium TINYINT(1) NOT NULL DEFAULT 0,
  promo_applied TINYINT(1) NOT NULL DEFAULT 0,
  total_estimate DECIMAL(10,2) NOT NULL DEFAULT 0,
  label_insurance_selected TINYINT(1) NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES Booking(booking_id) ON DELETE CASCADE,
  FOREIGN KEY (cust_id) REFERENCES Customer(cust_id) ON DELETE CASCADE
);

-- logistic regression raw coefficients (feature_name -> coefficient)
CREATE TABLE insurance_model_coeffs (
  feature_name VARCHAR(80) PRIMARY KEY,
  coefficient DOUBLE NOT NULL,
  last_trained_at TIMESTAMP NULL
);

-- cache predictions for booking insurance probability
CREATE TABLE insurance_predictions (
  booking_id INT PRIMARY KEY,
  probability DOUBLE NOT NULL,
  scored_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES Booking(booking_id) ON DELETE CASCADE
);

-- initialize coefficients with zeros (intercept + feature names expected by the Python trainer)
INSERT INTO insurance_model_coeffs (feature_name, coefficient)
VALUES
('__intercept__', 0.0),
('lead_days', 0.0),
('duration_days', 0.0),
('is_weekend_start', 0.0),
('cust_past_insurance_rate', 0.0),
('car_type_premium', 0.0),
('promo_applied', 0.0),
('total_estimate', 0.0)
ON DUPLICATE KEY UPDATE coefficient = VALUES(coefficient);

-- CAR TYPES
INSERT INTO CarType (car_make, car_model, year, category, daily_rate) VALUES
('Toyota','Camry',2021,'Sedan',45.00),
('Toyota','Corolla',2020,'Sedan',38.00),
('Honda','Civic',2021,'Sedan',42.00),
('Honda','CR-V',2020,'SUV',60.00),
('Ford','Escape',2019,'SUV',55.00),
('Ford','Transit',2019,'Van',85.00),
('Chevrolet','Malibu',2019,'Sedan',40.00),
('Nissan','Rogue',2022,'SUV',62.00);

-- BRANCHES
INSERT INTO Branch (branch_name, street, city, state, zip_code, phone_number) VALUES
('Downtown','10 Market St','Boston','MA','02108','617-000-1111'),
('Logan Airport','1 Airport Rd','Boston','MA','02128','617-000-2222'),
('Cambridge','100 Cambridge St','Cambridge','MA','02139','617-000-3333'),
('Somerville','50 Central St','Somerville','MA','02143','617-000-4444');

-- EMPLOYEES
INSERT INTO Employee (first_name, last_name, job_role, email, branch_id, hired_on) VALUES
('Alice','Wong','Manager','alice.w@rentawheel.com',1,'2021-04-01'),
('Bob','Garcia','Agent','bob.g@rentawheel.com',1,'2022-01-10'),
('Carlos','Perez','Mechanic','carlos.p@rentawheel.com',2,'2020-07-20'),
('Dana','Lee','Agent','dana.l@rentawheel.com',3,'2023-02-15'),
('Evan','Smith','Shift Lead','evan.s@rentawheel.com',4,'2022-05-12'),
('Fiona','Ng','Mechanic','fiona.n@rentawheel.com',1,'2019-09-01');

-- CARS
INSERT INTO Car (license_plate, mileage, status, car_make, car_model, year, branch_id) VALUES
('BOS-1001',15000,'Available','Toyota','Camry',2021,1),
('BOS-1002',22000,'Available','Toyota','Camry',2021,1),
('BOS-1003',8000,'Available','Toyota','Corolla',2020,1),
('BOS-2001',12000,'Available','Honda','CR-V',2020,2),
('BOS-2002',18000,'Available','Honda','Civic',2021,2),
('BOS-3001',30000,'Maintenance','Ford','Transit',2019,1),
('BOS-3002',26000,'Available','Ford','Escape',2019,3),
('BOS-4001',9000,'Available','Nissan','Rogue',2022,4),
('BOS-4002',14000,'Available','Chevrolet','Malibu',2019,4),
('BOS-5001',5000,'Available','Honda','CR-V',2020,3);

-- INSURANCE
INSERT INTO Insurance (policy_id, package_name, daily_cost, coverage_details) VALUES
(1, 'Basic', 8.00, 'Collision up to $5k; deductible $500'),
(2, 'Standard', 15.00, 'Collision + Theft; roadside assistance'),
(3, 'Premium', 25.00, 'Collision+Theft+Full Glass+Roadside, deductible $0');

-- PROMOTIONS
INSERT INTO Promotion (promo_code, discount_perc, start_date, end_date) VALUES
('WELCOME10', 10.00, '2024-01-01', '2026-12-31'),
('WEEKEND15', 15.00, '2025-01-01', '2026-12-31'),
('HOLIDAY20', 20.00, '2025-12-20', '2026-01-10');

-- CUSTOMERS
INSERT INTO Customer (cust_id, first_name, last_name, dob, email, contact_no, license_no) VALUES
(1,'John','Doe','1990-03-22','john.doe@example.com','617-111-0001','DLB1001'),
(2,'Jane','Roe','1988-07-05','jane.roe@example.com','617-111-0002','DLB1002'),
(3,'Sam','Adams','1985-04-12','sam.adams@example.com','617-111-0003','DLB1003');

INSERT INTO customer_address (cust_id, street, city, state, zip_code) VALUES
(1,'24 Elm St','Boston','MA','02110'),
(2,'46 Oak Ave','Boston','MA','02111'),
(3,'10 Beacon St','Boston','MA','02108');

-- BOOKINGS
INSERT INTO Booking (booking_id, cust_id, car_id, car_make, car_model, year, pickup_branch_id, dropoff_branch_id, insurance_policy_id, promo_code, start_datetime, end_datetime, total_amount, status, created_at)
VALUES
(1,1,1,'Toyota','Camry',2021,1,1,1,'WELCOME10','2025-11-25 10:00:00','2025-11-27 10:00:00',100.00,'Completed','2025-11-20 09:00:00'),
(2,2,NULL,'Honda','CR-V',2020,2,1,NULL,NULL,'2025-11-28 09:00:00','2025-11-30 09:00:00',150.00,'Booked','2025-11-24 09:00:00'),
(3,3,NULL,'Toyota','Camry',2021,1,1,2,NULL,'2025-12-02 12:00:00','2025-12-04 12:00:00',90.00,'Booked','2025-11-26 08:00:00');

-- PAYMENTS
INSERT INTO Payment (payment_id, booking_id, amount, payment_date, payment_mode, payment_status, transaction_ref) VALUES
(1,1,100.00,'2025-11-20 09:05:00','card','Successful','TXN1001');

-- FEEDBACK
INSERT INTO Feedback (feedback_id, cust_id, booking_id, rating, comment, submission_date) VALUES
(1,1,1,5,'Great service!','2025-11-27 12:00:00');

-- MAINTENANCE
INSERT INTO MaintenanceLogs (log_id, car_id, logged_by_emp_id, date_in, date_out, description, cost) VALUES
(1,3,3,'2025-11-01 08:00:00','2025-11-05 17:00:00','Transmission repair',1200.00);

-- ------------------------
-- INITIAL ML TABLE POPULATION
-- ------------------------

-- 1) Fill customer_features by aggregating bookings for each customer (simple initial population)
INSERT INTO customer_features (cust_id, total_bookings, avg_rental_days, avg_spend, insurance_accept_rate, cancel_rate, last_booking_date)
SELECT c.cust_id,
       COUNT(b.booking_id) AS total_bookings,
       COALESCE(AVG(CEIL(TIMESTAMPDIFF(HOUR, b.start_datetime, b.end_datetime)/24)), 0) AS avg_rental_days,
       COALESCE(AVG(b.total_amount), 0) AS avg_spend,
       COALESCE(SUM(CASE WHEN b.insurance_policy_id IS NOT NULL THEN 1 ELSE 0 END) / GREATEST(COUNT(b.booking_id),1), 0) AS insurance_accept_rate,
       COALESCE(SUM(CASE WHEN b.status = 'Cancelled' THEN 1 ELSE 0 END) / GREATEST(COUNT(b.booking_id),1), 0) AS cancel_rate,
       MAX(b.start_datetime) AS last_booking_date
FROM Customer c
LEFT JOIN Booking b ON b.cust_id = c.cust_id
GROUP BY c.cust_id
ON DUPLICATE KEY UPDATE
  total_bookings = VALUES(total_bookings),
  avg_rental_days = VALUES(avg_rental_days),
  avg_spend = VALUES(avg_spend),
  insurance_accept_rate = VALUES(insurance_accept_rate),
  cancel_rate = VALUES(cancel_rate),
  last_booking_date = VALUES(last_booking_date),
  updated_at = CURRENT_TIMESTAMP;

-- 2) Create placeholder customer_clusters rows (will be overwritten after KMeans train)
INSERT INTO customer_clusters (cust_id, cluster_id)
SELECT cust_id, 0 FROM Customer
ON DUPLICATE KEY UPDATE cluster_id = VALUES(cluster_id), assigned_at = CURRENT_TIMESTAMP;

-- 3) Create ml_insurance_features rows for existing bookings
INSERT INTO ml_insurance_features (booking_id, cust_id, lead_days, duration_days, is_weekend_start, cust_past_insurance_rate, car_type_premium, promo_applied, total_estimate, created_at)
SELECT b.booking_id,
       b.cust_id,
       GREATEST(0, DATEDIFF(b.start_datetime, b.created_at)) AS lead_days,
       GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, b.start_datetime, b.end_datetime)/24)) AS duration_days,
       IF(DAYOFWEEK(b.start_datetime) IN (1,7), 1, 0) AS is_weekend_start,
       COALESCE( (SELECT SUM(CASE WHEN bx.insurance_policy_id IS NOT NULL THEN 1 ELSE 0 END)/GREATEST(COUNT(*),1) FROM Booking bx WHERE bx.cust_id = b.cust_id AND bx.booking_id <> b.booking_id), 0) AS cust_past_insurance_rate,
       -- car_type_premium: compare this CarType.daily_rate to average daily_rate across CarType
       IF( (SELECT ct.daily_rate FROM CarType ct WHERE ct.car_make = b.car_make AND ct.car_model = b.car_model AND ct.year = b.year) > (SELECT AVG(daily_rate) FROM CarType), 1, 0) AS car_type_premium,
       IF(b.promo_code IS NULL, 0, 1) AS promo_applied,
       COALESCE(b.total_amount, 0) AS total_estimate,
       NOW()
FROM Booking b
ON DUPLICATE KEY UPDATE
  lead_days = VALUES(lead_days),
  duration_days = VALUES(duration_days),
  is_weekend_start = VALUES(is_weekend_start),
  cust_past_insurance_rate = VALUES(cust_past_insurance_rate),
  car_type_premium = VALUES(car_type_premium),
  promo_applied = VALUES(promo_applied),
  total_estimate = VALUES(total_estimate),
  created_at = CURRENT_TIMESTAMP;