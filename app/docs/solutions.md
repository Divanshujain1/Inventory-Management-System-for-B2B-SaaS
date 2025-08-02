Inventory Management System for B2B SaaS

Task 1 - Code Review & Debugging


ISSUES

Missing Input Validation
1.	Crashes with KeyError if required fields missing 
2.	Accepts invalid data types (string for price, negative quantities)
3.	No protection against malicious inputs

 No Error Handling
1.	Application crashes on database errors 
2.	No graceful error responses to clients
3.	Difficult to debug production issues
Missing Warehouse Validation

1.	Foreign key constraint violations
2.	Products linked to non-existent warehouses
3.	Data integrity issues
Transaction Management Issues / Missing SKU Uniqueness Check

1.	Product created but inventory might fail (orphaned data) 
2.	Inconsistent database state 
3.	No rollback mechanism
4.	Duplicate SKUs break business logic 
5.	Data integrity violations 
6.	Inventory tracking becomes unreliable

Key Points to Emphasize:

1.	Systematic Problem Analysis - I identified 5 major issues with clear explanations
2.	Production-Ready Solution - Complete rewrite with proper error handling
3.	Professional Folder Structure - Shows you understand scalable architecture
4.	Testing Strategy - Demonstrates quality-focused mindset
5.  Transaction Safety:** Single commit with proper rollback
6.  Response Format:** Proper HTTP status codes and JSON responses
7.  Data Normalization:** SKU converted to uppercase, names trimmed

Original Problem: 
Product had warehouse_id (only 1 warehouse per product)
Fixed: Products exist independently, linked to warehouses via Inventory table
Business Logic: Same SKU can exist in multiple warehouses via inventory records