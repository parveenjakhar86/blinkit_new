// Product management routes
const express = require('express');
const router = express.Router();
const { adminAuth, managerAuth } = require('../../middleware');
const productController = require('../../controller/product');

router.get('/', managerAuth, productController.getAll);
router.post('/', managerAuth, productController.create);
router.put('/:id', managerAuth, productController.update);
router.delete('/:id', managerAuth, productController.remove);

module.exports = router;
