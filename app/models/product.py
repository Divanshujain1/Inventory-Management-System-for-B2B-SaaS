from flask_sqlalchemy import SQLAlchemy
from decimal import Decimal

db = SQLAlchemy()

class Product(db.Model):
    __tablename__ = 'products'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    sku = db.Column(db.String(100), unique=True, nullable=False, index=True)
    price = db.Column(db.Numeric(10, 2), nullable=False)
    warehouse_id = db.Column(db.Integer, db.ForeignKey('warehouses.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=db.func.current_timestamp())
    
    # Relationships
    inventory_records = db.relationship('Inventory', backref='product', lazy=True)
    
    def __repr__(self):
        return f'<Product {self.sku}: {self.name}>'

class Warehouse(db.Model):
    __tablename__ = 'warehouses'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    location = db.Column(db.String(255))
    
class Inventory(db.Model):
    __tablename__ = 'inventory'
    
    id = db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.Integer, db.ForeignKey('products.id'), nullable=False)
    warehouse_id = db.Column(db.Integer, db.ForeignKey('warehouses.id'), nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=0)
    updated_at = db.Column(db.DateTime, default=db.func.current_timestamp())