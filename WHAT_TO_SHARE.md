# What to Share - Quick Reference

## ✅ SAFE to Share With Developer/Assistant

### Information
- ✅ Domain name: `vlagit.com`
- ✅ Public URLs: `https://vlagit.com`
- ✅ API endpoints: `https://vlagit.com/api/health`
- ✅ Folder structure: `public_html/api/`
- ✅ PHP version: `7.4` or `8.0` (if visible)
- ✅ Server type: `o2switch cPanel`

### Screenshots (Safe)
- ✅ File Manager showing folder structure
- ✅ cPanel tools interface (without credentials)
- ✅ Error messages (without sensitive data)
- ✅ Directory listings (without file contents)
- ✅ Settings pages (without values filled)

### Questions
- ✅ "How do I find X in cPanel?"
- ✅ "What should this folder structure be?"
- ✅ "I'm getting error X, what should I check?"
- ✅ "Where do I upload files?"

---

## 🚫 NEVER Share

### Credentials
- ❌ cPanel password
- ❌ FTP passwords
- ❌ Database passwords
- ❌ API keys from `config.php`
- ❌ Admin secrets

### Files with Secrets
- ❌ `config.php` contents (with actual values)
- ❌ `.env` files
- ❌ Private keys (`.key`, `.pem` files)

### Screenshots with Secrets
- ❌ Screenshots with password fields filled
- ❌ Screenshots showing API keys
- ❌ Screenshots with database credentials visible

---

## 📸 Example: Safe Screenshot

**Good Screenshot:**
```
Shows:
- File Manager
- Folder: public_html/api/
- Files: index.php, config.php (names only)
- NO file contents visible
- NO passwords visible
```

**Bad Screenshot:**
```
Shows:
- config.php OPEN with API_KEY = 'actual-secret-key-123'
- Password field with text visible
- Database connection string with password
```

---

## 💬 Example: Safe Communication

### ✅ Good Message:
```
"I've created the api folder in public_html.
I uploaded index.php, config.php, and utils.php.
I'm getting a 500 error when visiting /api/health.
Here's a screenshot of the File Manager structure."
[Screenshot without sensitive data]
```

### ❌ Bad Message:
```
"Here's my config.php:
API_KEY = 'sk_live_abc123xyz'
ADMIN_SECRET = 'my-secret-here'
FTP password is: MyPass123!"
```

---

## 🎯 Quick Decision Guide

**Ask yourself:**
- Does this contain a password? → ❌ Don't share
- Does this contain an API key? → ❌ Don't share
- Is this a public URL? → ✅ Safe to share
- Is this a folder name? → ✅ Safe to share
- Is this an error message? → ✅ Safe (if no secrets)

**When in doubt:** Don't share it. Ask first!

---

**Remember**: Public information (URLs, folder names) is safe. Private information (passwords, keys, secrets) is NEVER safe to share.
