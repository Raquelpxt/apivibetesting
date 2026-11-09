POST /auth/login
  Happy path: valid email and password → 200 with token
  Negative: wrong password → 401
  Negative: missing email field → 400
  Negative: non-existent email → 401
  Auth: none required

GET /products
  Happy path: returns 200 with array of products
  Happy path: filter by valid category (e.g. ?category=computers) → 200 with filtered array
  Negative: non-existent category filter → 200 with empty array (or 400)
  Auth: none required

GET /products/{id}
  Happy path: valid ID (e.g. 1) → 200 with product object
  Negative: non-existent ID (e.g. 999) → 404
  Negative: invalid format ID (e.g. "abc") → 400
  Auth: none required

GET /cart
  Happy path: valid token → 200 with cart object (items and total)
  Negative: missing auth token → 401
  Negative: invalid or expired token → 401
  Auth: Bearer token required

POST /cart
  Happy path: valid token + productId + quantity → 201 with updated cart
  Negative: negative quantity (e.g. -5) → 400
  Negative: quantity zero or less than 1 → 400
  Negative: missing auth token → 401
  Negative: non-existent productId → 404
  Auth: Bearer token required

PUT /cart/{itemId}
  Happy path: valid token + valid itemId + quantity → 200 with updated cart
  Negative: quantity less than 1 (e.g. 0) → 400
  Negative: non-existent itemId → 404
  Negative: missing auth token → 401
  Auth: Bearer token required

DELETE /cart/{itemId}
  Happy path: valid token + valid itemId → 200 with item removed
  Negative: missing auth token → 401
  Negative: non-existent itemId → 404
  Auth: Bearer token required

GET /orders
  Happy path: valid token → 200 with array of user orders
  Negative: missing auth token → 401
  Negative: invalid or expired token → 401
  Auth: Bearer token required

POST /orders
  Happy path: valid token + items + shipping + valid payment → 201 with order confirmation
  Negative: expired card expiry date (e.g. 01/20) → 400
  Negative: invalid card number (not 16 digits) → 400
  Negative: missing required shipping fields → 400
  Negative: empty items array in body → 400
  Negative: missing auth token → 401
  Auth: Bearer token required
