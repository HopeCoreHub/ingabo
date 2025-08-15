# iOS Build Setup Guide

This guide will help you set up the GitHub Actions workflow to build and submit your iOS app to the App Store.

## 🔧 Prerequisites

1. **Apple Developer Account** - You need a paid Apple Developer account
2. **Xcode** - Latest version recommended
3. **App Store Connect** access
4. **GitHub repository** with admin access

## 📋 Required GitHub Secrets

You need to configure the following secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

### Code Signing Secrets

#### `IOS_DIST_SIGNING_KEY`
- **Description**: Base64 encoded .p12 certificate file for distribution
- **How to get**:
  1. Open Keychain Access on macOS
  2. Find your "Apple Distribution" certificate
  3. Right-click and select "Export"
  4. Save as .p12 file with a password
  5. Convert to base64: `base64 -i YourCertificate.p12 | pbcopy`
  6. Paste the result as the secret value

#### `IOS_DIST_SIGNING_KEY_PASSWORD`
- **Description**: Password for the .p12 certificate file
- **Value**: The password you used when exporting the certificate

#### `IOS_BUNDLE_ID`
- **Description**: Your app's bundle identifier
- **Value**: `com.ingabohopecore.hopecorehub` (or your actual bundle ID)
- **How to find**: Check in Xcode project settings or `ios/Runner.xcodeproj`

### App Store Connect API Secrets

#### `APPSTORE_ISSUER_ID`
- **Description**: App Store Connect API Issuer ID
- **How to get**:
  1. Go to [App Store Connect](https://appstoreconnect.apple.com)
  2. Navigate to Users and Access > Integrations > App Store Connect API
  3. Copy the Issuer ID

#### `APPSTORE_KEY_ID`
- **Description**: App Store Connect API Key ID
- **How to get**:
  1. In App Store Connect API section
  2. Generate or find your API key
  3. Copy the Key ID

#### `APPSTORE_PRIVATE_KEY`
- **Description**: App Store Connect API Private Key
- **How to get**:
  1. Download the .p8 private key file from App Store Connect
  2. Copy the entire contents of the .p8 file (including headers)
  3. Paste as the secret value

## 🏗️ Setting Up Your App in App Store Connect

1. **Create App Record**:
   - Go to App Store Connect
   - Click "My Apps" > "+" > "New App"
   - Fill in app information:
     - Platform: iOS
     - Name: HopeCore Hub
     - Primary Language: English (or your preferred language)
     - Bundle ID: Select your registered bundle ID
     - SKU: Create a unique identifier

2. **Configure App Information**:
   - Add app description, keywords, categories
   - Upload screenshots and app icon
   - Set privacy policy URL if required
   - Configure age rating

3. **Set Up TestFlight** (Optional but recommended):
   - Enable TestFlight for beta testing
   - Add internal testers
   - Configure build settings

## 🚀 Workflow Triggers

The workflow runs automatically on:

1. **Push to main branch** - Builds and uploads to TestFlight
2. **Git tags** (v*) - Builds release version and uploads to TestFlight
3. **Pull requests** - Builds only (no upload)
4. **Manual trigger** - Can choose whether to upload to App Store

## 📱 Building Your App

### Automatic Builds

- **Development builds**: Push to any branch triggers a build
- **Release builds**: Create a git tag like `v1.0.0` to trigger a release build
- **Manual builds**: Use the "Run workflow" button in GitHub Actions

### Manual Release Process

1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # version+build_number
   ```

2. Commit and push changes

3. Create and push a git tag:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

4. The workflow will automatically build and upload to TestFlight

## 🔍 Troubleshooting

### Common Issues

1. **Code Signing Errors**:
   - Verify your distribution certificate is valid
   - Check that the bundle ID matches your provisioning profile
   - Ensure the certificate password is correct

2. **Provisioning Profile Issues**:
   - Make sure your app ID is registered in Apple Developer portal
   - Verify the provisioning profile includes your distribution certificate
   - Check that the bundle ID matches exactly

3. **App Store Connect Upload Errors**:
   - Verify API key has proper permissions
   - Check that the app record exists in App Store Connect
   - Ensure the bundle ID matches the app record

4. **Build Failures**:
   - Check Flutter version compatibility
   - Verify all dependencies are compatible with iOS
   - Review build logs for specific error messages

### Getting Help

- Check the [GitHub Actions logs](../../actions) for detailed error messages
- Review Apple's [App Store Connect API documentation](https://developer.apple.com/documentation/appstoreconnectapi)
- Check [Flutter iOS deployment guide](https://docs.flutter.dev/deployment/ios)

## 📝 Next Steps

1. Set up all required GitHub secrets
2. Create your app record in App Store Connect
3. Test the workflow with a small change
4. Monitor the first build in GitHub Actions
5. Check TestFlight for the uploaded build

## 🔒 Security Notes

- Never commit certificates or private keys to your repository
- Use GitHub secrets for all sensitive information
- Regularly rotate your App Store Connect API keys
- Review and limit API key permissions in App Store Connect

---

**Note**: This setup assumes you're using automatic code signing. If you prefer manual code signing, you'll need to modify the `ExportOptions.plist` and workflow accordingly.
