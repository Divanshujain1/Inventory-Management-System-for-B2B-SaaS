
INSERT INTO companies (company_name) VALUES ('Tech Traders');


INSERT INTO warehouses (company_id, warehouse_name)
VALUES (1, 'Main Warehouse');


INSERT INTO products (product_name, sku, product_type)
VALUES ('Widget A', 'WID-001', 'electronics');


INSERT INTO inventory (product_id, warehouse_id, current_stock)
VALUES (1, 1, 5);

INSERT INTO suppliers (supplier_name, contact_email)
VALUES ('Supplier Corp', 'orders@supplier.com');

INSERT INTO product_suppliers (product_id, supplier_id)
VALUES (1, 1);


INSERT INTO stock_thresholds (product_type, threshold)
VALUES ('electronics', 20);

INSERT INTO sales (product_id, quantity, sale_date)
VALUES (1, 3, CURRENT_DATE - INTERVAL '5 days'),
       (1, 2, CURRENT_DATE - INTERVAL '2 days');
