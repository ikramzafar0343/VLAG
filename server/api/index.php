<?php
/**
 * VLagIt API - Main Entry Point
 * 
 * This file handles all API requests for the VLagIt platform
 * Deploy to: public_html/api/
 * 
 * Required PHP version: 7.4+
 * Required extensions: json, curl, pdo (if using database)
 */

// Set headers for CORS and JSON responses
header('Content-Type: application/json; charset=utf-8');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    require_once __DIR__ . '/config.php';
    require_once __DIR__ . '/utils.php';
    setCorsHeaders();
    http_response_code(200);
    exit();
}

// Error reporting (disable in production)
error_reporting(E_ALL);
ini_set('display_errors', 0); // Set to 0 in production

// Load configuration
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/utils.php';

setCorsHeaders();

// Initialize response
$response = [
    'success' => false,
    'message' => '',
    'data' => null,
    'timestamp' => time()
];

try {
    // Get request method and path
    $method = $_SERVER['REQUEST_METHOD'];
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $pathParts = explode('/', trim($path, '/'));
    
    // Remove 'api' from path parts if present
    if (isset($pathParts[0]) && $pathParts[0] === 'api') {
        array_shift($pathParts);
    }
    
    $endpoint = $pathParts[0] ?? '';
    
    // Route to appropriate handler
    switch ($endpoint) {
        case 'health':
            $response = handleHealthCheck();
            break;
            
        case 'verified':
            $response = handleVerifiedBadge($method, $pathParts);
            break;
            
        case 'report':
            $response = handleReport($method, $pathParts);
            break;
            
        case 'analytics':
            $response = handleAnalytics($method, $pathParts);
            break;

        case 'upload':
            $response = handleUpload($method, $pathParts);
            break;
            
        default:
            http_response_code(404);
            $response['message'] = 'Endpoint not found';
            break;
    }
    
} catch (Exception $e) {
    http_response_code(500);
    $response['message'] = 'Internal server error';
    $response['error'] = API_DEBUG ? $e->getMessage() : 'An error occurred';
    
    // Log error
    error_log('VLagIt API Error: ' . $e->getMessage());
}

// Return JSON response
echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
exit();

/**
 * Health check endpoint
 */
function handleHealthCheck() {
    return [
        'success' => true,
        'message' => 'VLagIt API is running',
        'data' => [
            'version' => API_VERSION,
            'timestamp' => time(),
            'server' => $_SERVER['SERVER_NAME'] ?? 'unknown'
        ]
    ];
}

/**
 * Handle verified badge requests
 * GET /api/verified/{userId} - Check if user is verified
 * POST /api/verified - Admin: Set verified status (requires auth)
 */
function handleVerifiedBadge($method, $pathParts) {
    global $response;
    
    if ($method === 'GET') {
        $userId = $pathParts[1] ?? null;
        
        if (!$userId) {
            http_response_code(400);
            return [
                'success' => false,
                'message' => 'User ID is required'
            ];
        }
        
        // Check if user is verified
        // TODO: Implement database check or Firebase Admin SDK
        $isVerified = checkUserVerified($userId);
        
        return [
            'success' => true,
            'message' => 'Verification status retrieved',
            'data' => [
                'userId' => $userId,
                'verified' => $isVerified
            ]
        ];
    }
    
    if ($method === 'POST') {
        // Admin endpoint - requires authentication
        // TODO: Implement admin authentication
        $input = json_decode(file_get_contents('php://input'), true);
        $userId = $input['userId'] ?? null;
        $verified = $input['verified'] ?? false;
        
        if (!$userId) {
            http_response_code(400);
            return [
                'success' => false,
                'message' => 'User ID is required'
            ];
        }
        
        // TODO: Implement database update
        setUserVerified($userId, $verified);
        
        return [
            'success' => true,
            'message' => 'Verification status updated',
            'data' => [
                'userId' => $userId,
                'verified' => $verified
            ]
        ];
    }
    
    http_response_code(405);
    return [
        'success' => false,
        'message' => 'Method not allowed'
    ];
}

/**
 * Handle report requests
 * POST /api/report - Submit a report
 * GET /api/report/{reportId} - Get report details (admin)
 */
function handleReport($method, $pathParts) {
    if ($method === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        
        $required = ['userId', 'reportedUserId', 'reason'];
        foreach ($required as $field) {
            if (!isset($input[$field])) {
                http_response_code(400);
                return [
                    'success' => false,
                    'message' => "Field '$field' is required"
                ];
            }
        }
        
        // Create report
        $reportId = createReport([
            'userId' => $input['userId'],
            'reportedUserId' => $input['reportedUserId'],
            'reason' => $input['reason'],
            'description' => $input['description'] ?? '',
            'timestamp' => time()
        ]);
        
        return [
            'success' => true,
            'message' => 'Report submitted successfully',
            'data' => [
                'reportId' => $reportId
            ]
        ];
    }
    
    http_response_code(405);
    return [
        'success' => false,
        'message' => 'Method not allowed'
    ];
}

