# Inventory-Management-System-for-B2B-SaaS
Internship Task
**Document: Low Stock Alert API for Inventory Management**
1.** Problem Statement**
For any business handling products across multiple warehouses, maintaining an adequate stock level is essential. If stock runs too low, sales can be lost and customers may become dissatisfied. To solve this, we are designing a system that alerts a company whenever any product is approaching a shortage.

**The system must take into account:**
Different stock thresholds per product type
Only products with recent sales activity (no need to alert for dead stock)
Multiple warehouses belonging to the same company
Supplier information so that reordering is easier
An estimate of days until stock runs out, based on recent sales trends
The result is an API endpoint that companies can call to get a list of low-stock products.

**2. Approach**
We decided to build this using:
PostgreSQL as the database (because it supports complex queries and relationships).
Node.js with Express as the backend server (lightweight and easy to integrate with SQL).
Direct SQL queries using pg library in Node.js (instead of ORM like Sequelize, to keep things transparent and simple).
Postman as the testing tool to call our API endpoint.\

**3. Database Design**
We created a relational schema to support the requirements. The main entities are:
Companies: Each company can have multiple warehouses.
Warehouses: Each warehouse belongs to a company and holds inventory.
Products: Items being sold.
Inventory: Tracks how much stock of each product is available in each warehouse.
Sales: Records each sale, used to check recent activity.
Suppliers: Vendors providing the products.
Product-Supplier mapping: Since products can have suppliers linked.

**4. Backend Implementation**
The API was built using Express. Below is the step-by-step flow when the endpoint is called:
Validate the company ID
Check if the company exists in the database.
If not found, return a 404 error. Get company’s warehouses
Query all warehouses belonging to the company.
If none exist, return an empty alert list.
Check for recent sales activity
We only consider products sold in the last 30 days.
This avoids sending alerts for inactive products.
Also fetch thresholds from stock_thresholds.
Identify low-stock products
For each product, compare current_stock with the threshold.
If below threshold, calculate how many days until the stock will run out.
Calculate stockout days
Compute the average daily sales from the last 30 days.
Days until stockout = Current Stock ÷ Average Daily Sales.
Format the response
Return product details, warehouse info, threshold, days until stockout, and supplier contact.
The result is a JSON object with an alerts array and a total_alerts count.


 Alternative Approaches**
MySQL instead of PostgreSQL: Possible, but PostgreSQL offers stronger JSON and query features.
Automated Seeding from Node.js: Instead of manually running SQL files, we could have a Node.js script that creates tables and inserts data automatically.
Front-end Integration: A React or Angular dashboard could consume this API and show alerts visually.
Email/SMS Alerts: Extend the backend so when a low-stock alert is triggered, a notification is automatically sent to the company.

**Conclusion**
This project demonstrates how to build a reliable inventory alert system with Node.js and PostgreSQL. The API is designed to handle multiple warehouses, recent sales filtering, custom thresholds, and supplier integration.
With proper testing in Postman, the system provides actionable insights to companies, helping them prevent stockouts and maintain smooth operations.
This structure is scalable: more warehouses, more products, and more suppliers can easily be added without changing the core design
