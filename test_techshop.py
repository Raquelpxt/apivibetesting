import os
import pytest
import requests

BASE_URL = os.getenv("BASE_URL", "http://localhost:3000")

@pytest.fixture
def auth_token():
    email = os.getenv("TEST_EMAIL", "demo@techshop.com")
    password = os.getenv("TEST_PASSWORD", "password123")
    if not email or not password:
        raise ValueError("TEST_EMAIL and TEST_PASSWORD must be set as environment variables")
    
    response = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
    assert response.status_code == 200, f"Login failed: {response.text}"
    data = response.json()
    assert "token" in data, "No token found in login response"
    return data["token"]

@pytest.fixture
def auth_headers(auth_token):
    return {"Authorization": f"Bearer {auth_token}", "Content-Type": "application/json"}

# ─── Auth Endpoints ──────────────────────────────────────────────────────────

def test_login_valid_credentials():
    email = os.getenv("TEST_EMAIL", "demo@techshop.com")
    password = os.getenv("TEST_PASSWORD", "password123")
    res = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
    assert res.status_code == 200
    data = res.json()
    assert "token" in data
    assert "user" in data

def test_login_wrong_password_returns_401():
    email = os.getenv("TEST_EMAIL", "demo@techshop.com")
    res = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": "wrongpassword"})
    assert res.status_code == 401

def test_login_missing_email_returns_400():
    password = os.getenv("TEST_PASSWORD", "password123")
    res = requests.post(f"{BASE_URL}/auth/login", json={"password": password})
    assert res.status_code == 400

def test_login_missing_password_returns_400():
    email = os.getenv("TEST_EMAIL", "demo@techshop.com")
    res = requests.post(f"{BASE_URL}/auth/login", json={"email": email})
    assert res.status_code == 400

def test_login_nonexistent_email_returns_401():
    res = requests.post(f"{BASE_URL}/auth/login", json={"email": "nonexistent@techshop.com", "password": "password123"})
    assert res.status_code == 401

# ─── Products Endpoints ──────────────────────────────────────────────────────

def test_get_all_products_returns_200():
    res = requests.get(f"{BASE_URL}/products")
    assert res.status_code == 200
    assert isinstance(res.json(), list)
    assert len(res.json()) > 0

def test_get_products_filter_by_category():
    res = requests.get(f"{BASE_URL}/products", params={"category": "computers"})
    assert res.status_code == 200
    for product in res.json():
        assert product.get("category") == "computers"

def test_get_products_nonexistent_category_returns_empty():
    res = requests.get(f"{BASE_URL}/products", params={"category": "nonexistentcategory"})
    assert res.status_code == 200
    assert len(res.json()) == 0

def test_get_product_valid_id():
    res = requests.get(f"{BASE_URL}/products/1")
    assert res.status_code == 200
    assert res.json().get("id") == 1

def test_get_product_not_found_returns_404():
    res = requests.get(f"{BASE_URL}/products/999")
    assert res.status_code == 404

def test_get_product_invalid_id_format_returns_400():
    res = requests.get(f"{BASE_URL}/products/abc")
    assert res.status_code == 400

# ─── Cart Endpoints ──────────────────────────────────────────────────────────

def test_get_cart_valid_auth(auth_headers):
    res = requests.get(f"{BASE_URL}/cart", headers=auth_headers)
    assert res.status_code == 200
    data = res.json()
    assert "items" in data
    assert "total" in data

def test_get_cart_missing_auth_returns_401():
    res = requests.get(f"{BASE_URL}/cart")
    assert res.status_code == 401

def test_get_cart_invalid_auth_returns_401():
    res = requests.get(f"{BASE_URL}/cart", headers={"Authorization": "Bearer invalid_token"})
    assert res.status_code == 401

def test_add_to_cart_valid(auth_headers):
    res = requests.post(f"{BASE_URL}/cart", json={"productId": 1, "quantity": 2}, headers=auth_headers)
    assert res.status_code == 201

@pytest.mark.parametrize("invalid_qty", [-5, 0, -1])
def test_add_to_cart_invalid_quantity_returns_400(auth_headers, invalid_qty):
    res = requests.post(f"{BASE_URL}/cart", json={"productId": 1, "quantity": invalid_qty}, headers=auth_headers)
    assert res.status_code == 400

def test_add_to_cart_missing_fields_returns_400(auth_headers):
    res = requests.post(f"{BASE_URL}/cart", json={"quantity": 1}, headers=auth_headers)
    assert res.status_code == 400

def test_add_to_cart_missing_auth_returns_401():
    res = requests.post(f"{BASE_URL}/cart", json={"productId": 1, "quantity": 1})
    assert res.status_code == 401

def test_add_to_cart_nonexistent_product_returns_404(auth_headers):
    res = requests.post(f"{BASE_URL}/cart", json={"productId": 9999, "quantity": 1}, headers=auth_headers)
    assert res.status_code == 404

