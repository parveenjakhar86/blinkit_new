// Script to create an admin user in MongoDB
const mongoose = require('mongoose');
const Admin = require('./model/user/admin');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://parveenjakhar86_db_user:YqQ9oa4gJsdyZpuJ@ac-qi8azss-shard-00-00.e4lktzo.mongodb.net:27017,ac-qi8azss-shard-00-01.e4lktzo.mongodb.net:27017,ac-qi8azss-shard-00-02.e4lktzo.mongodb.net:27017/blinkit-new?ssl=true&authSource=admin&replicaSet=atlas-6ff2rs-shard-0&retryWrites=true&w=majority';

async function createAdmin() {
  await mongoose.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true });
  const exists = await Admin.findOne({ email: 'admin@example.com' });
  if (exists) {
    console.log('Admin already exists');
    process.exit(0);
  }
  const admin = new Admin({ email: 'admin@example.com', password: 'admin' });
  await admin.save();
  console.log('Admin created in admins collection');
  process.exit(0);
}

createAdmin().catch(err => { console.error(err); process.exit(1); });
