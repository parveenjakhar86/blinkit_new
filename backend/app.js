// Main Express app setup

const express = require('express');
const mongoose = require('mongoose');
const routes = require('./route');
const cors = require('cors');
const app = express();

require('dotenv').config();




console.log('JWT_SECRET:', process.env.JWT_SECRET); // DEBUG: Check if .env is loaded

// Middleware to parse JSON bodies
app.use(express.json({ limit: '5mb' }));
app.use(cors());

// Mount all API routes under /api
app.use('/api', routes);

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

const HOST = process.env.HOST || '0.0.0.0';
const PORT = process.env.PORT || 5007;

// Connect to MongoDB and start server
mongoose.connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => {
    app.listen(PORT, HOST, () => console.log(`Server running on http://${HOST}:${PORT}`));
  })
  .catch(err => console.error(err));
