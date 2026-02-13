<?php
/**
 * VLagIt API Configuration Template
 * 
 * Copy this file to config.php and update with your actual values.
 * 
 * ⚠️ NEVER commit config.php to Git
 * ✅ This template file is safe to commit
 */

// API Version
define('API_VERSION', '1.0.0');

// Debug mode (set to false in production)
define('API_DEBUG', false);

// Firebase Admin SDK Configuration
// Download service account key from Firebase Console
// Place it in: server/api/firebase-service-account.json
define('FIREBASE_PROJECT_ID', 'your-firebase-project-id');
define('FIREBASE_SERVICE_ACCOUNT_PATH', __DIR__ . '/firebase-service-account.json');

// Database Configuration (if using MySQL/PostgreSQL)
// For now, we'll use Firebase Firestore via Admin SDK
define('DB_HOST', 'localhost');
define('DB_NAME', 'vlagit_db');
define('DB_USER', 'your_db_user');
define('DB_PASS', 'your_db_password');

// Security
// ⚠️ Generate strong random keys:
// Use: openssl rand -hex 32
define('API_KEY', 'your-secret-api-key-here'); // Change this!
define('ADMIN_SECRET', 'your-admin-secret-here'); // Change this!

// Rate limiting
define('RATE_LIMIT_REQUESTS', 100); // Requests per hour
define('RATE_LIMIT_WINDOW', 3600); // 1 hour in seconds

// CORS allowed origins (comma-separated)
define('ALLOWED_ORIGINS', 'https://vlagit.com,https://www.vlagit.com');

// Timezone
date_default_timezone_set('UTC');
