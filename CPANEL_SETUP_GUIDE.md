# o2switch cPanel Setup Guide - VLagIt

## 🎯 What You Need to Do in cPanel

### Step 1: Access File Manager

1. In the **Technical Area**, use the **Search Tools** bar at the top
2. Type: `File Manager`
3. Click on **File Manager** when it appears
4. Navigate to `public_html/` directory

### Step 2: Create API Directory Structure

In File Manager (`public_html/`):

1. **Create `api` folder:**
   - Click "New Folder" or "+ Folder"
   - Name: `api`
   - Location: `public_html/api/`

2. **Create `static` folder** (for images):
   - Click "New Folder"
   - Name: `static`
   - Location: `public_html/static/`

### Step 3: Determine Domain Root Location

**IMPORTANT:** First check where your domain points!

1. In cPanel, search for: `Addon Domains`
2. Find `vlagit.com` in the list
3. Check the **"Document Root"** column

**Two scenarios:**

#### Scenario A: Domain points to `public_html/` (Main Domain)
- Document Root: `/home/username/public_html`
- Upload files to: `public_html/`

#### Scenario B: Domain points to `public_html/vlagit.com/` (Addon Domain)
- Document Root: `/home/username/public_html/vlagit.com`
- Upload files to: `public_html/vlagit.com/`

### Step 4: Upload Server Files

**What to upload from your local `server/` folder:**

