// Add many Blinkit-like products with categories and images.
require('dotenv').config();
const mongoose = require('mongoose');
const Product = require('./model/product/product');

const products = [
  { name: 'Amul Taaza Milk 1L', category: 'Dairy & Breakfast', price: 64, stock: 120, image: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=500&q=80', description: 'Fresh toned milk, 1 litre pack' },
  { name: 'Farm Eggs (12 pcs)', category: 'Dairy & Breakfast', price: 98, stock: 90, image: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=500&q=80', description: 'Farm fresh eggs tray' },
  { name: 'Whole Wheat Bread', category: 'Dairy & Breakfast', price: 48, stock: 80, image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80', description: 'Soft whole wheat bread loaf' },

  { name: 'Banana Robusta 1 Dozen', category: 'Fruits & Vegetables', price: 52, stock: 150, image: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500&q=80', description: 'Fresh ripe bananas' },
  { name: 'Tomato Hybrid 1kg', category: 'Fruits & Vegetables', price: 36, stock: 140, image: 'https://images.unsplash.com/photo-1546470427-e26264be0b2d?w=500&q=80', description: 'Red juicy tomatoes' },
  { name: 'Onion 1kg', category: 'Fruits & Vegetables', price: 42, stock: 130, image: 'https://images.unsplash.com/photo-1508747703725-719777637510?w=500&q=80', description: 'Fresh onions for daily cooking' },
  { name: 'Potato 1kg', category: 'Fruits & Vegetables', price: 30, stock: 160, image: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500&q=80', description: 'Clean and sorted potatoes' },

  { name: 'Basmati Rice 5kg', category: 'Atta, Rice & Dal', price: 549, stock: 70, image: 'https://images.unsplash.com/photo-1536304929831-ee1ca9d44906?w=500&q=80', description: 'Premium long grain basmati rice' },
  { name: 'Aashirvaad Atta 5kg', category: 'Atta, Rice & Dal', price: 299, stock: 85, image: 'https://images.unsplash.com/photo-1627485937980-221c88ac04f9?w=500&q=80', description: 'Whole wheat flour chakki atta' },
  { name: 'Toor Dal 1kg', category: 'Atta, Rice & Dal', price: 168, stock: 75, image: 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=500&q=80', description: 'Unpolished toor/arhar dal' },

  { name: 'Coca Cola 750ml', category: 'Cold Drinks & Juices', price: 40, stock: 110, image: 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=500&q=80', description: 'Chilled soft drink bottle' },
  { name: 'Real Mixed Fruit Juice 1L', category: 'Cold Drinks & Juices', price: 125, stock: 95, image: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=500&q=80', description: 'Mixed fruit drink' },

  { name: 'Lay\'s Magic Masala 52g', category: 'Munchies', price: 20, stock: 180, image: 'https://images.unsplash.com/photo-1585238342024-78d387f4a707?w=500&q=80', description: 'Crispy potato chips' },
  { name: 'Hide & Seek Biscuits', category: 'Munchies', price: 35, stock: 150, image: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=500&q=80', description: 'Choco chip cookies' },

  { name: 'MamyPoko Pants L 34', category: 'Baby Care', price: 499, stock: 65, image: 'https://images.unsplash.com/photo-1584515933487-779824d29309?w=500&q=80', description: 'Baby diaper pants large size' },
  { name: 'Johnson Baby Lotion 200ml', category: 'Baby Care', price: 190, stock: 70, image: 'https://images.unsplash.com/photo-1607619056574-7b8d3ee536b2?w=500&q=80', description: 'Gentle baby body lotion' },

  { name: 'Lakme Face Wash 100g', category: 'Beauty', price: 245, stock: 80, image: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=500&q=80', description: 'Daily fresh face wash' },
  { name: 'Nivea Body Lotion 400ml', category: 'Beauty', price: 325, stock: 72, image: 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=500&q=80', description: 'Nourishing body lotion' },

  { name: 'Surf Excel Matic 2kg', category: 'Household', price: 459, stock: 88, image: 'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=500&q=80', description: 'Laundry detergent powder' },
  { name: 'Harpic Toilet Cleaner 1L', category: 'Household', price: 210, stock: 92, image: 'https://images.unsplash.com/photo-1583947581924-a6d7f0f4c7ec?w=500&q=80', description: 'Disinfectant toilet cleaner' },

  { name: 'Boat Airdopes 141', category: 'Electronics', price: 1199, stock: 45, image: 'https://images.unsplash.com/photo-1588423771073-b8903fbb85b5?w=500&q=80', description: 'Wireless bluetooth earbuds' },
  { name: 'Portronics Power Bank 10000mAh', category: 'Electronics', price: 999, stock: 50, image: 'https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=500&q=80', description: 'Fast charging power bank' },

  { name: 'Protein Bar Chocolate', category: 'Summer', price: 59, stock: 100, image: 'https://images.unsplash.com/photo-1606312619344-8f2bf0f82f2f?w=500&q=80', description: 'High protein snack bar' },
  { name: 'Electrolyte Drink Orange', category: 'Summer', price: 35, stock: 130, image: 'https://images.unsplash.com/photo-1622543925917-763c34d1a86e?w=500&q=80', description: 'Hydration drink for summer' }
];

async function run() {
  const uri = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://localhost:27017/blinkit';
  await mongoose.connect(uri);
  console.log('Connected to MongoDB');

  let inserted = 0;
  let updated = 0;

  for (const p of products) {
    const existing = await Product.findOne({ name: p.name });
    if (!existing) {
      await Product.create(p);
      inserted += 1;
      console.log(`+ Added: ${p.name}`);
    } else {
      await Product.updateOne({ _id: existing._id }, { $set: p });
      updated += 1;
      console.log(`~ Updated: ${p.name}`);
    }
  }

  const total = await Product.countDocuments();
  console.log(`Done. Inserted ${inserted}, Updated ${updated}, Total products ${total}`);

  await mongoose.disconnect();
}

run().catch(async (err) => {
  console.error('Failed to add products:', err.message);
  await mongoose.disconnect();
  process.exit(1);
});
