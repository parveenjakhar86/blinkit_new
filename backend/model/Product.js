// Product model for MongoDB
const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  name: { type: String, required: true },
  category: { type: String, default: 'General' },
  price: { type: Number, required: true },
  image: { type: String },
  description: { type: String },
  stock: { type: Number, default: 0 }
});

module.exports = mongoose.model('Product', productSchema);
