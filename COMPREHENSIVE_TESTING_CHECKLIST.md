# Comprehensive Testing Checklist - Batches 1A to 2H

## Pre-Testing Setup

1. **Build the app:**
   ```bash
   flutter clean
   flutter pub get
   flutter build ios --simulator  # or flutter build apk for Android
   ```

2. **Run on simulator/device:**
   ```bash
   flutter devices  # Get device ID
   flutter run -d <device-id>
   ```

3. **Monitor console for errors:**
   - Watch for any runtime errors
   - Check for unexpected debugPrint messages

---

## Batch 1A: Edit Profile Functionality

### ✅ Test Cases:

1. **Access Edit Profile:**
   - [ ] Navigate to Settings page
   - [ ] Tap "Edit Profile" button (should be visible in profile section)
   - [ ] Dialog should open with username field

2. **Edit Username:**
   - [ ] Enter new username (e.g., "TestUser123")
   - [ ] Tap "Save" button
   - [ ] Verify success message appears
   - [ ] Verify username updates in:
     - [ ] Settings page profile header
     - [ ] Home page greeting
     - [ ] All other places username is displayed

3. **Validation:**
   - [ ] Try saving empty username → should show error
   - [ ] Try saving with only spaces → should show error
   - [ ] Cancel button should close dialog without saving

4. **Persistence:**
   - [ ] Close and reopen app
   - [ ] Verify username persists after app restart

---

## Batch 1B: Mahoro AI Improvements

### ✅ Test Cases:

1. **Default Language:**
   - [ ] Open Mahoro page
   - [ ] Verify default language is "English" (not French)
   - [ ] Language selector should show "English" selected

2. **Multiline Input:**
   - [ ] Tap on message input field
   - [ ] Type a long message (multiple lines)
   - [ ] Verify input field expands to show multiple lines
   - [ ] Verify keyboard shows "return" key (not "send")
   - [ ] Press return to create new line (not send message)

3. **Message Wrapping:**
   - [ ] Send a long message
   - [ ] Verify message text wraps properly in chat bubbles
   - [ ] No text overflow or cut-off

4. **Error Handling:**
   - [ ] Check console for detailed API error logging
   - [ ] Test with invalid API key (if applicable)
   - [ ] Verify user-friendly error messages appear
   - [ ] Test network error scenarios

5. **API Logging:**
   - [ ] Send a message
   - [ ] Check console for detailed debugPrint statements
   - [ ] Verify API request/response logging is present

---

## Batch 1C: Settings Cleanup

### ✅ Test Cases:

1. **TTS/STT Toggles Removed:**
   - [ ] Navigate to Settings
   - [ ] Go to Language & Audio section
   - [ ] Verify Text-to-Speech toggle is **NOT** present
   - [ ] Verify Voice-to-Text toggle is **NOT** present

2. **Font Size Selector Removed:**
   - [ ] In Settings → Language & Audio section
   - [ ] Verify custom font size selector is **NOT** present
   - [ ] Verify message appears: "Font size follows system settings"

3. **System Font Scaling:**
   - [ ] Change system font size in device settings (iOS: Settings → Display & Brightness → Text Size)
   - [ ] Return to app
   - [ ] Verify app text scales with system settings
   - [ ] Test with different system font sizes (small, large, extra large)

4. **Settings Descriptions:**
   - [ ] Verify new description text appears for:
     - [ ] Language selection
     - [ ] Font family selection
     - [ ] Other relevant settings

5. **Section Headers:**
   - [ ] Verify section headers use localized Title Case keys

---

## Batch 1D: Forum Improvements

### ✅ Test Cases:

1. **"Join The Convo" Button:**
   - [ ] Navigate to Forum page
   - [ ] Verify floating action button says "Join The Convo" (not "Create Post")
   - [ ] Verify button text is localized (test in different languages)

2. **Anonymous Display:**
   - [ ] Create a post as anonymous user
   - [ ] Verify post shows "Anonymous" as author (for other users)
   - [ ] Verify your own anonymous posts show your real username (to you)
   - [ ] Create a post as non-anonymous user
   - [ ] Verify real username is displayed

3. **Post Creation:**
   - [ ] Tap "Join The Convo" button
   - [ ] Create a new post
   - [ ] Verify post appears in forum list
   - [ ] Verify all post functionality still works (like, comment, etc.)

---

## Batch 2A: BuildContext Safety (Forum, Auth, Admin)

### ✅ Test Cases:

1. **Forum Page:**
   - [ ] Create a new post
   - [ ] Verify success message appears
   - [ ] Like a post
   - [ ] Verify like functionality works
   - [ ] No console errors about BuildContext

2. **Auth Page:**
   - [ ] Send email verification
   - [ ] Verify verification email sent message appears
   - [ ] Test "Resend verification" button
   - [ ] No console errors

