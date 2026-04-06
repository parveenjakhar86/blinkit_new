const mongoose = require('mongoose');
require('dotenv').config();

const Order = require('./model/Order');
const Product = require('./model/Product');
const User = require('./model/user/user');

const DEFAULT_MONGO_URI =
  'mongodb://parveenjakhar86_db_user:YqQ9oa4gJsdyZpuJ@ac-qi8azss-shard-00-00.e4lktzo.mongodb.net:27017,ac-qi8azss-shard-00-01.e4lktzo.mongodb.net:27017,ac-qi8azss-shard-00-02.e4lktzo.mongodb.net:27017/blinkit-new?ssl=true&authSource=admin&replicaSet=atlas-6ff2rs-shard-0&retryWrites=true&w=majority';

const MONGO_URI = process.env.MONGO_URI || DEFAULT_MONGO_URI;

const seedProducts = [
  { name: 'Fresh Bananas', price: 40, stock: 120, description: '1 dozen bananas' },
  { name: 'Milk 1L', price: 62, stock: 80, description: 'Toned milk 1 litre pack' },
  { name: 'Brown Bread', price: 45, stock: 60, description: 'Whole wheat bread loaf' },
  { name: 'Basmati Rice 5kg', price: 520, stock: 35, description: 'Premium basmati rice' },
  { name: 'Organic Eggs (12)', price: 95, stock: 70, description: 'Farm fresh eggs pack' },
  { name: 'Tomatoes 1kg', price: 32, stock: 90, description: 'Fresh red tomatoes' }
];

const seedCustomers = [
  { email: 'customer1@example.com', username: 'customer1', password: 'customer123' },
  { email: 'customer2@example.com', username: 'customer2', password: 'customer123' },
  { email: 'customer3@example.com', username: 'customer3', password: 'customer123' },
  { email: 'customer4@example.com', username: 'customer4', password: 'customer123' }
];

const statuses = ['pending', 'processing', 'completed', 'cancelled'];

async function ensureProducts() {
  const products = [];
  for (const data of seedProducts) {
    let product = await Product.findOne({ name: data.name });
    if (!product) {
      product = await Product.create(data);
    }
    products.push(product);
  }
  return products;
}

async function ensureCustomers() {
  const users = [];
  for (const data of seedCustomers) {
    let user = await User.findOne({ email: data.email });
    if (!user) {
      user = await User.create({
        ...data,
        role: 'customer',
        status: 'active'
      });
    }
    users.push(user);
  }
  return users;
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pickRandom(array) {
  return array[randomInt(0, array.length - 1)];
}

function buildOrderProducts(products) {
  const itemCount = randomInt(1, 3);
  const selectedIndexes = new Set();
  while (selectedIndexes.size < itemCount) {
    selectedIndexes.add(randomInt(0, products.length - 1));
  }

  return Array.from(selectedIndexes).map((index) => ({
    product: products[index]._id,
    quantity: randomInt(1, 4)
  }));
}

async function seedOrders() {
  await mongoose.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true });

  const existingOrderCount = await Order.countDocuments();
  if (existingOrderCount > 0) {
    console.log(`Skipping seed. Orders already exist (${existingOrderCount}).`);
    await mongoose.disconnect();
    return;
  }

  const products = await ensureProducts();
  const customers = await ensureCustomers();

  const now = new Date();
  const orders = Array.from({ length: 10 }).map((_, index) => ({
    user: pickRandom(customers)._id,
    products: buildOrderProducts(products),
    status: statuses[index % statuses.length],
    createdAt: new Date(now.getTime() - index * 24 * 60 * 60 * 1000)
  }));

  await Order.insertMany(orders);
  console.log('Seeded 10 orders successfully.');

  await mongoose.disconnect();
}

seedOrders().catch(async (error) => {
  console.error('Failed to seed orders:', error.message);
  await mongoose.disconnect();
  process.exit(1);
});
