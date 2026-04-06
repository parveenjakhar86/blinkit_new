// Order management routes
const express = require('express');
const router = express.Router();
const { adminAuth, managerAuth } = require('../../middleware');
const orderController = require('../../controller/order');

router.get('/', managerAuth, orderController.getAll);
router.post('/', managerAuth, orderController.create);
router.put('/:id', managerAuth, orderController.update);
router.delete('/:id', managerAuth, orderController.remove);

module.exports = router;