3. **Admin Page:**
   - [ ] Update subscription status (if admin)
   - [ ] Extend subscription (if admin)
   - [ ] Verify success messages appear
   - [ ] No console errors

4. **Admin Setup Page:**
   - [ ] Run admin setup (if applicable)
   - [ ] Verify setup completes successfully
   - [ ] No console errors

---

## Batch 2B: Unused Code Removal

### ✅ Test Cases:

1. **General Functionality:**
   - [ ] Navigate through all pages
   - [ ] Verify no missing features
   - [ ] Verify no broken functionality
   - [ ] All removed code was truly unused

2. **Specific Areas:**
   - [ ] Dashboard page loads correctly
   - [ ] Mobile dashboard works
   - [ ] All widgets render properly
   - [ ] No missing imports or undefined references

---

## Batch 2C: Print to DebugPrint

### ✅ Test Cases:

1. **Console Output:**
   - [ ] Use app normally
   - [ ] Check console for debugPrint messages (not print)
   - [ ] Verify no "print" statements in console
   - [ ] All logging uses debugPrint

---

## Batch 2D: Duplicate Localization Keys

### ✅ Test Cases:

1. **Language Switching:**
   - [ ] Switch between all languages (EN, FR, SW, RW)
   - [ ] Verify no duplicate key errors
   - [ ] Verify all text displays correctly
   - [ ] Test "Cancel" button in all languages (was duplicate)

2. **All Localized Text:**
   - [ ] Navigate through all pages
   - [ ] Verify all localized text displays correctly
   - [ ] No missing translations
   - [ ] No duplicate key warnings in console

---

## Color Changes: Dark Mode & Mahoro

### ✅ Test Cases:

1. **Dark Mode Background:**
   - [ ] Enable dark mode
   - [ ] Navigate through all pages:
     - [ ] Home page → should have **absolute black** background
     - [ ] Settings page → should have **absolute black** background
     - [ ] Forum page → should have **absolute black** background
     - [ ] Mahoro page → should have **absolute black** background
     - [ ] Auth page → should have **absolute black** background
     - [ ] Admin page → should have **absolute black** background
     - [ ] Muganga page → should have **absolute black** background
   - [ ] Verify backgrounds are **pure black** (not dark gray)

2. **Mahoro Colors in Dark Mode:**
   - [ ] Open Mahoro page in dark mode
   - [ ] Verify accent color is **purple** (Color(0xFF8A4FFF)) not red
   - [ ] Check header, buttons, and UI elements
   - [ ] Verify purple color is consistent throughout

3. **Light Mode:**
   - [ ] Switch to light mode
   - [ ] Verify Mahoro still uses red accent color
   - [ ] Verify all backgrounds are white/light

4. **High Contrast Mode:**
   - [ ] Enable high contrast mode in dark mode
   - [ ] Verify backgrounds are still absolute black
   - [ ] Verify borders and contrast are appropriate

---

## Batch 2E: Remaining BuildContext Safety

### ✅ Test Cases:

1. **Main Page Phone/SMS:**
   - [ ] Tap emergency call button
   - [ ] Make a phone call
   - [ ] Verify error messages appear if call fails
   - [ ] Send SMS message
   - [ ] Verify error messages appear if SMS fails
   - [ ] No console errors

2. **Settings Page:**
   - [ ] Logout from settings
   - [ ] Verify navigation to auth page works
   - [ ] Make phone call from settings
   - [ ] Verify error handling works
   - [ ] No console errors

3. **Muganga Page:**
   - [ ] Complete subscription payment flow
   - [ ] Verify success messages appear
   - [ ] Verify navigation works after payment
   - [ ] No console errors

4. **Reply Dialog:**
   - [ ] Reply to a forum post
   - [ ] Verify dialog closes properly
   - [ ] Verify reply is submitted
   - [ ] No console errors

---

## Batch 2F: Deprecated API Fixes

### ✅ Test Cases:

1. **Visual Verification:**
   - [ ] Navigate through all pages
   - [ ] Verify all colors display correctly
   - [ ] Verify opacity/alpha effects work properly
   - [ ] No visual glitches or missing colors

2. **Animations:**
   - [ ] Test navigation animations
   - [ ] Test button hover effects
   - [ ] Test card animations
   - [ ] Verify Matrix4 scaling works (bottom nav icons)

3. **Switch Widgets:**
   - [ ] Toggle switches in Settings
   - [ ] Toggle switches in Data Privacy Settings
   - [ ] Verify switches work correctly
   - [ ] Verify active colors display properly

4. **No Deprecation Warnings:**
   - [ ] Check console for deprecation warnings
   - [ ] Verify no withOpacity warnings
   - [ ] Verify no scale warnings
   - [ ] Verify no activeColor warnings

