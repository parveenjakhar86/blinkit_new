const express = require('express');

const { adminAuth } = require('../../middleware');
const riderAdminController = require('../../controller/rider/riderAdminController');

const router = express.Router();

router.get('/', adminAuth, riderAdminController.getAll);
router.post('/', adminAuth, riderAdminController.create);
router.put('/:id', adminAuth, riderAdminController.update);
router.delete('/:id', adminAuth, riderAdminController.remove);

module.exports = router;