/**
 * Cloud Functions for VLag - Dynamic Meta Tags for Rich Link Previews
 * 
 * This function serves HTML with dynamic Open Graph meta tags for social media crawlers.
 * Social media platforms (WhatsApp, Facebook, Twitter) don't execute JavaScript,
 * so we need server-side rendering for proper rich link previews.
 * 
 * Setup Instructions:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Initialize functions: firebase init functions
 * 3. Deploy: firebase deploy --only functions
 * 4. Update firebase.json to add rewrite rules (see below)
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Serves HTML with dynamic meta tags for profile pages
 * This enables rich link previews similar to Linkfly
 */
exports.serveProfilePage = functions.https.onRequest(async (req, res) => {
  const path = req.path;
  const profileCodeMatch = path.match(/^\/([A-Za-z0-9]{5})$/);
  
  if (!profileCodeMatch) {
    // Not a profile URL, serve default Flutter app
    return res.redirect('/');
  }
  
  const profileCode = profileCodeMatch[1];
  
  try {
    // Fetch profile data from Firestore
    const doc = await admin.firestore().collection('users').doc(profileCode).get();
    
    if (!doc.exists) {
      // Profile not found, serve default
      return res.redirect('/');
    }
    
    const data = doc.data();
    const nickname = data.nickname || 'VLag Profile';
    const subtitle = data.subtitle || 'Visit my VLag profile to see all my links in one place';
    const profileImageUrl = data.dpUrl || 'https://vlagit.com/static/vlag-meta.png';
    const profileUrl = `https://vlagit.com/${profileCode}`;
    const title = `${nickname} - VLag Profile`;
    
    // Generate HTML with dynamic meta tags
    const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <!-- Primary Meta Tags -->
  <title>${title}</title>
  <meta name="title" content="${title}">
  <meta name="description" content="${subtitle}">
  
  <!-- Open Graph / Facebook -->
  <meta property="og:type" content="website">
  <meta property="og:url" content="${profileUrl}">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${subtitle}">
  <meta property="og:image" content="${profileImageUrl}">
  <meta property="og:site_name" content="VLag">
  
  <!-- Twitter -->
  <meta property="twitter:card" content="summary_large_image">
  <meta property="twitter:url" content="${profileUrl}">
  <meta property="twitter:title" content="${title}">
  <meta property="twitter:description" content="${subtitle}">
  <meta property="twitter:image" content="${profileImageUrl}">
  
  <!-- Redirect to Flutter app after meta tags are read by crawlers -->
  <script>
    // Redirect to main app after a short delay (for crawlers that execute JS)
    setTimeout(function() {
      window.location.href = '/';
    }, 100);
  </script>
</head>
<body>
  <p>Loading profile...</p>
  <script>
    // Immediate redirect for browsers
    window.location.href = '/';
  </script>
</body>
</html>`;
    
    res.set('Cache-Control', 'public, max-age=3600, s-maxage=3600');
    res.send(html);
  } catch (error) {
    console.error('Error serving profile page:', error);
    res.redirect('/');
  }
});
