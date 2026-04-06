const mongoose = require('mongoose');
require('dotenv').config();

const User = require('./model/user/user');
const Customer = require('./model/Customer');

const DEFAULT_MONGO_URI =
  'mongodb://parveenjakhar86_db_user:YqQ9oa4gJsdyZpuJ@ac-qi8azss-shard-00-00.e4lktzo.mongodb.net:27017,ac-qi8azss-shard-00-01.e4lktzo.mongodb.net:27017,ac-qi8azss-shard-00-02.e4lktzo.mongodb.net:27017/blinkit-new?ssl=true&authSource=admin&replicaSet=atlas-6ff2rs-shard-0&retryWrites=true&w=majority';

const MONGO_URI = process.env.MONGO_URI || DEFAULT_MONGO_URI;

async function migrateCustomers() {
  await mongoose.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true });

  const userCustomers = await User.find({ role: 'customer' });

  let inserted = 0;
  let updated = 0;

  for (const user of userCustomers) {
    const payload = {
      name: user.username || user.email,
      email: user.email,
      phone: '',
      address: '',
      password: user.password || 'customer123',
      status: user.status || 'active'
    };

    const existing = await Customer.findOne({ email: payload.email });
    if (existing) {
      await Customer.findByIdAndUpdate(existing._id, payload, { new: true });
      updated += 1;
    } else {
      await Customer.create(payload);
      inserted += 1;
    }
  }

  console.log(`Customer migration complete. Found ${userCustomers.length} in users; inserted ${inserted}, updated ${updated}.`);

  await mongoose.disconnect();
}

migrateCustomers().catch(async (error) => {
  console.error('Migration failed:', error.message);
  try {
    await mongoose.disconnect();
  } catch (_) {}
  process.exit(1);
});