---

## Batch 2G: UI Overflow Issues

### ✅ Test Cases:

1. **Text Overflow:**
   - [ ] Test with very long usernames
   - [ ] Test with very long post titles
   - [ ] Test with very long messages
   - [ ] Verify text wraps or truncates properly
   - [ ] No "overflowed by X pixels" errors

2. **Layout Overflow:**
   - [ ] Test on different screen sizes (if possible)
   - [ ] Test with large system font sizes
   - [ ] Verify no RenderFlex overflow errors
   - [ ] All content fits within screens

3. **Responsive Design:**
   - [ ] Rotate device (if supported)
   - [ ] Verify layouts adapt properly
   - [ ] No overflow issues in landscape/portrait

---

## Batch 2H: Test Fixes

### ✅ Test Cases:

1. **Run Test Suite:**
   ```bash
   flutter test --reporter expanded
   ```
   - [ ] All tests pass (or known failures are documented)
   - [ ] No setMockMethodCallHandler deprecation warnings
   - [ ] Test infrastructure works correctly

2. **Manual Verification:**
   - [ ] All functionality tested above works
   - [ ] No regressions from test fixes

---

## Cross-Batch Integration Tests

### ✅ Test Cases:

1. **End-to-End User Flows:**
   - [ ] **New User Flow:**
     - [ ] Sign up → Edit profile → Use Mahoro → Create forum post
   - [ ] **Returning User Flow:**
     - [ ] Sign in → Check profile → Chat with Mahoro → Browse forum
   - [ ] **Admin Flow:**
     - [ ] Admin login → Manage subscriptions → Review content reports

2. **Language Switching:**
   - [ ] Switch language → Verify all text updates
   - [ ] Test in all 4 languages (EN, FR, SW, RW)
   - [ ] Verify no missing translations

3. **Theme Switching:**
   - [ ] Toggle dark/light mode multiple times
   - [ ] Verify all pages update correctly
   - [ ] Verify colors are correct in each mode

4. **Accessibility:**
   - [ ] Enable high contrast mode
   - [ ] Change system font size
   - [ ] Verify app adapts correctly
   - [ ] Verify all features remain usable

---

## Performance & Stability

### ✅ Test Cases:

1. **Performance:**
   - [ ] App launches quickly
   - [ ] Page transitions are smooth
   - [ ] No lag when typing in inputs
   - [ ] Animations are smooth

2. **Memory:**
   - [ ] Use app for extended period
   - [ ] Navigate between pages multiple times
   - [ ] Verify no memory leaks
   - [ ] App remains responsive

3. **Stability:**
   - [ ] No crashes during normal use
   - [ ] No crashes when switching themes/languages
   - [ ] No crashes during async operations
   - [ ] App handles errors gracefully

---

## Console Monitoring

### ✅ Check For:

- [ ] No BuildContext warnings
- [ ] No deprecation warnings
- [ ] No undefined function errors
- [ ] No missing asset errors
- [ ] Appropriate debugPrint messages (not print)
- [ ] No unexpected exceptions

---

## Quick Smoke Test (5 minutes)

If short on time, test these critical paths:

1. [ ] Sign in/out works
2. [ ] Edit profile works
3. [ ] Mahoro chat works (multiline input, default English)
4. [ ] Forum "Join The Convo" works
5. [ ] Settings: No TTS/STT toggles, font follows system
6. [ ] Dark mode: Absolute black backgrounds
7. [ ] Mahoro: Purple accent in dark mode
8. [ ] Language switching works
9. [ ] No console errors
10. [ ] App doesn't crash

---

## Test Results Template

```
Date: ___________
Tester: ___________
Device: ___________
OS Version: ___________

### Batch 1A: Edit Profile
- [ ] Pass / [ ] Fail - Notes: ___________

### Batch 1B: Mahoro AI
- [ ] Pass / [ ] Fail - Notes: ___________

### Batch 1C: Settings Cleanup
- [ ] Pass / [ ] Fail - Notes: ___________

### Batch 1D: Forum
- [ ] Pass / [ ] Fail - Notes: ___________

### Batches 2A-2H: Technical Fixes
- [ ] Pass / [ ] Fail - Notes: ___________

### Color Changes
- [ ] Pass / [ ] Fail - Notes: ___________

### Overall Status
- [ ] Ready for Production
- [ ] Needs Fixes (list below)
- [ ] Blocking Issues (list below)

Issues Found:
1. ___________
2. ___________
3. ___________
```

---

## Notes

- Test on both iOS and Android if possible
- Test with different user roles (regular user, admin, guest)
- Test with different network conditions (online, offline)
- Document any issues found with steps to reproduce
- Take screenshots of any visual issues

