// Script to migrate all admins from 'admins' collection to 'users' collection
const mongoose = require('mongoose');
const Admin = require('./model/user/admin');
const User = require('./model/user/user');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://parveenjakhar86_db_user:YqQ9oa4gJsdyZpuJ@ac-qi8azss-shard-00-00.e4lktzo.mongodb.net:27017,ac-qi8azss-shard-00-01.e4lktzo.mongodb.net:27017,ac-qi8azss-shard-00-02.e4lktzo.mongodb.net:27017/blinkit-new?ssl=true&authSource=admin&replicaSet=atlas-6ff2rs-shard-0&retryWrites=true&w=majority';

async function migrateAdmins() {
  await mongoose.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true });
  const admins = await Admin.find();
  for (const admin of admins) {
    // Check if already exists in users
    const exists = await User.findOne({ email: admin.email });
    if (!exists) {
      await User.create({
        email: admin.email,
        password: admin.password,
        role: 'admin',
        status: 'active'
      });
      console.log(`Migrated admin: ${admin.email}`);
    } else {
      console.log(`Already exists in users: ${admin.email}`);
    }
  }
  console.log('Migration complete.');
  process.exit(0);
}

migrateAdmins().catch(err => { console.error(err); process.exit(1); });
