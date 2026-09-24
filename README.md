# AssetGuard

AI-powered asset tracking system using BLE, Wi-Fi fingerprinting, and community sensing.

## Project Structure

- `lib/` - Flutter mobile application
- `backend/` - Node.js REST API
- `android/` - Android-specific configuration
- `assets/` - Images and static resources

## Development Setup

### Backend

1. Navigate to backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create `.env` file from template:
   ```bash
   cp .env.example .env
   ```

4. Configure environment variables in `.env` (see backend/.env.example for required values)

5. Start development server:
   ```bash
   npm run dev
   ```

### Flutter App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Production Deployment

### Backend Deployment (Render)

1. Push code to GitHub
2. Create new Web Service on Render
3. Connect GitHub repository
4. Configure environment variables (see backend/.env.example)
5. Deploy from `clean-main` branch

### Android Production Build

1. Generate keystore (one-time setup):
   ```bash
   cd android/app
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

3. Build release APK:
   ```bash
   flutter build apk --dart-define=API_URL=https://your-backend.onrender.com --dart-define=ML_API_URL=https://wifi-server-sl6b.onrender.com
   ```

4. Find APK at: `build/app/outputs/flutter-apk/app-release.apk`

## Security Notes

- **Never commit** `.env` files, `key.properties`, or `.jks` keystores
- All sensitive files are excluded in `.gitignore`
- Use environment variables for all secrets
- Backend uses JWT authentication with configurable secrets

## Documentation

- Full project documentation: `COMPLETE_PROJECT_DOCUMENTATION_FOR_PRESENTATION.md`
- Presentation guide: `PRESENTATION_GUIDE.md`
- Background BLE implementation: `BACKGROUND_BLE_COMMUNITY_SENSING.md`
