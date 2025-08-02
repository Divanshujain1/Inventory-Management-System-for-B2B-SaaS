-- Companies table
CREATE TABLE companies (
    company_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_name VARCHAR(255) NOT NULL,
    company_code VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    tax_id VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE  
    --   company active or not
);

-- Warehouses
CREATE TABLE warehouses (
    warehouse_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT NOT NULL,
    warehouse_name VARCHAR(255) NOT NULL,
    warehouse_code VARCHAR(50) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    manager_name VARCHAR(255),
    manager_email VARCHAR(255),
    manager_phone VARCHAR(20),
    capacity_limit DECIMAL(15,2),
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_warehouse_company FOREIGN KEY (company_id) 
        REFERENCES companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_warehouse_code_company UNIQUE (company_id, warehouse_code)
);

-- If you want to track sales orders.
CREATE TABLE customers (
    customer_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    customer_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    tax_id VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE
);
-- For industries like pharma/food, you need to track expiry dates & batch number
CREATE TABLE product_batches (
    batch_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    product_id BIGINT NOT NULL,
    warehouse_id BIGINT NOT NULL,
    batch_number VARCHAR(100),
    manufacture_date DATE,
    expiry_date DATE,
    quantity DECIMAL(15,2),
    CONSTRAINT fk_batch_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT fk_batch_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);
-- Track every insert/update/delete for compliance.
CREATE TABLE audit_log (
    log_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    table_name VARCHAR(100),
    record_id BIGINT,
    action VARCHAR(20) CHECK (action IN ('INSERT','UPDATE','DELETE')),
    changed_by VARCHAR(255),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    old_data JSONB,
    new_data JSONB
);




-- Product categories
CREATE TABLE product_categories (
    category_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    category_name VARCHAR(255) NOT NULL,
    category_code VARCHAR(50) UNIQUE NOT NULL,
    parent_category_id BIGINT,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_parent_category FOREIGN KEY (parent_category_id) 
        REFERENCES product_categories(category_id)
);

-- Products
CREATE TABLE products (
    product_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    company_id BIGINT NOT NULL,
    category_id BIGINT,
    product_name VARCHAR(255) NOT NULL,
    product_code VARCHAR(100) NOT NULL,
    sku VARCHAR(100) UNIQUE NOT NULL,
    barcode VARCHAR(100),
    description TEXT,
    unit_of_measure VARCHAR(50) NOT NULL,
    weight DECIMAL(10,3),
    dimensions_length DECIMAL(10,2),
    dimensions_width DECIMAL(10,2),
    dimensions_height DECIMAL(10,2),
    cost_price DECIMAL(15,2),
    selling_price DECIMAL(15,2),
    minimum_stock_level DECIMAL(15,2) DEFAULT 0,
    maximum_stock_level DECIMAL(15,2),
    reorder_point DECIMAL(15,2),
    reorder_quantity DECIMAL(15,2),
    is_active BOOLEAN DEFAULT TRUE,
    is_bundle BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_product_company FOREIGN KEY (company_id) 
        REFERENCES companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_product_category FOREIGN KEY (category_id) 
        REFERENCES product_categories(category_id),
    CONSTRAINT uk_product_code_company UNIQUE (company_id, product_code),
    CONSTRAINT chk_positive_prices CHECK (cost_price >= 0 AND selling_price >= 0),
    CONSTRAINT chk_stock_levels CHECK (
        minimum_stock_level >= 0 AND 
        (maximum_stock_level IS NULL OR maximum_stock_level >= minimum_stock_level)
    )
);

-- Suppliers
CREATE TABLE suppliers (
    supplier_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    supplier_name VARCHAR(255) NOT NULL,
    supplier_code VARCHAR(50) UNIQUE NOT NULL,
    contact_person VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    tax_id VARCHAR(50),
    payment_terms VARCHAR(100),
    credit_limit DECIMAL(15,2),
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Supplier Products
CREATE TABLE supplier_products (
    supplier_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    supplier_product_code VARCHAR(100),
    unit_cost DECIMAL(15,2),
    minimum_order_quantity DECIMAL(15,2),
    lead_time_days INTEGER,
    is_preferred BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (supplier_id, product_id),
    CONSTRAINT fk_supplier FOREIGN KEY (supplier_id) 
        REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    CONSTRAINT fk_supplier_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id) ON DELETE CASCADE
);

-- Inventory
CREATE TABLE inventory (
    inventory_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    warehouse_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity_on_hand DECIMAL(15,2) NOT NULL DEFAULT 0,
    quantity_reserved DECIMAL(15,2) NOT NULL DEFAULT 0,
    quantity_available DECIMAL(15,2) GENERATED ALWAYS AS 
        (quantity_on_hand - quantity_reserved) STORED,
    last_counted_at TIMESTAMP WITH TIME ZONE,
    last_counted_by VARCHAR(255),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id) 
        REFERENCES warehouses(warehouse_id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id) ON DELETE CASCADE
);

