# Troubleshooting Mahoro "Invalid Request" Error

## Current Status
- Function is deployed as 2nd Gen (Node.js 20)
- API key is set via `firebase functions:config:set`
- Function has enhanced logging

## Next Steps

### 1. Try Mahoro Again
After the latest deployment, try sending a message in Mahoro.

### 2. Check Function Logs
```bash
firebase functions:log --only mahorochat
```

Look for:
- "Mahoro function called with data:" - shows what data was received
- "API key found" or "API key not configured" - shows if API key is accessible
- Any error messages

### 3. If functions.config() Doesn't Work with 2nd Gen

If the logs show that `functions.config()` is not working, we need to set the API key as an environment variable:

```bash
# Set as environment variable for 2nd gen functions
firebase functions:secrets:set CLAUDE_API_KEY
# Then enter your API key when prompted
```

Then update the function to use the secret (we'll need to modify the code).

### 4. Alternative: Use Firebase Console

1. Go to: https://console.firebase.google.com/project/hopecore-hub/functions
2. Click on your function
3. Go to "Configuration" tab
4. Add environment variable: `CLAUDE_API_KEY` = your API key
5. Redeploy

## Common Issues

1. **"Invalid Request"** → Usually means `invalid-argument` error
   - Check logs to see what data was received
   - Verify message format is correct

2. **"API key not configured"** → `functions.config()` might not work with 2nd gen
   - Need to use environment variables instead

3. **Function not receiving data** → Check how the app is calling the function
   - Verify `httpsCallable` is being used correctly