/**
 * Handle analytics requests
 * GET /api/analytics/{userId} - Get user analytics
 */
function handleAnalytics($method, $pathParts) {
    if ($method === 'GET') {
        $userId = $pathParts[1] ?? null;
        
        if (!$userId) {
            http_response_code(400);
            return [
                'success' => false,
                'message' => 'User ID is required'
            ];
        }
        
        // Get analytics data
        // TODO: Implement analytics retrieval from Firebase or database
        $analytics = getUserAnalytics($userId);
        
        return [
            'success' => true,
            'message' => 'Analytics retrieved',
            'data' => $analytics
        ];
    }
    
    http_response_code(405);
    return [
        'success' => false,
        'message' => 'Method not allowed'
    ];
}

function handleUpload($method, $pathParts) {
    requireRateLimit($_SERVER['REMOTE_ADDR'] ?? 'unknown');

    if ($method !== 'POST') {
        http_response_code(405);
        return [
            'success' => false,
            'message' => 'Method not allowed'
        ];
    }

    $action = $pathParts[1] ?? '';
    if ($action !== 'profile-image') {
        http_response_code(404);
        return [
            'success' => false,
            'message' => 'Endpoint not found'
        ];
    }

    $user = requireAuthUser();
    $uid = $user['localId'] ?? null;
    if (!$uid) {
        http_response_code(401);
        return [
            'success' => false,
            'message' => 'Unauthorized'
        ];
    }

    if (!isset($_FILES['file']) || !is_array($_FILES['file'])) {
        http_response_code(400);
        return [
            'success' => false,
            'message' => 'Missing file'
        ];
    }

    $file = $_FILES['file'];
    if (($file['error'] ?? UPLOAD_ERR_OK) !== UPLOAD_ERR_OK) {
        http_response_code(400);
        return [
            'success' => false,
            'message' => 'Upload failed'
        ];
    }

    $maxBytes = defined('UPLOAD_MAX_BYTES') ? UPLOAD_MAX_BYTES : 5242880;
    if (($file['size'] ?? 0) <= 0 || ($file['size'] ?? 0) > $maxBytes) {
        http_response_code(400);
        return [
            'success' => false,
            'message' => 'File too large'
        ];
    }

    $tmpPath = $file['tmp_name'] ?? null;
    if (!$tmpPath || !file_exists($tmpPath)) {
        http_response_code(400);
        return [
            'success' => false,
            'message' => 'Invalid upload'
        ];
    }

    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime = finfo_file($finfo, $tmpPath);
    finfo_close($finfo);

    $allowed = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp'
    ];

    if (!isset($allowed[$mime])) {
        http_response_code(400);
        return [
            'success' => false,
            'message' => 'Unsupported file type'
        ];
    }

    $ext = $allowed[$mime];
    $baseDir = defined('UPLOAD_BASE_DIR') ? UPLOAD_BASE_DIR : (__DIR__ . '/uploads');
    $profilesDir = rtrim($baseDir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . 'profiles';

    if (!is_dir($profilesDir)) {
        mkdir($profilesDir, 0755, true);
    }

    $random = bin2hex(random_bytes(8));
    $filename = 'p_' . preg_replace('/[^A-Za-z0-9_-]/', '_', $uid) . '_' . time() . '_' . $random . '.' . $ext;
    $destPath = $profilesDir . DIRECTORY_SEPARATOR . $filename;

    if (!move_uploaded_file($tmpPath, $destPath)) {
        http_response_code(500);
        return [
            'success' => false,
            'message' => 'Failed to store file'
        ];
    }

    chmod($destPath, 0644);

    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? ($_SERVER['SERVER_NAME'] ?? 'localhost');
    $baseUrl = defined('UPLOAD_BASE_URL') && UPLOAD_BASE_URL ? rtrim(UPLOAD_BASE_URL, '/') : ($scheme . '://' . $host . '/uploads');
    $publicUrl = $baseUrl . '/profiles/' . $filename;

    return [
        'success' => true,
        'message' => 'Uploaded',
        'data' => [
            'uid' => $uid,
            'filename' => $filename,
            'mime' => $mime,
            'size' => $file['size'] ?? null,
            'url' => $publicUrl
        ]
    ];
}
