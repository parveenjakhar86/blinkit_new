// Main Express app setup

const express = require('express');
const mongoose = require('mongoose');
const routes = require('./route');
const cors = require('cors');
const path = require('path');
const app = express();

require('dotenv').config();

const frontendBuildPath = path.join(__dirname, '..', 'frontend', 'build');

// Middleware to parse JSON bodies
app.use(express.json({ limit: '5mb' }));
app.use(cors());
app.use(express.static(frontendBuildPath));

// Mount all API routes under /api
app.use('/api', routes);

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.get('/', (req, res) => {
  res.sendFile(path.join(frontendBuildPath, 'index.html'));
});

app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api')) {
    return next();
  }

  return res.sendFile(path.join(frontendBuildPath, 'index.html'));
});

const HOST = process.env.HOST || '0.0.0.0';
const PORT = process.env.PORT || 5007;
const MONGO_URI = process.env.MONGODB_URI || process.env.MONGO_URI;

// Connect to MongoDB and start server
mongoose.connect(MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  serverSelectionTimeoutMS: 15000,
})
  .then(() => {
    app.listen(PORT, HOST, () => console.log(`Server running on http://${HOST}:${PORT}`));
  })
  .catch(err => {
    if (!MONGO_URI) {
      console.error('MongoDB connection failed: MONGODB_URI or MONGO_URI is not set.');
    } else {
      console.error('MongoDB connection failed. Check Atlas Network Access and the connection string configured on Render.');
      console.error(err);
    }

    process.exit(1);
  });
