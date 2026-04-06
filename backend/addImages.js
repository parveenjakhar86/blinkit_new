// Script to add product images to the database
require('dotenv').config();
const mongoose = require('mongoose');
const Product = require('./model/product/product');

const imageMap = {
  'banana':   'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&q=80',
  'milk':     'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400&q=80',
  'bread':    'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&q=80',
  'rice':     'https://images.unsplash.com/photo-1536304929831-ee1ca9d44906?w=400&q=80',
  'egg':      'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400&q=80',
  'tomato':   'https://images.unsplash.com/photo-1546470427-e26264be0b2d?w=400&q=80',
  'apple':    'https://images.unsplash.com/photo-1569870499705-504209102861?w=400&q=80',
  'onion':    'https://images.unsplash.com/photo-1508747703725-719777637510?w=400&q=80',
  'potato':   'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400&q=80',
  'butter':   'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&q=80',
  'cheese':   'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400&q=80',
  'curd':     'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400&q=80',
  'oil':      'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&q=80',
  'atta':     'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400&q=80',
  'sugar':    'https://images.unsplash.com/photo-1558642144-7b69c94f75ac?w=400&q=80',
  'coffee':   'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400&q=80',
  'tea':      'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=400&q=80',
  'biscuit':  'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&q=80',
  'juice':    'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400&q=80',
  'water':    'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400&q=80',
  'soap':     'https://images.unsplash.com/photo-1584305574647-0cc949a2bb9f?w=400&q=80',
  'shampoo':  'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80',
  'cream':    'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80',
  'chocolate':'https://images.unsplash.com/photo-1518057111178-44a106bad636?w=400&q=80',
  'chips':    'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&q=80',
  'diaper':   'https://images.unsplash.com/photo-1584515933487-779824d29309?w=400&q=80',
  'lotion':   'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=400&q=80',
  'face wash':'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&q=80',
  'detergent':'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=400&q=80',
  'cleaner':  'https://images.unsplash.com/photo-1583947581924-a6d7f0f4c7ec?w=400&q=80',
  'earbuds':  'https://images.unsplash.com/photo-1588423771073-b8903fbb85b5?w=400&q=80',
  'power bank':'https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=400&q=80',
  'protein':  'https://images.unsplash.com/photo-1606312619344-8f2bf0f82f2f?w=400&q=80',
  'electrolyte':'https://images.unsplash.com/photo-1622543925917-763c34d1a86e?w=400&q=80',
  'cola':     'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400&q=80',
  'soft drink':'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400&q=80',
};

const categoryMap = {
  'dairy': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400&q=80',
  'fruits': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&q=80',
  'vegetables': 'https://images.unsplash.com/photo-1546470427-e26264be0b2d?w=400&q=80',
  'atta': 'https://images.unsplash.com/photo-1627485937980-221c88ac04f9?w=400&q=80',
  'rice': 'https://images.unsplash.com/photo-1536304929831-ee1ca9d44906?w=400&q=80',
  'dal': 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400&q=80',
  'cold drinks': 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400&q=80',
  'munchies': 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&q=80',
  'baby care': 'https://images.unsplash.com/photo-1584515933487-779824d29309?w=400&q=80',
  'beauty': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&q=80',
  'household': 'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=400&q=80',
  'electronics': 'https://images.unsplash.com/photo-1588423771073-b8903fbb85b5?w=400&q=80',
  'summer': 'https://images.unsplash.com/photo-1622543925917-763c34d1a86e?w=400&q=80',
};

function getImageForProduct(product) {
  const name = (product.name || '').toLowerCase();
  const category = (product.category || '').toLowerCase();

  for (const [keyword, url] of Object.entries(imageMap)) {
    if (name.includes(keyword)) return url;
  }

  for (const [keyword, url] of Object.entries(categoryMap)) {
    if (category.includes(keyword)) return url;
  }

  // Default grocery image
  return 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400&q=80';
}

async function run() {
  await mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://localhost:27017/blinkit');
  console.log('Connected to MongoDB');

  const products = await Product.find({});
  console.log(`Found ${products.length} products`);

  for (const product of products) {
    const imageUrl = getImageForProduct(product);
    await Product.updateOne({ _id: product._id }, { image: imageUrl });
    console.log(`✓ ${product.name} → image set`);
  }

  console.log('Done!');
  await mongoose.disconnect();
}

run().catch(console.error);
