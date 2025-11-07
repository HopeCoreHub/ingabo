# Testing Guide for Batch 1C Changes

## Quick Answer: Do You Need to Rebuild?

**Yes, you need to rebuild and run the app** because:
- ✅ Code changes require a fresh build
- ✅ Hot reload won't pick up structural changes (removed widgets, new localization keys)
- ✅ Font scaling changes need a full rebuild to work correctly

**The changes are NOT in the database** - they're code changes that need to be compiled into the app.

---

## Testing Steps

### Step 1: Build and Run iOS Simulator

```bash
# Build iOS (no codesign needed for simulator)
flutter build ios --no-codesign

# Open Simulator (if not already open)
open -a Simulator

# Get simulator device ID
flutter devices

# Run the app (replace <simulator-id> with actual ID)
flutter run -d <simulator-id>
```

**Example:**
```bash
flutter run -d BDB5ED36-A36B-482D-A385-7987491BAE7A
```

---

### Step 2: Manual Testing Checklist

#### Test 1: TTS/STT Toggles Removed ✅
1. Open app and navigate to **Settings** page
2. Scroll down to **"Language & Audio"** section
3. **Verify:** Only Language selector is visible
4. **Verify:** No "Text-to-Speech" toggle
5. **Verify:** No "Voice-to-Text" toggle
6. **Verify:** Language selector still works (tap it, change language)

#### Test 2: Font Size Selector Removed ✅
1. In Settings, scroll to **"Accessibility"** section
2. **Verify:** Only Font Family selector is visible
3. **Verify:** No "Font Size" selector
4. **Verify:** Note appears below: *"Font size follows your device accessibility setting."*
5. **Verify:** Font Family selector works (tap it, change font)

#### Test 3: System Font Scale Works ✅
1. **On iOS Simulator:**
   - Go to **Settings** app (iOS Settings, not app Settings)
   - Navigate to **Accessibility** > **Display & Text Size** > **Larger Text**
   - Enable **Larger Accessibility Sizes**
   - Move slider to increase text size
   
2. **Return to HopeCore Hub app:**
   - Navigate through different screens (Home, Forum, Mahoro, Settings)
   - **Verify:** All text is larger
   - **Verify:** Text scales proportionally
   - **Verify:** No text overflow or layout breaks

3. **Decrease system font size:**
   - Go back to iOS Settings
   - Decrease text size
   - Return to app
   - **Verify:** Text scales down

#### Test 4: Localization ✅
1. In app Settings, change language to **French**
2. **Verify:** Section headers are in French
3. **Verify:** "Font size follows..." message is in French
4. Change to **Swahili**
5. **Verify:** Headers and messages are in Swahili
6. Change to **Kinyarwanda**
7. **Verify:** Headers and messages are in Kinyarwanda

#### Test 5: Font Family Still Works ✅
1. In Settings > Accessibility
2. Tap **Font Family** selector
3. **Verify:** Dialog opens with font options
4. Select a different font (e.g., Roboto)
5. **Verify:** Font changes throughout app
6. Navigate to different screens
7. **Verify:** New font is applied everywhere
8. Close and reopen app
9. **Verify:** Font preference persists

#### Test 6: No Regressions ✅
1. Navigate through all app sections:
   - Home
   - Forum
   - Mahoro
   - Settings
2. **Verify:** No console errors
3. **Verify:** No UI glitches
4. **Verify:** All other settings still work
5. **Verify:** No crashes

---

## What to Watch For

### ✅ Expected (Good)
- Language & Audio section only shows language selector
- Accessibility section only shows font family selector
- Note about system font size appears
- App text scales when you change iOS system font size
- All localization works correctly
- Font family selection works

### ❌ Unexpected (Report These)
- TTS/STT toggles still visible (should be removed)
- Font size selector still visible (should be removed)
- App text doesn't scale with system font size
- Layout breaks when system font size is large
- Console errors related to font size or TTS
- Crashes when accessing Settings

---

## Quick Test Commands

### Check if app is running:
```bash
flutter devices
```

### Hot reload (if app is already running):
```bash
# Press 'r' in the terminal where flutter run is active
# OR
flutter run -d <simulator-id>
```

### View logs:
```bash
# In a separate terminal
flutter logs
```

---

## Testing on Physical Device (Optional)

If you want to test on a physical iOS device:

```bash
# Connect device via USB
flutter devices  # Should show your device

# Run on device
flutter run -d <device-id>
```

**Note:** Physical device testing is recommended for:
- Real system font scale testing
- Performance verification
- Actual user experience

---

## Expected Results Summary

After testing, you should see:

✅ **Settings Page:**
- Language & Audio: Only language selector
- Accessibility: Only font family selector + system font note
- All other sections unchanged

✅ **System Font Scale:**
- App text automatically scales with iOS accessibility settings
- No need for custom font size selector
- Smooth scaling without layout breaks

✅ **Localization:**
- All section headers translated
- New messages translated
- Language switching works

✅ **No Regressions:**
- All existing features still work
- No crashes or errors
- Smooth user experience

---

## If You Find Issues

1. **Note the exact steps to reproduce**
2. **Check console for errors** (`flutter logs`)
3. **Take screenshots if UI issues**
4. **Report back with:**
   - What you tested
   - What happened vs. what should happen
   - Any error messages

---

## Next Steps After Testing

Once you confirm everything works:
1. ✅ Batch 1C is complete
2. ✅ Ready to proceed to Batch 1D (Forum improvements)
3. ✅ Or continue with other batches from the plan

---

**Ready to test!** Start with Step 1 (build and run), then follow the checklist.

