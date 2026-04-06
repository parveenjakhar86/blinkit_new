// User management routes
const express = require('express');
const router = express.Router();
const { adminAuth } = require('../../middleware');
const userController = require('../../controller/user');

router.get('/', adminAuth, userController.getAll);
router.post('/', adminAuth, userController.create);
router.put('/:id', adminAuth, userController.update);
router.delete('/:id', adminAuth, userController.remove);

module.exports = router;
