// Product management controller
const Product = require('../../model/Product');

function toPayload(body) {
  return {
    name: body.name,
    category: body.category || 'General',
    price: Number(body.price || 0),
    image: body.image || '',
    description: body.description || '',
    stock: Number(body.stock || 0)
  };
}

// Get all products
exports.getAll = async (req, res) => {
  const products = await Product.find().sort({ _id: -1 });
  res.json(products);
};

// Create product
exports.create = async (req, res) => {
  const product = new Product(toPayload(req.body));
  await product.save();
  res.status(201).json(product);
};

// Update product
exports.update = async (req, res) => {
  const product = await Product.findByIdAndUpdate(req.params.id, toPayload(req.body), { new: true });
  if (!product) {
    return res.status(404).json({ message: 'Product not found' });
  }
  res.json(product);
};

// Delete product
exports.remove = async (req, res) => {
  await Product.findByIdAndDelete(req.params.id);
  res.json({ message: 'Product deleted' });
};
