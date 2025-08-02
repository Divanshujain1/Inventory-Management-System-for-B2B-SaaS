import pytest
import json
from app import create_app
from app.models.product import db, Product, Warehouse

@pytest.fixture
def client():
    app = create_app('testing')
    with app.test_client() as client: # Create test warehouse
        with app.app_context():
            db.create_all()
           
            warehouse = Warehouse(id=1, name='Test Warehouse', location='Test City')
            db.session.add(warehouse)
            db.session.commit()
            yield client
            db.drop_all()

def test_create_product_success(client):
    """Test successful product creation"""
    payload = {
        'name': 'Test Product',
        'sku': 'TEST001',
        'price': '29.99',
        'warehouse_id': 1,
        'initial_quantity': 100
    }
    response = client.post('/api/products', 
                          data=json.dumps(payload),
                          content_type='application/json')
    
    assert response.status_code == 201
    data = json.loads(response.data)
    assert 'product_id' in data
    assert data['sku'] == 'TEST001'

def test_create_product_missing_fields(client): # Missing sku, price, warehouse_id, initial_quantity
    """Test missing required fields"""
    payload = {
        'name': 'Test Product',
        
    }
    response = client.post('/api/products',
                          data=json.dumps(payload),
                          content_type='application/json')
    
    assert response.status_code == 400
    data = json.loads(response.data)
    assert 'Missing required fields' in data['error']

def test_create_product_duplicate_sku(client):
    """Test duplicate SKU rejection"""
    payload = {
        'name': 'Test Product',
        'sku': 'DUPLICATE001',
        'price': '29.99',
        'warehouse_id': 1,
        'initial_quantity': 100
    }
    

    client.post('/api/products', 
                data=json.dumps(payload),    # Create first product
                content_type='application/json')
    
    # Try to create duplicate
    response = client.post('/api/products',
                          data=json.dumps(payload),
                          content_type='application/json')
    
    assert response.status_code == 409
    data = json.loads(response.data)
    assert 'already exists' in data['error']