-- Enum for movement types
CREATE TYPE movement_type AS ENUM (
    'RECEIPT',
    'SHIPMENT', 
    'ADJUSTMENT',
    'TRANSFER',
    'CONSUMPTION',
    'RETURN',
    'DAMAGE',
    'THEFT',
    'CYCLE_COUNT'
);

-- Inventory Movements
CREATE TABLE inventory_movements (
    movement_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    warehouse_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    movement_type movement_type NOT NULL,
    quantity_change DECIMAL(15,2) NOT NULL,
    quantity_before DECIMAL(15,2) NOT NULL,
    quantity_after DECIMAL(15,2) NOT NULL,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    unit_cost DECIMAL(15,2),
    total_cost DECIMAL(15,2),
    notes TEXT,
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_movement_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id) ON DELETE CASCADE,
    CONSTRAINT fk_movement_product FOREIGN KEY (product_id)
        REFERENCES products(product_id) ON DELETE CASCADE
);

-- Warehouse Locations
CREATE TABLE warehouse_locations (
    location_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    warehouse_id BIGINT NOT NULL,
    location_code VARCHAR(50) NOT NULL,
    location_name VARCHAR(255),
    aisle VARCHAR(10),
    rack VARCHAR(10),
    shelf VARCHAR(10),
    bin VARCHAR(10),
    location_type VARCHAR(50),
    CONSTRAINT fk_location_warehouse FOREIGN KEY (warehouse_id) 
        REFERENCES warehouses(warehouse_id) ON DELETE CASCADE
);

-- Bundle Components (for product bundles)
CREATE TABLE bundle_components (
    bundle_component_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    bundle_id BIGINT NOT NULL,
    component_product_id BIGINT NOT NULL,
    quantity DECIMAL(15,2) NOT NULL,
    CONSTRAINT fk_bundle FOREIGN KEY (bundle_id)
        REFERENCES products(product_id) ON DELETE CASCADE,
    CONSTRAINT fk_component FOREIGN KEY (component_product_id)
        REFERENCES products(product_id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_companies_active ON companies(is_active);
CREATE INDEX idx_companies_code ON companies(company_code);

CREATE INDEX idx_warehouses_company ON warehouses(company_id);
CREATE INDEX idx_warehouses_active ON warehouses(is_active);

CREATE INDEX idx_products_company ON products(company_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_bundle ON products(is_bundle);

CREATE INDEX idx_inventory_warehouse ON inventory(warehouse_id);
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_available ON inventory(quantity_available);
CREATE INDEX idx_inventory_updated ON inventory(updated_at);

CREATE INDEX idx_movements_warehouse ON inventory_movements(warehouse_id);
CREATE INDEX idx_movements_product ON inventory_movements(product_id);
CREATE INDEX idx_movements_type ON inventory_movements(movement_type);
CREATE INDEX idx_movements_created ON inventory_movements(created_at);
CREATE INDEX idx_movements_reference ON inventory_movements(reference_type, reference_id);

CREATE INDEX idx_supplier_products_supplier ON supplier_products(supplier_id);
CREATE INDEX idx_supplier_products_product ON supplier_products(product_id);
CREATE INDEX idx_supplier_products_preferred ON supplier_products(is_preferred);

-- Sample Data
INSERT INTO companies (company_name, company_code, email, phone)
VALUES ('ACME Corporation', 'ACME001', 'contact@acme.com', '+1-555-0123');

INSERT INTO warehouses (company_id, warehouse_name, warehouse_code, address, city, country)
VALUES 
(1, 'Main Warehouse', 'WH001', '123 Industrial Blvd', 'Chicago', 'USA'),
(1, 'East Coast Distribution', 'WH002', '456 Shipping Lane', 'New York', 'USA');

INSERT INTO product_categories (category_name, category_code, description)
VALUES 
('Electronics', 'ELEC', 'Electronic devices and components'),
('Furniture', 'FURN', 'Office and home furniture');

INSERT INTO products (company_id, category_id, product_name, product_code, sku, unit_of_measure, cost_price, selling_price)
VALUES 
(1, 1, 'Laptop Computer', 'LAPTOP001', 'SKU-LAPTOP-001', 'pcs', 800.00, 1200.00),
(1, 2, 'Office Chair', 'CHAIR001', 'SKU-CHAIR-001', 'pcs', 150.00, 250.00),
(1, 1, 'Office Bundle', 'BUNDLE001', 'SKU-BUNDLE-001', 'set', 0.00, 1400.00);

UPDATE products SET is_bundle = TRUE WHERE product_code = 'BUNDLE001';

INSERT INTO bundle_components (bundle_id, component_product_id, quantity)
VALUES 
(3, 1, 1), -- 1 laptop
(3, 2, 1); -- 1 chair
