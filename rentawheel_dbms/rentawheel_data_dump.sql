DROP DATABASE IF EXISTS `rentawheel_db`;
CREATE DATABASE  IF NOT EXISTS `rentawheel_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `rentawheel_db`;
-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: rentawheel_db
-- ------------------------------------------------------
-- Server version	9.4.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `booking`
--

DROP TABLE IF EXISTS `booking`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `booking` (
  `booking_id` int NOT NULL AUTO_INCREMENT,
  `cust_id` int NOT NULL,
  `car_id` int DEFAULT NULL,
  `car_make` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `car_model` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `year` year NOT NULL,
  `pickup_branch_id` int NOT NULL,
  `dropoff_branch_id` int NOT NULL,
  `insurance_policy_id` int DEFAULT NULL,
  `promo_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `start_datetime` datetime NOT NULL,
  `end_datetime` datetime NOT NULL,
  `total_amount` decimal(12,2) DEFAULT '0.00',
  `status` enum('Confirmed','Completed','Cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Confirmed',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`booking_id`),
  KEY `cust_id` (`cust_id`),
  KEY `car_id` (`car_id`),
  KEY `car_make` (`car_make`,`car_model`,`year`),
  KEY `pickup_branch_id` (`pickup_branch_id`),
  KEY `dropoff_branch_id` (`dropoff_branch_id`),
  KEY `insurance_policy_id` (`insurance_policy_id`),
  KEY `promo_code` (`promo_code`),
  CONSTRAINT `booking_ibfk_1` FOREIGN KEY (`cust_id`) REFERENCES `customer` (`cust_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `booking_ibfk_2` FOREIGN KEY (`car_id`) REFERENCES `car` (`car_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `booking_ibfk_3` FOREIGN KEY (`car_make`, `car_model`, `year`) REFERENCES `cartype` (`car_make`, `car_model`, `year`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `booking_ibfk_4` FOREIGN KEY (`pickup_branch_id`) REFERENCES `branch` (`branch_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `booking_ibfk_5` FOREIGN KEY (`dropoff_branch_id`) REFERENCES `branch` (`branch_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `booking_ibfk_6` FOREIGN KEY (`insurance_policy_id`) REFERENCES `insurance` (`policy_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `booking_ibfk_7` FOREIGN KEY (`promo_code`) REFERENCES `promotion` (`promo_code`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `booking_chk_1` CHECK ((`start_datetime` < `end_datetime`))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `booking`
--

LOCK TABLES `booking` WRITE;
/*!40000 ALTER TABLE `booking` DISABLE KEYS */;
INSERT INTO `booking` VALUES (1,1,1,'Toyota','Camry',2021,1,1,1,'WELCOME10','2025-11-25 10:00:00','2025-11-27 10:00:00',100.00,'Completed','2025-11-20 14:00:00'),(2,2,NULL,'Honda','CR-V',2020,2,1,3,NULL,'2025-11-28 09:00:00','2025-11-30 09:00:00',150.00,'Confirmed','2025-11-24 14:00:00'),(3,3,NULL,'Toyota','Camry',2021,1,1,2,NULL,'2025-12-02 12:00:00','2025-12-04 12:00:00',90.00,'Confirmed','2025-11-26 13:00:00');
/*!40000 ALTER TABLE `booking` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_after_insert_booking` AFTER INSERT ON `booking` FOR EACH ROW BEGIN
  CALL proc_update_customer_features_for_customer(NEW.cust_id);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_after_update_booking` AFTER UPDATE ON `booking` FOR EACH ROW BEGIN
  CALL proc_update_customer_features_for_customer(NEW.cust_id);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_after_delete_booking` AFTER DELETE ON `booking` FOR EACH ROW BEGIN
  CALL proc_update_customer_features_for_customer(OLD.cust_id);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `branch`
--

DROP TABLE IF EXISTS `branch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `branch` (
  `branch_id` int NOT NULL AUTO_INCREMENT,
  `branch_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `street` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `city` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `state` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `zip_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone_number` varchar(14) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`branch_id`),
  UNIQUE KEY `branch_name` (`branch_name`),
  UNIQUE KEY `phone_number` (`phone_number`),
  UNIQUE KEY `street` (`street`,`city`,`state`,`zip_code`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `branch`
--

LOCK TABLES `branch` WRITE;
/*!40000 ALTER TABLE `branch` DISABLE KEYS */;
INSERT INTO `branch` VALUES (1,'Downtown','10 Market St','Boston','MA','02108','617-000-1111'),(2,'Logan Airport','1 Airport Rd','Boston','MA','02128','617-000-2222'),(3,'Cambridge','100 Cambridge St','Cambridge','MA','02139','617-000-3333'),(4,'Somerville','50 Central St','Somerville','MA','02143','617-000-4444');
/*!40000 ALTER TABLE `branch` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `car`
--

DROP TABLE IF EXISTS `car`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `car` (
  `car_id` int NOT NULL AUTO_INCREMENT,
  `license_plate` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mileage` int DEFAULT '0',
  `status` enum('Available','Booked','Maintenance','Retired') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Available',
  `car_make` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `car_model` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `year` year NOT NULL,
  `branch_id` int NOT NULL,
  PRIMARY KEY (`car_id`),
  UNIQUE KEY `license_plate` (`license_plate`),
  KEY `car_make` (`car_make`,`car_model`,`year`),
  KEY `branch_id` (`branch_id`),
  CONSTRAINT `car_ibfk_1` FOREIGN KEY (`car_make`, `car_model`, `year`) REFERENCES `cartype` (`car_make`, `car_model`, `year`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `car_ibfk_2` FOREIGN KEY (`branch_id`) REFERENCES `branch` (`branch_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `car`
--

LOCK TABLES `car` WRITE;
/*!40000 ALTER TABLE `car` DISABLE KEYS */;
INSERT INTO `car` VALUES (1,'BOS-1001',15000,'Available','Toyota','Camry',2021,1),(2,'BOS-1002',22000,'Available','Toyota','Camry',2021,1),(3,'BOS-1003',8000,'Available','Toyota','Corolla',2020,1),(4,'BOS-2001',12000,'Available','Honda','CR-V',2020,2),(5,'BOS-2002',18000,'Available','Honda','Civic',2021,2),(6,'BOS-3001',30000,'Maintenance','Ford','Transit',2019,1),(7,'BOS-3002',26000,'Available','Ford','Escape',2019,3),(8,'BOS-4001',9000,'Available','Nissan','Rogue',2022,4),(9,'BOS-4002',14000,'Available','Chevrolet','Malibu',2019,4),(10,'BOS-5001',5000,'Available','Honda','CR-V',2020,3);
/*!40000 ALTER TABLE `car` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cartype`
--

DROP TABLE IF EXISTS `cartype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cartype` (
  `car_make` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `car_model` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `year` year NOT NULL,
  `category` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `daily_rate` decimal(9,2) NOT NULL DEFAULT '12.00',
  PRIMARY KEY (`car_make`,`car_model`,`year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cartype`
--

LOCK TABLES `cartype` WRITE;
/*!40000 ALTER TABLE `cartype` DISABLE KEYS */;
INSERT INTO `cartype` VALUES ('Chevrolet','Malibu',2019,'Sedan',40.00),('Ford','Escape',2019,'SUV',55.00),('Ford','Transit',2019,'Van',85.00),('Honda','Civic',2021,'Sedan',42.00),('Honda','CR-V',2020,'SUV',60.00),('Nissan','Rogue',2022,'SUV',62.00),('Toyota','Camry',2021,'Sedan',45.00),('Toyota','Corolla',2020,'Sedan',38.00);
/*!40000 ALTER TABLE `cartype` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customer`
--

DROP TABLE IF EXISTS `customer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customer` (
  `cust_id` int NOT NULL AUTO_INCREMENT,
  `first_name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dob` date NOT NULL,
  `email` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_no` varchar(14) COLLATE utf8mb4_unicode_ci NOT NULL,
  `license_no` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`cust_id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `contact_no` (`contact_no`),
  UNIQUE KEY `license_no` (`license_no`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer`
--

LOCK TABLES `customer` WRITE;
/*!40000 ALTER TABLE `customer` DISABLE KEYS */;
INSERT INTO `customer` VALUES (1,'John','Doe','1990-03-22','john.doe@example.com','6171110001','DLB1001'),(2,'Jane','Roe','1988-07-05','jane.roe@example.com','6171110002','DLB1002'),(3,'Sam','Adams','1985-04-12','sam.adams@example.com','6171110003','DLB1003');
/*!40000 ALTER TABLE `customer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customer_clusters`
--

DROP TABLE IF EXISTS `customer_clusters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customer_clusters` (
  `cust_id` int NOT NULL,
  `cluster_id` int NOT NULL,
  `assigned_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cust_id`),
  CONSTRAINT `customer_clusters_ibfk_1` FOREIGN KEY (`cust_id`) REFERENCES `customer` (`cust_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer_clusters`
--

LOCK TABLES `customer_clusters` WRITE;
/*!40000 ALTER TABLE `customer_clusters` DISABLE KEYS */;
INSERT INTO `customer_clusters` VALUES (1,0,'2025-12-05 05:17:57'),(2,0,'2025-12-05 05:17:57'),(3,0,'2025-12-05 05:17:57');
/*!40000 ALTER TABLE `customer_clusters` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customer_features`
--

DROP TABLE IF EXISTS `customer_features`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customer_features` (
  `cust_id` int NOT NULL,
  `total_bookings` int NOT NULL DEFAULT '0',
  `avg_rental_days` decimal(6,2) NOT NULL DEFAULT '0.00',
  `avg_spend` decimal(10,2) NOT NULL DEFAULT '0.00',
  `insurance_accept_rate` decimal(6,4) NOT NULL DEFAULT '0.0000',
  `cancel_rate` decimal(6,4) NOT NULL DEFAULT '0.0000',
  `last_booking_date` datetime DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`cust_id`),
  CONSTRAINT `customer_features_ibfk_1` FOREIGN KEY (`cust_id`) REFERENCES `customer` (`cust_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customer_features`
--

LOCK TABLES `customer_features` WRITE;
/*!40000 ALTER TABLE `customer_features` DISABLE KEYS */;
INSERT INTO `customer_features` VALUES (1,1,2.00,100.00,1.0000,0.0000,'2025-11-25 10:00:00','2025-12-05 05:17:57'),(2,1,2.00,150.00,1.0000,0.0000,'2025-11-28 09:00:00','2025-12-05 05:17:57'),(3,1,2.00,90.00,1.0000,0.0000,'2025-12-02 12:00:00','2025-12-05 05:17:57');
/*!40000 ALTER TABLE `customer_features` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `employee`
--

DROP TABLE IF EXISTS `employee`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee` (
  `emp_id` int NOT NULL AUTO_INCREMENT,
  `first_name` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `job_role` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `branch_id` int NOT NULL,
  `hired_on` date DEFAULT NULL,
  PRIMARY KEY (`emp_id`),
  UNIQUE KEY `email` (`email`),
  KEY `branch_id` (`branch_id`),
  CONSTRAINT `employee_ibfk_1` FOREIGN KEY (`branch_id`) REFERENCES `branch` (`branch_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `employee`
--

LOCK TABLES `employee` WRITE;
/*!40000 ALTER TABLE `employee` DISABLE KEYS */;
INSERT INTO `employee` VALUES (1,'Alice','Wong','Manager','alice.w@rentawheel.com',1,'2021-04-01'),(2,'Bob','Garcia','Mechanic','bob.g@rentawheel.com',1,'2022-01-10'),(3,'Carlos','Perez','Mechanic','carlos.p@rentawheel.com',2,'2020-07-20'),(4,'Dana','Lee','Mechanic','dana.l@rentawheel.com',3,'2023-02-15'),(5,'Evan','Smith','Manager','evan.s@rentawheel.com',4,'2022-05-12'),(6,'Fiona','Ng','Shift Lead','fiona.n@rentawheel.com',1,'2019-09-01');
/*!40000 ALTER TABLE `employee` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `feedback`
--

DROP TABLE IF EXISTS `feedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `feedback` (
  `feedback_id` int NOT NULL AUTO_INCREMENT,
  `cust_id` int NOT NULL,
  `booking_id` int NOT NULL,
  `rating` tinyint unsigned DEFAULT NULL,
  `comment` text COLLATE utf8mb4_unicode_ci,
  `submission_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`feedback_id`),
  UNIQUE KEY `booking_id` (`booking_id`),
  KEY `cust_id` (`cust_id`),
  CONSTRAINT `feedback_ibfk_1` FOREIGN KEY (`cust_id`) REFERENCES `customer` (`cust_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `feedback_ibfk_2` FOREIGN KEY (`booking_id`) REFERENCES `booking` (`booking_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `feedback_chk_1` CHECK (((`rating` >= 1) and (`rating` <= 5)))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `feedback`
--

LOCK TABLES `feedback` WRITE;
/*!40000 ALTER TABLE `feedback` DISABLE KEYS */;
INSERT INTO `feedback` VALUES (1,1,1,5,'Great service!','2025-11-27 12:00:00');
/*!40000 ALTER TABLE `feedback` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `insurance`
--

DROP TABLE IF EXISTS `insurance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `insurance` (
  `policy_id` int NOT NULL AUTO_INCREMENT,
  `package_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `daily_cost` decimal(9,2) NOT NULL DEFAULT '8.00',
  `coverage_details` text COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`policy_id`),
  UNIQUE KEY `package_name` (`package_name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `insurance`
--

LOCK TABLES `insurance` WRITE;
/*!40000 ALTER TABLE `insurance` DISABLE KEYS */;
INSERT INTO `insurance` VALUES (1,'Basic',8.00,'Collision up to $5k; deductible $500'),(2,'Standard',15.00,'Collision + Theft; roadside assistance'),(3,'Premium',25.00,'Collision+Theft+Full Glass+Roadside, deductible $0');
/*!40000 ALTER TABLE `insurance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `maintenancelogs`
--

DROP TABLE IF EXISTS `maintenancelogs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `maintenancelogs` (
  `log_id` int NOT NULL AUTO_INCREMENT,
  `car_id` int NOT NULL,
  `logged_by_emp_id` int DEFAULT NULL,
  `date_in` datetime NOT NULL,
  `date_out` datetime DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `cost` decimal(10,2) DEFAULT '0.00',
  PRIMARY KEY (`log_id`),
  KEY `car_id` (`car_id`),
  KEY `logged_by_emp_id` (`logged_by_emp_id`),
  CONSTRAINT `maintenancelogs_ibfk_1` FOREIGN KEY (`car_id`) REFERENCES `car` (`car_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `maintenancelogs_ibfk_2` FOREIGN KEY (`logged_by_emp_id`) REFERENCES `employee` (`emp_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `maintenancelogs`
--

LOCK TABLES `maintenancelogs` WRITE;
/*!40000 ALTER TABLE `maintenancelogs` DISABLE KEYS */;
INSERT INTO `maintenancelogs` VALUES (1,3,3,'2025-11-01 08:00:00','2025-11-05 17:00:00','Transmission repair',1200.00);
/*!40000 ALTER TABLE `maintenancelogs` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_after_insert_maintenance` AFTER INSERT ON `maintenancelogs` FOR EACH ROW BEGIN
  UPDATE Car SET status = 'Maintenance' WHERE car_id = NEW.car_id;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `payment`
--

DROP TABLE IF EXISTS `payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment` (
  `payment_id` int NOT NULL AUTO_INCREMENT,
  `booking_id` int NOT NULL,
  `payment_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `amount` decimal(12,2) NOT NULL,
  `payment_mode` enum('card','cash','wallet','online') COLLATE utf8mb4_unicode_ci NOT NULL,
  `payment_status` enum('Successful','Failed','Pending') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending',
  `transaction_ref` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`payment_id`),
  UNIQUE KEY `transaction_ref` (`transaction_ref`),
  KEY `booking_id` (`booking_id`),
  CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `booking` (`booking_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payment`
--

LOCK TABLES `payment` WRITE;
/*!40000 ALTER TABLE `payment` DISABLE KEYS */;
INSERT INTO `payment` VALUES (1,1,'2025-11-20 09:05:00',100.00,'card','Successful','TXN1001');
/*!40000 ALTER TABLE `payment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `promotion`
--

DROP TABLE IF EXISTS `promotion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promotion` (
  `promo_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `discount_perc` decimal(5,2) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  PRIMARY KEY (`promo_code`),
  CONSTRAINT `promotion_chk_1` CHECK (((`discount_perc` >= 0) and (`discount_perc` <= 100))),
  CONSTRAINT `promotion_chk_2` CHECK ((`start_date` <= `end_date`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `promotion`
--

LOCK TABLES `promotion` WRITE;
/*!40000 ALTER TABLE `promotion` DISABLE KEYS */;
INSERT INTO `promotion` VALUES ('HOLIDAY20',20.00,'2025-12-20','2026-01-10'),('WEEKEND15',15.00,'2025-01-01','2026-12-31'),('WELCOME10',10.00,'2024-01-01','2026-12-31');
/*!40000 ALTER TABLE `promotion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'rentawheel_db'
--

--
-- Dumping routines for database 'rentawheel_db'
--
/*!50003 DROP FUNCTION IF EXISTS `fn_is_car_available` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_is_car_available`(p_car_id INT, p_start DATETIME, p_end DATETIME) RETURNS tinyint
    DETERMINISTIC
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `proc_add_feedback` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_add_feedback`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `proc_add_maintenance_log` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_add_maintenance_log`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `proc_assign_car_to_booking` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_assign_car_to_booking`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `proc_cancel_booking` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_cancel_booking`(IN p_booking_id INT)
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

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `proc_create_booking` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_create_booking`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `proc_create_customer` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_create_customer`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `proc_create_payment` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_create_payment`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `proc_update_booking` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_update_booking`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `proc_update_customer_features_all` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_update_customer_features_all`()
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `proc_update_customer_features_for_customer` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_update_customer_features_for_customer`(IN p_cust_id INT)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-05  0:20:17
