#!/bin/bash

# Check if project name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <project-name>"
  exit 1
fi

PROJECT_NAME=$1

# Create project directory
echo "🚀 Creating project: $PROJECT_NAME..."
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

# Initialize npm
echo "📦 Initializing npm..."
npm init -y > /dev/null

# Set type to module for ESM
npm pkg set type="module"

# Add scripts
npm pkg set scripts.start="node src/index.js"
npm pkg set scripts.dev="nodemon src/index.js"

# Install dependencies
echo "📥 Installing dependencies (express, dotenv, cors, morgan, helmet)..."
npm install express dotenv cors morgan helmet > /dev/null

# Install dev dependencies
echo "📥 Installing dev dependencies (nodemon)..."
npm install --save-dev nodemon > /dev/null

# Create directory structure
echo "📂 Creating directory structure..."
mkdir -p src/controllers src/routes src/models src/middleware src/config

# Create .env
cat <<EOF > .env
PORT=3000
NODE_ENV=development
EOF

# Create .gitignore
cat <<EOF > .gitignore
node_modules/
.env
.DS_Store
dist/
logs/
EOF

# Create src/app.js
cat <<EOF > src/app.js
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';
import router from './routes/index.js';

const app = express();

// Global Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Routes
app.use('/api', router);

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
  });
});

export default app;
EOF

# Create src/index.js
cat <<EOF > src/index.js
import 'dotenv/config';
import app from './app.js';

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server is running on port \${PORT} in \${process.env.NODE_ENV} mode`);
});
EOF

# Create src/routes/index.js
cat <<EOF > src/routes/index.js
import { Router } from 'express';

const router = Router();

router.get('/', (req, res) => {
  res.json({ message: 'Welcome to the API' });
});

export default router;
EOF

echo "✅ Project '$PROJECT_NAME' created successfully!"
echo "👉 To start: cd $PROJECT_NAME && npm run dev"