#### Upload to `[domain-root]/api/`:
- `index.php`
- `config.php` (you'll edit this)
- `utils.php`
- `.htaccess`

#### Upload to `[domain-root]/`:
- `.htaccess` (from `server/public_html/.htaccess`)

#### Upload to `[domain-root]/static/`:
- `vlag-meta.png` (if you have it)

**Replace `[domain-root]` with:**
- `public_html/` if main domain
- `public_html/vlagit.com/` if addon domain

### Step 5: Upload Flutter Web Build

**After building Flutter web (`flutter build web --release`):**

1. Upload all files from `build/web/` to `[domain-root]/`
   - Where `[domain-root]` is determined in Step 3
   - Files: `index.html`, `main.dart.js`, `assets/`, `icons/`, etc.

2. **Important:**
   - Upload directly to domain root (not in subfolder)
   - Do NOT overwrite `api/` folder
   - Do NOT overwrite `static/` folder

### Step 6: Configure API (IMPORTANT)

1. In File Manager, navigate to `public_html/api/`
2. **Right-click on `config.php`** → **Edit**
3. Update these values (NEVER share the actual values with me):

```php
// Generate secure keys (use password generator or: openssl rand -hex 32)
define('API_KEY', 'your-generated-secret-key-here');
define('ADMIN_SECRET', 'your-generated-admin-secret-here');

// Set to false in production
define('API_DEBUG', false);
```

4. **Save** the file

### Step 7: Set File Permissions

In File Manager, set permissions:

1. **Select `api` folder** → Right-click → **Change Permissions**
   - Set to: `755`

2. **Select `api/cache` folder** (create if doesn't exist) → Permissions: `755`

3. **Select `api/logs` folder** (create if doesn't exist) → Permissions: `755`

4. **PHP files** (`index.php`, `config.php`, `utils.php`): `644`

### Step 8: Test API Endpoint

1. Open a new browser tab
2. Visit: `https://vlagit.com/api/health`
3. Should see JSON response:
```json
{
  "success": true,
  "message": "VLagIt API is running"
}
```

---

## 🔒 What to Share With Me (Safe)

### ✅ SAFE to Share:

1. **Screenshots of File Manager:**
   - Folder structure (with sensitive file contents hidden)
   - Directory listings (without showing config.php contents)

2. **Screenshots of cPanel Tools:**
   - FTP Accounts interface (without passwords)
   - Database interface (without credentials)
   - SSL Certificates section

3. **Information:**
   - Domain name: `vlagit.com` ✅
   - Public URLs: `https://vlagit.com` ✅
   - API endpoint: `https://vlagit.com/api/health` ✅
   - Folder structure: `public_html/api/` ✅
   - PHP version (if visible) ✅

4. **Error Messages:**
   - API error responses (without credentials)
   - File permission errors
   - Upload errors

5. **Questions:**
   - "Where do I find X in cPanel?"
   - "What should this folder structure look like?"
   - "How do I set permissions?"

---

## 🚫 What NOT to Share (NEVER)

### ❌ NEVER Share:

1. **Credentials:**
   - ❌ cPanel password
   - ❌ FTP passwords
   - ❌ Database passwords
   - ❌ API keys or secrets from `config.php`
   - ❌ Your username (`icdn8280`) - not critical, but better safe

2. **Sensitive Files:**
   - ❌ Contents of `config.php` (with actual API_KEY values)
   - ❌ `.env` files
   - ❌ Private keys or certificates

3. **Screenshots with Secrets:**
   - ❌ Screenshots showing passwords
   - ❌ Screenshots showing API keys
   - ❌ Screenshots showing database credentials

---

## 📸 How to Share Screenshots Safely

### ✅ Good Screenshots to Share:

1. **File Manager Structure:**
   ```
   Screenshot showing:
   - public_html/
     - api/
       - index.php
       - config.php (file name visible, NOT contents)
   ```

2. **cPanel Interface:**
   - Tools menu
   - Folder structure
   - Settings (without values)

3. **Error Messages:**
   - API errors (without credentials)
   - Permission errors
   - Upload errors

### ❌ Bad Screenshots (Don't Share):

- Screenshots with password fields filled
- Screenshots showing `config.php` contents with API_KEY values
- Screenshots with database connection strings

---

## 🛠️ Common Tasks in cPanel

### Finding Tools (Use Search Bar):

Type in "Search Tools" bar:
- `File Manager` - Manage files
- `FTP Accounts` - Create FTP users
- `MySQL Databases` - Database management
- `SSL/TLS` - Certificate management
- `PHP Version` - Check PHP version

### Creating FTP User (If Needed):

1. Search: `FTP Accounts`
2. Click **"FTP Accounts"**
3. Click **"Add FTP Account"**
4. Fill in:
   - **Username**: `ftp_vlagit` (or similar)
   - **Directory**: `/public_html/api` (limited access)
   - **Quota**: Set limit (e.g., 100 MB)
5. **Create Account**
6. **Share credentials securely** (not with me, with your developer if needed)

---

## ✅ Setup Checklist

Use this checklist as you work:

- [ ] File Manager accessed
- [ ] `public_html/api/` folder created
- [ ] `public_html/static/` folder created
- [ ] Server files uploaded to correct locations
- [ ] `config.php` edited with secure keys
- [ ] File permissions set correctly
- [ ] `.htaccess` files uploaded
- [ ] API health check works (`/api/health`)
- [ ] No sensitive information shared

---

## 🆘 If You Need Help

### Safe Questions to Ask:

✅ "How do I find File Manager in cPanel?"
✅ "What should the folder structure look like?"
✅ "I'm getting a 500 error on `/api/health`, what should I check?"
✅ "How do I set file permissions to 755?"
✅ "Where do I upload the Flutter web build files?"

### What to Include When Asking:

1. **Screenshot** of the issue (without sensitive data)
2. **Error message** (if any)
3. **What you were trying to do**
4. **What you've already tried**

---

## 📋 Next Steps After Setup

Once server is set up:

1. **Test API:**
   - Visit: `https://vlagit.com/api/health`
   - Should return success message

2. **Prepare for Flutter Web Upload:**
   - Build Flutter web: `flutter build web --release`
   - Upload files from `build/web/` to `public_html/`

3. **Verify SSL:**
   - Check SSL Certificates section
   - Ensure HTTPS is working

---

## 🔐 Security Reminders

- ✅ Never share passwords or API keys
- ✅ Use limited access users when possible
- ✅ Set proper file permissions
- ✅ Keep `config.php` secure (not in Git)
- ✅ Test endpoints without exposing secrets

---

**Remember**: I can help you with setup steps, folder structure, and troubleshooting, but I should NEVER see your actual passwords, API keys, or sensitive configuration values.
