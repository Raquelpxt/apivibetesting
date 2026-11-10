const express = require('express');
const products = require('../data/products');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

const carts = {};

function getCart(userId) {
  if (!carts[userId]) carts[userId] = [];
  return carts[userId];
}

/**
 * @openapi
 * /cart:
 *   get:
 *     summary: Get the current user's cart
 *     tags: [Cart]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Cart contents
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Cart'
 *       401:
 *         description: Unauthorized
 */
router.get('/', authenticate, (req, res) => {
  const cart = getCart(req.user.id);
  const total = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  res.json({ items: cart, total: parseFloat(total.toFixed(2)) });
});

/**
 * @openapi
 * /cart:
 *   post:
 *     summary: Add an item to the cart
 *     tags: [Cart]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [productId, quantity]
 *             properties:
 *               productId:
 *                 type: integer
 *                 example: 1
 *               quantity:
 *                 type: integer
 *                 minimum: 1
 *                 example: 2
 *     responses:
 *       201:
 *         description: Item added to cart
 *       400:
 *         description: Invalid productId or quantity
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Product not found
 */
// FIX B2: Quantity must be >= 1
router.post('/', authenticate, (req, res) => {
  const { productId, quantity } = req.body;

  if (!productId || quantity === undefined) {
    return res.status(400).json({ error: 'productId and quantity are required' });
  }

  if (!Number.isInteger(quantity) || quantity < 1) {
    return res.status(400).json({ error: 'Quantity must be a whole number of at least 1' });
  }

  const product = products.find(p => p.id === parseInt(productId));
  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }

  if (product.stock === 0) {
    return res.status(400).json({ error: 'Product is out of stock' });
  }

  const cart = getCart(req.user.id);
  const existing = cart.find(item => item.productId === product.id);

  if (existing) {
    existing.quantity += quantity;
  } else {
    cart.push({
      id: cart.length + 1,
      productId: product.id,
      name: product.name,
      price: product.price,
      quantity
    });
  }

  const total = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  res.status(201).json({ items: cart, total: parseFloat(total.toFixed(2)) });
});

/**
 * @openapi
 * /cart/{itemId}:
 *   put:
 *     summary: Update the quantity of a cart item
 *     tags: [Cart]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: itemId
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [quantity]
 *             properties:
 *               quantity:
 *                 type: integer
 *                 minimum: 1
 *                 example: 3
 *     responses:
 *       200:
 *         description: Cart item updated
 *       400:
 *         description: Invalid quantity
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Cart item not found
 */
router.put('/:itemId', authenticate, (req, res) => {
  const { quantity } = req.body;
  const itemId = parseInt(req.params.itemId);

  if (!quantity || quantity < 1) {
    return res.status(400).json({ error: 'Quantity must be at least 1' });
  }

  const cart = getCart(req.user.id);
  const item = cart.find(i => i.id === itemId || i.productId === itemId);

  if (!item) {
    return res.status(404).json({ error: 'Cart item not found' });
  }

  item.quantity = quantity;
  const total = cart.reduce((sum, i) => sum + i.price * i.quantity, 0);
  res.json({ items: cart, total: parseFloat(total.toFixed(2)) });
});

/**
 * @openapi
 * /cart/{itemId}:
 *   delete:
 *     summary: Remove an item from the cart
 *     tags: [Cart]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: itemId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Item removed from cart
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Cart item not found
 */
// FIX B4: authenticate middleware is now present
router.delete('/:itemId', authenticate, (req, res) => {
  const itemId = parseInt(req.params.itemId);
  const cart = getCart(req.user.id);
  const index = cart.findIndex(i => i.id === itemId || i.productId === itemId);

  if (index === -1) {
    return res.status(404).json({ error: 'Cart item not found' });
  }

  cart.splice(index, 1);
  const total = cart.reduce((sum, i) => sum + i.price * i.quantity, 0);
  res.json({ items: cart, total: parseFloat(total.toFixed(2)) });
});

module.exports = router;
