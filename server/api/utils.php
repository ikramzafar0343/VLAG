<?php
/**
 * VLagIt API Utility Functions
 */

function getRequestHeader($name) {
    $key = 'HTTP_' . strtoupper(str_replace('-', '_', $name));
    return $_SERVER[$key] ?? null;
}

function getBearerToken() {
    $auth = getRequestHeader('Authorization');
    if (!$auth) {
        return null;
    }
    if (stripos($auth, 'Bearer ') !== 0) {
        return null;
    }
    return trim(substr($auth, 7));
}

function getCorsOrigin() {
    $origin = getRequestHeader('Origin');
    if (!$origin) {
        return '*';
    }
    $allowed = array_map('trim', explode(',', ALLOWED_ORIGINS));
    if (in_array($origin, $allowed, true)) {
        return $origin;
    }
    return '*';
}

function setCorsHeaders() {
    header('Access-Control-Allow-Origin: ' . getCorsOrigin());
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-API-Key, X-Admin-Secret');
}

function requireRateLimit($identifier) {
    if (!checkRateLimit($identifier)) {
        http_response_code(429);
        echo json_encode([
            'success' => false,
            'message' => 'Rate limit exceeded',
            'data' => null,
            'timestamp' => time()
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit();
    }
}

function verifyFirebaseIdToken($idToken) {
    if (!$idToken || !defined('FIREBASE_WEB_API_KEY') || !FIREBASE_WEB_API_KEY) {
        return null;
    }

    $url = 'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=' . urlencode(FIREBASE_WEB_API_KEY);
    $payload = json_encode(['idToken' => $idToken]);

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    $body = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($status !== 200 || !$body) {
        return null;
    }

    $data = json_decode($body, true);
    $users = $data['users'] ?? null;
    if (!$users || !is_array($users) || !isset($users[0]['localId'])) {
        return null;
    }
    return $users[0];
}

function requireAuthUser() {
    $adminSecret = getRequestHeader('X-Admin-Secret');
    if ($adminSecret && validateAdminSecret($adminSecret)) {
        return ['localId' => 'admin'];
    }

    $apiKey = getRequestHeader('X-API-Key');
    if ($apiKey && validateApiKey($apiKey)) {
        return ['localId' => 'api_key'];
    }

    $token = getBearerToken();
    $user = verifyFirebaseIdToken($token);
    if ($user) {
        return $user;
    }

    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Unauthorized',
        'data' => null,
        'timestamp' => time()
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit();
}

/**
 * Check if user is verified
 * TODO: Implement Firebase Admin SDK or database query
 */
function checkUserVerified($userId) {
    // Placeholder - implement with Firebase Admin SDK or database
    // Example: Query Firestore for user document and check 'verified' field
    return false;
}

/**
 * Set user verified status
 * TODO: Implement Firebase Admin SDK or database update
 */
function setUserVerified($userId, $verified) {
    // Placeholder - implement with Firebase Admin SDK or database
    // Example: Update Firestore user document
    return true;
}

/**
 * Create a report
 * TODO: Implement database storage or Firebase
 */
function createReport($reportData) {
    // Placeholder - implement database storage
    // Generate unique report ID
    $reportId = 'RPT' . time() . rand(1000, 9999);
    
    // TODO: Store in database or Firebase
    // Example: Firestore collection 'reports'
    
    return $reportId;
}

/**
 * Get user analytics
 * TODO: Implement analytics retrieval from Firebase or database
 */
function getUserAnalytics($userId) {
    // Placeholder - implement analytics retrieval
    return [
        'userId' => $userId,
        'totalViews' => 0,
        'totalClicks' => 0,
        'topLinks' => [],
        'recentActivity' => []
    ];
}

/**
 * Validate API key
 */
function validateApiKey($apiKey) {
    return $apiKey === API_KEY;
}

/**
 * Validate admin secret
 */
function validateAdminSecret($secret) {
    return $secret === ADMIN_SECRET;
}

/**
 * Rate limiting check
 */
function checkRateLimit($identifier) {
    // Simple file-based rate limiting
    // In production, use Redis or database
    $rateLimitFile = __DIR__ . '/cache/rate_limit_' . md5($identifier) . '.json';
    
    if (file_exists($rateLimitFile)) {
        $data = json_decode(file_get_contents($rateLimitFile), true);
        $requests = $data['requests'] ?? 0;
        $windowStart = $data['windowStart'] ?? 0;
        
        if (time() - $windowStart > RATE_LIMIT_WINDOW) {
            // Reset window
            $data = ['requests' => 1, 'windowStart' => time()];
        } else {
            $data['requests']++;
        }
    } else {
        $data = ['requests' => 1, 'windowStart' => time()];
    }
    
    // Ensure cache directory exists
    $cacheDir = __DIR__ . '/cache';
    if (!is_dir($cacheDir)) {
        mkdir($cacheDir, 0755, true);
    }
    
    file_put_contents($rateLimitFile, json_encode($data));
    
    return $data['requests'] <= RATE_LIMIT_REQUESTS;
}

/**
 * Log API request
 */
function logApiRequest($endpoint, $method, $data = []) {
    if (!API_DEBUG) {
        return;
    }
    
    $logFile = __DIR__ . '/logs/api_' . date('Y-m-d') . '.log';
    $logDir = dirname($logFile);
    
    if (!is_dir($logDir)) {
        mkdir($logDir, 0755, true);
    }
    
    $logEntry = [
        'timestamp' => date('Y-m-d H:i:s'),
        'endpoint' => $endpoint,
        'method' => $method,
        'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
        'data' => $data
    ];
    
    file_put_contents($logFile, json_encode($logEntry) . "\n", FILE_APPEND);
}
