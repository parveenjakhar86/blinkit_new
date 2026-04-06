const express = require('express');
const router = express.Router();
const { adminAuth } = require('../../middleware');
const customerController = require('../../controller/customer');

router.get('/', adminAuth, customerController.getAll);
router.post('/', adminAuth, customerController.create);
router.put('/:id', adminAuth, customerController.update);
router.delete('/:id', adminAuth, customerController.remove);

module.exports = router;
