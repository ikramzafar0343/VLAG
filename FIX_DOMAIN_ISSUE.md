# Fix: vlagit.com Showing Old Site

## 🔍 Problem Identified

From your cPanel screenshots:
- ✅ `vlagit.com` points to `/public_html/` (correct location)
- ❌ There's a **redirection** configured for `vlagit.com`
- ❌ WordPress `index.php` might be taking precedence over Flutter `index.html`

## 🎯 Solution Steps

### Step 1: Remove Domain Redirection

1. In cPanel, go to **"Edit the additional domain"** (where you saw the redirection)
2. Find `vlagit.com` in the list
3. Click **"Manage redirection"** for `vlagit.com`
4. **Clear/Remove the redirection:**
   - Delete the "https://" value in the redirection field
   - Leave it **empty** (no redirection)
   - Click **"Enregistrer"** (Save)
5. Click **"Retour"** (Back) to confirm

**Result:** Domain will serve files from `/public_html/` directly, not redirect.

### Step 2: Handle WordPress index.php

Since both domains share `public_html/`, WordPress might be interfering:

**Option A: Remove WordPress (if stenme.com not needed)**
1. In File Manager (`public_html/`):
   - Delete or rename `index.php` (WordPress)
   - This allows Flutter `index.html` to load

**Option B: Keep WordPress, Prioritize Flutter**
1. In File Manager (`public_html/`):
   - Rename WordPress `index.php` to `index.php.backup`
   - Flutter `index.html` will now load first

### Step 3: Verify Flutter Files Location

Ensure Flutter files are in `public_html/` root:
- ✅ `index.html` (Flutter)
- ✅ `main.dart.js`
- ✅ `assets/` folder
- ✅ `icons/` folder
- ✅ `.htaccess` (with Flutter routing rules)

### Step 4: Update .htaccess to Prioritize HTML

In File Manager, edit `public_html/.htaccess`:

```apache
# Enable rewrite engine
RewriteEngine On

# Prioritize index.html over index.php
DirectoryIndex index.html index.php

# Handle Flutter Web routing
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_URI} !^/api/
RewriteRule ^(.*)$ /index.html [L]
```

### Step 5: Clear Cache and Test

1. **Clear browser cache:** `Ctrl + Shift + R`
2. **Try incognito mode**
3. **Visit:** `https://vlagit.com`
4. **Should see:** VLag authentication screen

---

## ✅ Quick Fix Summary

1. **Remove redirection** for `vlagit.com` (leave empty)
2. **Rename WordPress `index.php`** to `index.php.backup`
3. **Verify Flutter `index.html`** is in `public_html/`
4. **Update `.htaccess`** with `DirectoryIndex index.html index.php`
5. **Clear browser cache** and test

---

## 🔍 Verify Files Are Correct

In File Manager, check `public_html/` contains:

**Flutter Files:**
- `index.html` (Flutter app)
- `main.dart.js` (large file, ~3MB)
- `assets/` folder
- `icons/` folder
- `canvaskit/` folder

**Server Files:**
- `api/` folder
- `static/` folder
- `.htaccess` file

**WordPress (if present):**
- `wp-admin/` (can keep if needed)
- `wp-content/` (can keep if needed)
- `index.php` (WordPress - rename this!)

---

## 🎯 Expected Result

After fixing:
- `https://vlagit.com` → Shows VLag Flutter app
- `https://stenme.com` → Shows WordPress (if you keep it)

Both can coexist in `public_html/` if you:
- Remove redirection
- Prioritize `index.html` over `index.php`
- Use proper `.htaccess` configuration

---

**Most Important:** Remove the redirection first! That's likely why the old site is showing.
