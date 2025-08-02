from flask import request, jsonify, Blueprint
from sqlalchemy.exc import IntegrityError
from decimal import Decimal, InvalidOperation
from app.models.product import db, Product, Inventory, Warehouse

products_bp = Blueprint('products', __name__)

@products_bp.route('/api/products', methods=['POST'])
def create_product():
   

        # 1. INPUT VALIDATION
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
            required_fields = ['name', 'sku', 'warehouse_id', 'initial_quantity']
            optional_fields = ['price', 'description']  # Some fields might be optional
        
        missing_fields = [field for field in required_fields if field not in data or data[field] is None]
        if missing_fields:
            return jsonify({
                'error': f'Missing required fields: {", ".join(missing_fields)}'
            }), 400
        
        # Check required fields
        required_fields = ['name', 'sku', 'price', 'warehouse_id', 'initial_quantity']
        missing_fields = [field for field in required_fields if field not in data]
        if missing_fields:
            return jsonify({
                'error': f'Missing required fields: {", ".join(missing_fields)}'
            }), 400
        
        # Validate price
        try:
            price = Decimal(str(data['price']))
            if price < 0:
                return jsonify({'error': 'Price cannot be negative'}), 400
        except (InvalidOperation, TypeError):
            return jsonify({'error': 'Invalid price format'}), 400
        
        # Validate quantity
        try:
            initial_quantity = int(data['initial_quantity'])
            if initial_quantity < 0:
                return jsonify({'error': 'Initial quantity cannot be negative'}), 400
        except (ValueError, TypeError):
            return jsonify({'error': 'Initial quantity must be a valid integer'}), 400
        
        # 2. BUSINESS LOGIC VALIDATION
        
        existing_product = Product.query.filter_by(sku=data['sku'].strip().upper()).first()
        if existing_product:
            # Product exists - check if it's already in this warehouse
            existing_inventory = Inventory.query.filter_by(
                product_id=existing_product.id,
                warehouse_id=data['warehouse_id']
            ).first()
            
            if existing_inventory:
                return jsonify({
                    'error': f'Product {data["sku"]} already exists in warehouse {data["warehouse_id"]}'
                }), 409
            else:
                # Product exists but not in this warehouse - add inventory record
                warehouse = Warehouse.query.get(data['warehouse_id'])
                if not warehouse:
                    return jsonify({'error': f'Warehouse {data["warehouse_id"]} not found'}), 404
                
                try:
                    inventory = Inventory(
                        product_id=existing_product.id,
                        warehouse_id=data['warehouse_id'],
                        quantity=initial_quantity
                    )
                    db.session.add(inventory)
                    db.session.commit()
                    
                    return jsonify({
                        'message': 'Product added to new warehouse successfully',
                        'product_id': existing_product.id,
                        'sku': existing_product.sku,
                        'warehouse_id': data['warehouse_id'],
                        'action': 'added_to_warehouse'
                    }), 201
                    
                except IntegrityError:
                    db.session.rollback()
                    return jsonify({'error': 'Database integrity error'}), 500
        
        # Check warehouse exists for new product
        warehouse = Warehouse.query.get(data['warehouse_id'])
        if not warehouse:
            return jsonify({'error': f'Warehouse {data["warehouse_id"]} not found'}), 404
        
        # 3. DATABASE TRANSACTION - CREATE NEW PRODUCT
        try:
            # Create product (NO warehouse_id in product table!)
            product = Product(
                name=data['name'].strip(),
                sku=data['sku'].strip().upper(),
                price=price,  # Can be None
                description=data.get('description', '').strip() if data.get('description') else None
            )
            db.session.add(product)
            db.session.flush()  # Get product.id without committing
            
            # Create inventory record (this links product to warehouse)
            inventory = Inventory(
                product_id=product.id,
                warehouse_id=data['warehouse_id'],
                quantity=initial_quantity
            )
            db.session.add(inventory)
            
            # Single commit for data integrity
            db.session.commit()
            
            return jsonify({
                'message': 'Product created successfully',
                'product_id': product.id,
                'sku': product.sku,
                'warehouse_id': data['warehouse_id'],
                'action': 'created_new_product'
            }), 201
            
        except IntegrityError as e:
            db.session.rollback()
            return jsonify({'error': 'Database integrity error occurred'}), 500
            
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': 'Internal server error'}), 500