def test_update_cart_item_valid(auth_headers):
    requests.post(f"{BASE_URL}/cart", json={"productId": 1, "quantity": 1}, headers=auth_headers)
    res = requests.put(f"{BASE_URL}/cart/1", json={"quantity": 3}, headers=auth_headers)
    assert res.status_code == 200

def test_update_cart_item_quantity_less_than_1_returns_400(auth_headers):
    res = requests.put(f"{BASE_URL}/cart/1", json={"quantity": 0}, headers=auth_headers)
    assert res.status_code == 400

def test_update_cart_item_missing_auth_returns_401():
    res = requests.put(f"{BASE_URL}/cart/1", json={"quantity": 2})
    assert res.status_code == 401

def test_update_cart_item_nonexistent_id_returns_404(auth_headers):
    res = requests.put(f"{BASE_URL}/cart/9999", json={"quantity": 2}, headers=auth_headers)
    assert res.status_code == 404

def test_remove_cart_item_valid(auth_headers):
    requests.post(f"{BASE_URL}/cart", json={"productId": 1, "quantity": 1}, headers=auth_headers)
    res = requests.delete(f"{BASE_URL}/cart/1", headers=auth_headers)
    assert res.status_code == 200

def test_remove_cart_item_missing_auth_returns_401():
    res = requests.delete(f"{BASE_URL}/cart/1")
    assert res.status_code == 401

def test_remove_cart_item_nonexistent_id_returns_404(auth_headers):
    res = requests.delete(f"{BASE_URL}/cart/9999", headers=auth_headers)
    assert res.status_code == 404

# ─── Orders Endpoints ────────────────────────────────────────────────────────

def test_get_orders_valid(auth_headers):
    res = requests.get(f"{BASE_URL}/orders", headers=auth_headers)
    assert res.status_code == 200
    assert isinstance(res.json(), list)

def test_get_orders_missing_auth_returns_401():
    res = requests.get(f"{BASE_URL}/orders")
    assert res.status_code == 401

def test_place_order_valid(auth_headers):
    payload = {
        "items": [{"productId": 1, "quantity": 2}],
        "shipping": {
            "firstName": "Jane",
            "lastName": "Doe",
            "email": "jane@example.com",
            "phone": "0412345678"
        },
        "payment": {
            "cardNumber": "4111111111111111",
            "expiryDate": "12/28",
            "cvv": "123"
        }
    }
    res = requests.post(f"{BASE_URL}/orders", json=payload, headers=auth_headers)
    assert res.status_code == 201
    assert "id" in res.json()
    assert res.json().get("status") == "confirmed"

def test_place_order_expired_card_returns_400(auth_headers):
    payload = {
        "items": [{"productId": 1, "quantity": 1}],
        "shipping": {
            "firstName": "Jane",
            "lastName": "Doe",
            "email": "jane@example.com",
            "phone": "0412345678"
        },
        "payment": {
            "cardNumber": "4111111111111111",
            "expiryDate": "01/20",
            "cvv": "123"
        }
    }
    res = requests.post(f"{BASE_URL}/orders", json=payload, headers=auth_headers)
    assert res.status_code == 400

def test_place_order_invalid_card_number_returns_400(auth_headers):
    payload = {
        "items": [{"productId": 1, "quantity": 1}],
        "shipping": {
            "firstName": "Jane",
            "lastName": "Doe",
            "email": "jane@example.com",
            "phone": "0412345678"
        },
        "payment": {
            "cardNumber": "1234",
            "expiryDate": "12/28",
            "cvv": "123"
        }
    }
    res = requests.post(f"{BASE_URL}/orders", json=payload, headers=auth_headers)
    assert res.status_code == 400

def test_place_order_missing_shipping_fields_returns_400(auth_headers):
    payload = {
        "items": [{"productId": 1, "quantity": 1}],
        "shipping": {"firstName": "Jane"},
        "payment": {
            "cardNumber": "4111111111111111",
            "expiryDate": "12/28",
            "cvv": "123"
        }
    }
    res = requests.post(f"{BASE_URL}/orders", json=payload, headers=auth_headers)
    assert res.status_code == 400

def test_place_order_empty_items_returns_400(auth_headers):
    payload = {
        "items": [],
        "shipping": {
            "firstName": "Jane",
            "lastName": "Doe",
            "email": "jane@example.com",
            "phone": "0412345678"
        },
        "payment": {
            "cardNumber": "4111111111111111",
            "expiryDate": "12/28",
            "cvv": "123"
        }
    }
    res = requests.post(f"{BASE_URL}/orders", json=payload, headers=auth_headers)
    assert res.status_code == 400

def test_place_order_missing_auth_returns_401():
    payload = {
        "items": [{"productId": 1, "quantity": 1}],
        "shipping": {
            "firstName": "Jane",
            "lastName": "Doe",
            "email": "jane@example.com",
            "phone": "0412345678"
        },
        "payment": {
            "cardNumber": "4111111111111111",
            "expiryDate": "12/28",
            "cvv": "123"
        }
    }
    res = requests.post(f"{BASE_URL}/orders", json=payload)
    assert res.status_code == 401

