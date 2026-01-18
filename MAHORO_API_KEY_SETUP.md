# Mahoro API Key Setup Guide

## Quick Setup (2 Steps)

### Step 1: Set Your Claude API Key

Run this command (replace `YOUR_API_KEY_HERE` with your actual Claude API key):

```bash
cd /Users/jovan/Projects/ingabo
firebase functions:config:set claude.api_key="YOUR_API_KEY_HERE"
```

**Example:**
```bash
firebase functions:config:set claude.api_key="sk-ant-api03-..."
```

### Step 2: Deploy the Function

After setting the API key, deploy the function:

```bash
firebase deploy --only functions
```

This will take 2-5 minutes. Once complete, Mahoro will automatically work in your app!

---

## Alternative: Using Firebase Console

If you prefer using the web interface:

1. Go to: https://console.firebase.google.com/project/hopecore-hub/functions/config
2. Click "Add variable"
3. Key: `claude.api_key`
4. Value: Your Claude API key (starts with `sk-ant-`)
5. Click "Save"
6. Then deploy: `firebase deploy --only functions`

---

## Verify It's Working

After deployment, test in your app:

1. Open the app
2. Navigate to "Mahoro AI"
3. Send a test message like "Hello"
4. You should get a response from Mahoro!

---

## Troubleshooting

### Check if API key is set:
```bash
firebase functions:config:get
```

Should show:
```json
{
  "claude": {
    "api_key": "sk-ant-..."
  }
}
```

### Check function logs:
```bash
firebase functions:log --only mahoroChat
```

### Common Issues:

1. **"API key not configured"** → Make sure you ran `firebase functions:config:set` and then `firebase deploy --only functions`

2. **"Invalid API key"** → Check that your API key is correct and starts with `sk-ant-`

3. **Function not found** → Make sure you deployed: `firebase deploy --only functions`

---

## Note on Deprecation

Firebase is deprecating `functions.config()` in March 2026. The current setup will work until then. We can migrate to environment variables later if needed.

