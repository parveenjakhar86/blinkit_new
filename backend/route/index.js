// Main router for API endpoints
const express = require('express');
const router = express.Router();


// Admin login route
router.post('/admin/login', require('../controller/adminAuthController').login);

// User login route (admin, manager, staff)
router.post('/user/login', require('../controller/user/userLoginController').login);

// Customer login route
router.post('/customer/login', require('../controller/customer/customerAuthController').login);
router.post('/customer/send-otp', require('../controller/customer/customerAuthController').sendOtp);
router.post('/customer/verify-otp', require('../controller/customer/customerAuthController').verifyOtp);

// Public order placement for customer checkout
router.post('/orders/place', require('../controller/order').placeOrder);

// Public product listing for mobile / customer storefront
router.get('/products', async (req, res) => {
  try {
    const Product = require('../model/Product');
    const products = await Product.find({});
    res.json(products);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch products' });
  }
});

// Example protected admin route (replace with real management routes)
const { adminAuth, customerAuth } = require('../middleware');
router.get('/admin/protected', adminAuth, (req, res) => {
	res.json({ message: 'You are authenticated as admin', user: req.user });
});

router.get('/customer/orders', customerAuth, require('../controller/order').getCustomerOrders);



// Modular resource routers
router.use('/admin/users', require('./user'));
router.use('/admin/customers', require('./customer'));
router.use('/admin/orders', require('./order'));
router.use('/admin/products', require('./product'));

// Export the router to be used in app.js
module.exports = router;
