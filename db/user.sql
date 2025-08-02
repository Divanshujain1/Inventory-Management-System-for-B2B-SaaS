
CREATE TABLE companies (
    company_id BIGSERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL
);

CREATE TABLE warehouses (
    warehouse_id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES companies(company_id),
    warehouse_name VARCHAR(255) NOT NULL
);


CREATE TABLE products (
    product_id BIGSERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) UNIQUE,
    product_type VARCHAR(50) NOT NULL
);


CREATE TABLE inventory (
    inventory_id BIGSERIAL PRIMARY KEY,
    product_id BIGINT REFERENCES products(product_id),
    warehouse_id BIGINT REFERENCES warehouses(warehouse_id),
    current_stock INT NOT NULL
);

CREATE TABLE sales (
    sale_id BIGSERIAL PRIMARY KEY,
    product_id BIGINT REFERENCES products(product_id),
    quantity INT NOT NULL,
    sale_date DATE NOT NULL
);


CREATE TABLE suppliers (
    supplier_id BIGSERIAL PRIMARY KEY,
    supplier_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255)
);


CREATE TABLE product_suppliers (
    product_id BIGINT REFERENCES products(product_id),
    supplier_id BIGINT REFERENCES suppliers(supplier_id),
    PRIMARY KEY (product_id, supplier_id)
);

CREATE TABLE stock_thresholds (
    product_type VARCHAR(50) PRIMARY KEY,
    threshold INT NOT NULL
);
