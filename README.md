# Rent-A-Wheel - Car Rental System
### Modern DBMS application to manage hassle-free car rentals
---
## TOP LEVEL DESCRIPTION OF THE PROJECT
Rent-A-Wheel is a car rental platform that manages vehicle rentals across multiple branches. Branches employ multiple employees. Employees are responsible for various activities, currently role added for logging maintenance work on cars.

Cars in the fleet are uniquely identified by a car ID and have a license plate number, mileage, and current status. Every car belongs to one branch and is classified by a car type which details the make, model, year, category, and daily rental rate. Branches stock multiple cars, each linked to a specific car type.

Customers can register on the platform by providing personal details including name, date of birth, email, contact number, and driver's license number. Customers can search the cars available for various timings across different branch locations. They need to select desired car from given options and set the rental period. Once the selection is made, custome r proceeds to the payment screen for the calculated amount. Once it is done, the booking is confirmed and that car becomes unavailable to other customers.

A customer can make one booking at a time. The booking also references an insurance policy chosen by the customer, which has its package name, daily cost, and coverage details. Optionally, customers may apply a promotion code to avail discounts, which includes a discount percentage and validity period indicated by the start and end date of the promo code. A customer can apply at most one promo code per booking. After completing a rental, customers can provide feedback, including a rating, comments, and submission date. 

The application also supports an employee portal GUI which allows designated employees to log maintenance requests and provides an analytics dashboard for fleet management and tracking revenue from bookings.Maintenance activities are logged by employees along with their estimated cost and linked to the specific cars serviced.

##  Prerequisites
Make sure you have the following installed:
1.  **MySQL Server** (for the database)
2.  **Python 3.10+** (for the backend)
3.  **Node.js** (for the frontend)

---

##  Setup & Run Instructions

### 1. Database Setup
You have two options to set up the database:

**Option A :** Run the full Data Dump.
1.  Open your MySQL client.
2.  Run the **Data Dump** file (this contains everything):
    `rentawheel_dbms/rentawheel_data_dump.sql`

**Option B:** Run the Schema then the Procedures.
1.  Open your MySQL client.
2.  Run the **Schema** file first:
    `rentawheel_dbms/crms_schema.sql`
3.  Run the **Procedures & Triggers** file second:
    `rentawheel_dbms/crms_procedures_triggers.sql`

### 2. Backend Setup (Flask)
The backend runs on port `5001`.

1.  Open a terminal in the project root folder (`CAR RENTAL`).
2.  Navigate to the backend folder:
    ```bash
    cd backend
    ```
3.  Install Python dependencies:
    ```bash
    pip install -r requirements.txt
    ```
4.  **Important:** Open `backend/app/__init__.py` and update the `MYSQL_PASSWORD` to match your local MySQL password.

5.  Start the server:
    ```bash
    python run.py
    ```

### 3. Frontend Setup 
The frontend runs on port `5173` (Vite default).

1.  Open a **new** terminal window in the project root (`CAR RENTAL`).

2.  Navigate to the frontend folder:
    ```bash
    cd frontend
    ```
3.  Install Node dependencies:
    ```bash
    npm install
    ```
4.  Start the frontend:
    ```bash
    npm run dev
    ```
5.  Open the link shown in the terminal ( `http://localhost:5173`) to use the app.

---

## 📂 Project Structure
* **backend/** - Flask API and Python logic.
* **frontend/** - React frontend source code.
* **rentawheel_dbms/** - SQL scripts for database creation.