# Troubleshooting: Domain Still Shows Old Site

## 🔍 Problem
You've uploaded Flutter web files to `public_html/` but `https://vlagit.com` still shows the StenMe WordPress site.

## 🎯 Most Likely Causes

### Issue 1: Domain Points to Subdirectory
The domain `vlagit.com` might be configured as an **addon domain** pointing to `public_html/vlagit.com/` instead of `public_html/`.

**Solution:**
1. Check if `vlagit.com` folder exists in `public_html/`
2. If yes, upload Flutter files to `public_html/vlagit.com/` instead
3. OR reconfigure the domain to point to `public_html/` root

### Issue 2: WordPress index.php Takes Precedence
WordPress `index.php` might be loading before Flutter `index.html`.

**Solution:**
1. Rename or remove WordPress `index.php` in `public_html/`
2. Ensure Flutter `index.html` is in the root
3. Check `.htaccess` is configured correctly

### Issue 3: Wrong Directory Structure
Files might be in a subdirectory instead of root.

**Solution:**
- Flutter files should be directly in `public_html/` (or `public_html/vlagit.com/` if addon domain)

---

## 🔧 Step-by-Step Fix

### Step 1: Check Domain Configuration

In cPanel:
1. Search for: `Addon Domains` or `Subdomains`
2. Check where `vlagit.com` is configured
3. Note the document root path

**Common scenarios:**
- **Main domain:** Points to `public_html/`
- **Addon domain:** Points to `public_html/vlagit.com/` or similar

### Step 2: Verify File Locations

**If domain points to `public_html/`:**
- Flutter files should be in `public_html/`
- `index.html` should be in `public_html/` root

**If domain points to `public_html/vlagit.com/`:**
- Flutter files should be in `public_html/vlagit.com/`
- `index.html` should be in `public_html/vlagit.com/` root

### Step 3: Check for WordPress Files

If WordPress is installed:
1. **Option A:** Remove WordPress files (if not needed)
   - Delete `wp-admin/`, `wp-content/`, `wp-includes/`
   - Remove `index.php` (WordPress)
   - Remove `wp-config.php` (if exists)

2. **Option B:** Keep WordPress, prioritize Flutter
   - Rename WordPress `index.php` to `index.php.backup`
   - Ensure Flutter `index.html` is in root
   - Update `.htaccess` to prioritize HTML

### Step 4: Verify .htaccess

Ensure `.htaccess` in root contains:
```apache
# Handle Flutter Web routing
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_URI} !^/api/
RewriteRule ^(.*)$ /index.html [L]
```

### Step 5: Clear Browser Cache

1. Hard refresh: `Ctrl + Shift + R` (Windows) or `Cmd + Shift + R` (Mac)
2. Or clear browser cache completely
3. Try incognito/private mode

---

## 📋 Quick Diagnostic Checklist

Check these in cPanel File Manager:

- [ ] Is `index.html` in the correct root directory?
- [ ] Is `main.dart.js` in the same directory as `index.html`?
- [ ] Are `assets/`, `icons/`, `canvaskit/` folders present?
- [ ] Is `.htaccess` in the root directory?
- [ ] Is there a WordPress `index.php` that might be interfering?
- [ ] Where does the domain actually point? (Check Addon Domains)

---

## 🎯 Most Common Solution

Based on your screenshot showing `vlagit.com` folder in `public_html/`:

**The domain likely points to `public_html/vlagit.com/`**

### Fix:

1. **Upload Flutter files to the correct location:**
   - Upload all files from `build/web/` to `public_html/vlagit.com/`
   - NOT to `public_html/` root

2. **Verify structure:**
   ```
   public_html/
   ├── vlagit.com/          ← Domain points here
   │   ├── index.html      ← Flutter app entry
   │   ├── main.dart.js
   │   ├── assets/
   │   ├── icons/
   │   └── .htaccess
   ├── api/                ← API can stay here
   └── static/             ← Static files can stay here
   ```

3. **Or move API to match:**
   ```
   public_html/
   └── vlagit.com/
       ├── index.html
       ├── main.dart.js
       ├── assets/
       ├── icons/
       ├── api/            ← Move API here
       ├── static/         ← Move static here
       └── .htaccess
   ```

---

## 🔍 How to Check Domain Configuration

### In cPanel:

1. Search for: `Addon Domains`
2. Look for `vlagit.com`
3. Check the "Document Root" column
4. This shows where the domain actually points

**Example:**
- Document Root: `/home/username/public_html/vlagit.com` → Upload to `vlagit.com/` folder
- Document Root: `/home/username/public_html` → Upload to `public_html/` root

---

## ✅ After Fixing

1. **Clear browser cache** (important!)
2. **Test in incognito mode**
3. **Visit:** `https://vlagit.com`
4. **Should see:** VLag authentication screen

---

## 🆘 Still Not Working?

If still showing old site:

1. **Check file permissions:**
   - `index.html`: `644`
   - Folders: `755`

2. **Verify .htaccess is working:**
   - Check Apache error logs in cPanel
   - Ensure mod_rewrite is enabled

3. **Test direct file access:**
   - `https://vlagit.com/index.html` (should load)
   - `https://vlagit.com/main.dart.js` (should download)

4. **Check for DNS/CDN caching:**
   - Wait a few minutes
   - Try different browser/device
   - Clear DNS cache

---

**Most likely:** The domain points to `public_html/vlagit.com/` so you need to upload files there, not to `public_html/` root.
