# ASSETGUARD AI - COMPLETE PROJECT DOCUMENTATION FOR PRESENTATION

**Project**: Indoor Asset Tracking System using BLE + Wi-Fi Fingerprinting + ML  
**Tech Stack**: Flutter (Frontend) + Node.js/Express (Backend) + MongoDB (Database) + Python ML Server  
**Purpose**: Help users find lost belongings on campus through community-powered BLE detection and ML-based room prediction

---

## TABLE OF CONTENTS

1. [Project Structure](#part-1-project-structure)
2. [Important Files Explained](#part-2-important-files)
3. [Application Startup](#part-3-startup-workflow)
4. [Authentication System](#part-4-authentication)
5. [Asset Management](#part-5-asset-management)
6. [Asset Lifecycle](#part-6-asset-states)
7. [BLE System](#part-7-ble-system)
8. [Wi-Fi System](#part-8-wifi-system)
9. [Wi-Fi Cache](#part-9-wifi-cache)
10. [Community Sensing](#part-10-community-sensing)
11. [Backend API](#part-11-backend-api)
12. [MongoDB Architecture](#part-12-mongodb)
13. [Community Detection Flow](#part-13-community-detection-flow)
14. [ML Integration](#part-14-ml-integration)
15. [Notifications](#part-15-notifications)
16. [Track Asset](#part-16-track-asset)
17. [Dashboard](#part-17-dashboard)
18. [Mark as Recovered](#part-18-mark-as-recovered)
19. [Error Handling](#part-19-error-handling)
20. [Security](#part-20-security)
21. [Complete End-to-End Flow](#part-21-complete-workflow)
22. [File Dependencies](#part-22-file-dependencies)
23. [Viva Questions](#part-23-viva-questions)
24. [Top 10 Files to Know](#top-10-files)

---

## PART 1: PROJECT STRUCTURE

### Root Folder Structure

```
c:\flutter-project\assetguard\
├── lib/                          # Flutter application source code
├── backend/                      # Node.js REST API server
├── android/                      # Android native configuration
├── ios/                          # iOS native configuration
├── assets/                       # Images, icons, static resources
├── build/                        # Compiled APK output
├── test/                         # Flutter unit/widget tests
├── pubspec.yaml                  # Flutter dependencies
└── *.md files                    # Documentation from development
```

### Flutter Application (`lib/`) Structure

```
lib/
├── main.dart                     # Application entry point
├── models/                       # Data models (Dart classes)
│   ├── asset_model.dart          # Asset data structure
│   ├── user_model.dart           # User data structure
│   ├── notification_model.dart   # Notification data structure
│   ├── community_detection_model.dart
│   ├── detection_model.dart
│   ├── dashboard_stats_model.dart
│   └── room_prediction_model.dart
├── screens/                      # UI screens/pages
│   ├── splash_screen.dart        # Initial loading screen
│   ├── login_screen.dart         # User login
│   ├── register_screen.dart      # User registration
│   ├── home_screen.dart          # Main dashboard
│   ├── my_assets_screen.dart     # List of user's assets
│   ├── add_asset_screen.dart     # Create new asset
│   ├── asset_details_screen.dart # View/edit asset details
│   ├── track_asset_screen.dart   # Map showing detections
│   ├── notifications_screen.dart # Notification list
│   ├── profile_screen.dart       # User profile
│   └── main_shell.dart           # Bottom navigation container
├── services/                     # Business logic layer
│   ├── api_service.dart          # HTTP client (talks to backend)
│   ├── auth_service.dart         # Login/logout/token management
│   ├── asset_service.dart        # Asset CRUD operations
│   ├── ble_service.dart          # Bluetooth scanning
│   ├── wifi_scan_service.dart    # Wi-Fi scanning
│   ├── wifi_fingerprint_cache.dart # Wi-Fi data cache
│   ├── community_sensing_service.dart # Background scanning orchestrator
│   ├── community_detection_service.dart # Report detections to backend
│   ├── notification_service.dart # Fetch notifications
│   ├── location_service.dart     # GPS coordinates
│   └── permission_service.dart   # Android permissions
├── widgets/                      # Reusable UI components
│   ├── asset_card.dart           # Asset list item
│   ├── stat_card.dart            # Dashboard metric card
│   └── custom_text_field.dart    # Styled input field
├── theme/                        # App colors, fonts, styles
│   └── app_theme.dart
└── utils/                        # Configuration constants
    ├── api_config.dart           # Backend URL
    └── community_detection_config.dart # Scan intervals, debounce
```

**Why This Structure?**
- **Separation of concerns**: UI (screens) separate from logic (services) separate from data (models)
- **Reusability**: Services can be called from any screen
- **Testability**: Services can be tested independently
- **Maintainability**: Each file has a single responsibility

### Backend Structure (`backend/`)

```
backend/
├── server.js                     # Entry point (starts Express server)
├── package.json                  # Node.js dependencies
├── .env                          # Environment variables (secrets)
├── src/
│   ├── app.js                    # Express app configuration
│   ├── config/
│   │   └── db.js                 # MongoDB connection
│   ├── models/                   # MongoDB schemas
│   │   ├── User.js               # User collection schema
│   │   ├── Asset.js              # Asset collection schema
│   │   ├── Detection.js          # Owner detections
│   │   ├── CommunityDetection.js # Community detections
│   │   ├── CommunityFingerprint.js # Wi-Fi scans
│   │   └── Notification.js       # Notification collection
│   ├── controllers/              # Business logic handlers
│   │   ├── authController.js     # Login, register, verify email
│   │   ├── assetController.js    # Asset CRUD operations
│   │   ├── communityController.js # Community detection logic
│   │   ├── notificationController.js
│   │   ├── dashboardController.js
│   │   └── detectionController.js
│   ├── routes/                   # API endpoint definitions
│   │   ├── authRoutes.js         # /api/auth/*
│   │   ├── assetRoutes.js        # /api/assets/*
│   │   ├── communityRoutes.js    # /api/community/*
│   │   ├── notificationRoutes.js # /api/notifications/*
│   │   └── dashboardRoutes.js    # /api/dashboard/stats
│   ├── middleware/
│   │   ├── auth.js               # JWT verification (protect routes)
│   │   └── validate.js           # Input validation
│   ├── services/
│   │   └── emailService.js       # Send verification emails
│   └── utils/
│       └── response.js           # Standardized API responses
└── tests/                        # API integration tests
```

**Why This Structure?**
- **MVC Pattern**: Models (data), Controllers (logic), Routes (endpoints)
- **Middleware**: Reusable authentication/validation
- **Environment Variables**: Secrets not in code (`.env`)
- **Scalability**: Easy to add new endpoints/models

### Android Native Configuration (`android/`)

```
android/
├── app/
│   └── src/
│       └── main/
│           ├── AndroidManifest.xml    # Permissions, deep links
│           ├── kotlin/                # Android-specific code
│           └── res/                   # Icons, launch screen
└── build.gradle                       # Android build configuration
```

**Important for**: Bluetooth permissions, location permissions, foreground service permissions, deep link configuration

---

## WHY EACH FOLDER EXISTS

### `lib/models/`
- **Purpose**: Define data structures that match backend API responses
- **Contains**: Dart classes with `fromJson()` and `toJson()` methods
- **Interacts with**: Services (convert JSON ↔ Dart objects), Screens (display data)

### `lib/services/`
- **Purpose**: Business logic layer - talks to backend, manages state, handles complex operations
- **Contains**: Singleton services with async methods
- **Interacts with**: Screens (UI calls services), Backend (HTTP requests), Platform (BLE/GPS)

### `lib/screens/`
- **Purpose**: User interface pages
- **Contains**: StatefulWidget/StatelessWidget classes
- **Interacts with**: Services (fetch/update data), Widgets (compose UI), Navigation

### `backend/models/`
- **Purpose**: Define MongoDB collection schemas
- **Contains**: Mongoose schemas with validation rules
- **Interacts with**: Controllers (query/insert/update data), MongoDB

### `backend/controllers/`
- **Purpose**: Handle API requests, implement business rules
- **Contains**: Async functions that receive `req` and return `res`
- **Interacts with**: Models (database), Services (email), ML Server (HTTP)

### `backend/routes/`
- **Purpose**: Map HTTP endpoints to controller functions
- **Contains**: Express Router definitions
- **Interacts with**: Controllers (handler functions), Middleware (auth, validation)

---

## ENTRY POINT FILES

### Flutter Entry Point: `lib/main.dart`
- **Line 10**: `void main()` - Dart execution starts here
- **Line 14**: `CommunitySensingService.initForegroundTask()` - Registers Android notification channel
- **Line 25**: `runApp(AssetGuardApp())` - Starts Flutter app
- **Line 81**: First screen is `SplashScreen()`

### Backend Entry Point: `backend/server.js`
- **Line 1**: Load environment variables from `.env`
- **Line 2**: Import Express app from `src/app.js`
- **Line 3**: Import MongoDB connection function
- **Line 7-12**: Connect to MongoDB then start server on port 5000

---

## FILE TYPES

### **CRITICAL FILES** (Never modify without understanding)
1. `lib/services/community_sensing_service.dart` - Background scanning orchestration
2. `lib/services/ble_service.dart` - Bluetooth detection
3. `backend/src/controllers/communityController.js` - Detection + ML integration

### **UI FILES** (Safe to modify styling)
1. All files in `lib/screens/`
2. All files in `lib/widgets/`
3. `lib/theme/app_theme.dart`

### **CONFIGURATION FILES** (Project settings)
1. `pubspec.yaml` - Flutter dependencies
2. `backend/package.json` - Node.js dependencies
3. `backend/.env` - Secrets (NEVER commit to Git)
4. `lib/utils/api_config.dart` - Backend URL

### **GENERATED FILES** (Auto-created, ignore)
1. `build/` folder - Compiled APK
2. `.dart_tool/` - Flutter tooling cache
3. `backend/node_modules/` - Downloaded packages

### **TEST FILES**
1. `test/` - Flutter tests (mostly empty)
2. `backend/tests/` - API tests
3. `backend/test-*.js` - Manual test scripts

### **DOCUMENTATION FILES** (Development notes)
- All `*.md` files in root - Created during development to track decisions

---


## PART 2: IMPORTANT FILES EXPLAINED

### FLUTTER FILES

#### `lib/main.dart`
**PURPOSE**: Entry point of the Flutter application

**IMPORTANT FUNCTIONS**:
- `void main()` - First function executed when app starts
  - Initializes Flutter binding
  - Registers foreground task notification channel
  - Sets screen orientation to portrait only
  - Launches `AssetGuardApp` widget
- `_initDeepLinks()` - Sets up deep link handling for email verification and password reset
- `_handleDeepLink(Uri uri)` - Routes deep links to appropriate screens

**CALLS**:
- `CommunitySensingService.initForegroundTask()` - Registers Android notification channel for background scanning
- `runApp(AssetGuardApp())` - Starts Flutter app
- `AppLinks()` - Third-party package for handling `assetguard://` deep links

**DATA USED**: None (just configuration)

**WHY IT EXISTS**: Every Flutter app needs a `main()` function as the entry point

---

#### `lib/models/asset_model.dart`
**PURPOSE**: Represents an Asset (user's belongings) in Dart

**IMPORTANT CLASSES**:
- `Asset` - Data class with fields:
  - `id` - MongoDB `_id`
  - `name` - E.g., "Laptop", "Wallet"
  - `category` - E.g., "Electronics", "Personal"
  - `description` - Optional details
  - `trackerId` - Unique BLE tracker ID (e.g., "AG-001")
  - `status` - 'ACTIVE', 'LOST', or 'RECOVERED'
  - `lastDetectedLocation` - Last known location string
  - `lastDetectedTime` - Last detection timestamp

**IMPORTANT FUNCTIONS**:
- `Asset.fromJson(Map<String, dynamic> json)` - Converts backend JSON to Dart object
- `toJson()` - Converts Dart object to JSON for API requests
- `copyWith()` - Creates a modified copy of an asset (immutability pattern)

**INPUT**: JSON from backend API `/api/assets`

**OUTPUT**: Dart `Asset` object that UI can display

**CALLED BY**: 
- `asset_service.dart` - When fetching/creating assets
- UI screens - To display asset data

**WHY IT EXISTS**: Type-safe representation of asset data, matches backend `Asset` model

---

#### `lib/models/notification_model.dart`
**PURPOSE**: Represents a notification sent to asset owner

**IMPORTANT CLASSES**:
- `AppNotification` - Fields include:
  - `id, type, title, message`
  - `assetId, trackerId` - Which asset was detected
  - `latitude, longitude, rssi` - Detection metadata
  - `predictedRoom, roomConfidence` - ML prediction (e.g., "Room 310", 0.38)
  - `read` - Boolean flag
  - `createdAt` - Timestamp

**WHY IT EXISTS**: Stores all notification data including ML room predictions

---

#### `lib/services/auth_service.dart`
**PURPOSE**: Manages user authentication and JWT token persistence

**IMPORTANT FUNCTIONS**:
- `tryAutoLogin()` - Called on app startup
  - Reads token from `SharedPreferences`
  - Validates token with backend (`GET /api/auth/me`)
  - Restores user session if valid
- `register(name, email, password)` - Creates new account
  - `POST /api/auth/register`
  - In dev mode, may return token immediately (bypass email verification)
  - In production, user must verify email first
- `login(email, password)` - Authenticates existing user
  - `POST /api/auth/login`
  - Stores JWT token in SharedPreferences
  - Stores user data in memory
- `logout()` - Clears token and user data
- `verifyEmailToken(rawToken)` - Called from deep link
  - `GET /api/auth/verify-email?token=...`
  - Completes email verification

**DATA USED**:
- `SharedPreferences` - Persistent key-value storage (stores JWT)
- `ApiService` - HTTP client
- `UserModel` - Current user data

**CALLED BY**:
- `login_screen.dart` - Login button
- `register_screen.dart` - Register button
- `splash_screen.dart` - Auto-login check
- `verify_email_callback_screen.dart` - Email verification

**CALLS**:
- `ApiService.instance.post()` - HTTP requests
- `SharedPreferences.getInstance()` - Token storage

**WHY IT EXISTS**: Centralized authentication logic, token management

---

#### `lib/services/api_service.dart`
**PURPOSE**: HTTP client for all backend communication

**IMPORTANT CLASSES**:
- `ApiService` - Singleton
- `ApiException` - Custom error type with `statusCode` and `message`

**IMPORTANT FUNCTIONS**:
- `get(String endpoint)` - HTTP GET request
- `post(String endpoint, Map<String, dynamic> body)` - HTTP POST
- `put(String endpoint, Map<String, dynamic> body)` - HTTP PUT
- `delete(String endpoint)` - HTTP DELETE
- `setToken(String? token)` - Stores JWT for authenticated requests
- `_headers` - Getter that includes `Authorization: Bearer <token>` header

**INPUT**: Endpoint path (e.g., '/api/assets'), optional request body

**OUTPUT**: Parsed JSON as `Map<String, dynamic>`

**CALLED BY**: All service classes (`auth_service.dart`, `asset_service.dart`, etc.)

**WHY IT EXISTS**: 
- Single point for all HTTP logic
- Automatic token injection
- Centralized error handling
- Base URL configuration

---

#### `lib/services/asset_service.dart`
**PURPOSE**: Manages asset CRUD operations

**IMPORTANT FUNCTIONS**:
- `getAssets()` - `GET /api/assets` - Fetches all user's assets
- `getAsset(id)` - `GET /api/assets/:id` - Fetch single asset
- `createAsset(Asset asset)` - `POST /api/assets` - Create new asset
- `updateAsset(Asset asset)` - `PUT /api/assets/:id` - Update asset
- `deleteAsset(id)` - `DELETE /api/assets/:id` - Remove asset
- `markAsLost(id)` - `PUT /api/assets/:id/status` - Change status to LOST
- `markAsRecovered(id)` - `PUT /api/assets/:id/recover` - Change status to RECOVERED

**CALLS**:
- `ApiService.instance` for all HTTP requests
- `Asset.fromJson()` to convert responses

**CALLED BY**:
- `my_assets_screen.dart` - Display asset list
- `add_asset_screen.dart` - Create asset
- `asset_details_screen.dart` - View/edit/delete/mark lost/recover

**WHY IT EXISTS**: Encapsulates all asset-related API calls

---

#### `lib/services/ble_service.dart`
**PURPOSE**: Bluetooth Low Energy scanning for AssetGuard trackers

**IMPORTANT CLASSES**:
- `BleService` - Singleton
- `BleDevice` - Detected device data (trackerId, remoteId, rssi, detectedAt)
- `BleException` - BLE-specific errors

**IMPORTANT FUNCTIONS**:
- `scan({required Set<String> knownTrackerIds, int durationSeconds = 8})` 
  - Starts BLE scan using `flutter_blue_plus`
  - Scans for 8 seconds
  - Returns list of detected AssetGuard trackers
  - Filters by AG-XXX pattern or known tracker IDs
  - Captures RSSI (signal strength)

**INPUT**: Set of known tracker IDs from user's assets

**OUTPUT**: List of `BleDevice` objects

**CALLED BY**:
- `community_sensing_service.dart` - Background community detection
- `nearby_devices_screen.dart` - Manual scan feature

**CALLS**:
- `flutter_blue_plus` package - Platform-specific BLE APIs
- Android/iOS BLE stack via method channels

**DATA USED**: Tracker IDs from assets

**WHY IT EXISTS**: Core detection mechanism - finds lost assets via Bluetooth

**CRITICAL**: This file implements the working BLE pipeline. Do NOT modify casually.

---

#### `lib/services/wifi_scan_service.dart`
**PURPOSE**: Scans for Wi-Fi access points (AP) on campus

**IMPORTANT CLASSES**:
- `WifiScanService` - Singleton
- `WifiScanResult` - Abstract base class
- `WifiScanSuccess` - Successful scan with `List<AccessPoint> accessPoints`
- `WifiScanFailure` - Failed scan with reason
- `AccessPoint` - Wi-Fi AP data (bssid, ssid, rssi)

**IMPORTANT FUNCTIONS**:
- `scanNieAccessPoints()` - Performs Wi-Fi scan
  - Uses `wifi_scan` package
  - Filters only NIE-STUDENTS and NIE-STAFF networks
  - Returns BSSID (MAC address) + RSSI pairs
  - Converts to `Map<String, int>` (BSSID → RSSI mapping)

**INPUT**: None (scans all nearby Wi-Fi)

**OUTPUT**: `WifiScanResult` (success with AP list or failure with reason)

**CALLED BY**:
- `community_sensing_service.dart` - Automatic background Wi-Fi scanning

**CALLS**:
- `wifi_scan` package - Android Wi-Fi APIs
- `Permission.location` - Wi-Fi scanning requires location permission

**DATA USED**: Wi-Fi radio scan results from Android

**WHY IT EXISTS**: Collects Wi-Fi fingerprint for ML-based room prediction

---

#### `lib/services/wifi_fingerprint_cache.dart`
**PURPOSE**: Short-term cache for Wi-Fi fingerprints in memory

**IMPORTANT CLASSES**:
- `WifiFingerprintCache` - Singleton
- Fields:
  - `_fingerprint` - `Map<String, int>?` (BSSID → RSSI)
  - `_timestamp` - When cached
  - `_maxAge` - 2 minutes validity

**IMPORTANT FUNCTIONS**:
- `update(Map<String, int> fingerprint)` - Stores new fingerprint with timestamp
- `get()` - Returns cached fingerprint if age < 2 minutes, else null
- `_isExpired()` - Checks if cache is too old

**INPUT**: Wi-Fi scan results from `wifi_scan_service.dart`

**OUTPUT**: Cached fingerprint for BLE detections to use

**CALLED BY**:
- `community_sensing_service.dart` - Stores Wi-Fi scans
- `community_sensing_service.dart` - Retrieves during BLE detection

**WHY IT EXISTS**: 
- BLE and Wi-Fi scans happen independently (both every 15s)
- Cache ensures BLE detection can include recent Wi-Fi data
- 2-minute validity prevents stale data

**CRITICAL**: Must be updated and retrieved in the **same isolate** (main isolate) to work correctly

---

#### `lib/services/community_sensing_service.dart`
**PURPOSE**: Orchestrates background BLE + Wi-Fi scanning using foreground service

**IMPORTANT CLASSES**:
- `CommunitySensingService` - Singleton, main interface
- `_CommunitySensingTaskHandler` - Runs in foreground task isolate (minimal now)
- `CommunitySensingStartResult` - Enum for start() outcomes

**IMPORTANT FUNCTIONS**:
- `static initForegroundTask()` - Called once in `main()`, registers Android notification channel
- `start()` - Starts foreground service
  - Requests Bluetooth, Location permissions
  - Creates persistent notification
  - Starts two Timers in main isolate:
    - BLE scan every 15 seconds
    - Wi-Fi scan every 15 seconds
- `stop()` - Stops service and cancels timers
- `_startBleScanTimer()` - Creates `Timer.periodic(15s)` for BLE
- `_startWifiScanTimer()` - Creates `Timer.periodic(15s)` for Wi-Fi
- `_performBleScan()` - Executes BLE scan in main isolate
  - Gets known asset tracker IDs
  - Calls `BleService.scan()`
  - For each detected AssetGuard tracker:
    - Checks debounce (60s)
    - Retrieves cached Wi-Fi fingerprint
    - Calls `CommunityDetectionService.reportDetection()`
- `_performWifiScan()` - Executes Wi-Fi scan in main isolate
  - Calls `WifiScanService.scanNieAccessPoints()`
  - Updates `WifiFingerprintCache`
  - Uploads to backend (`POST /api/community/scan`)

**DATA USED**:
- Assets from `AssetService` (to know which tracker IDs to look for)
- Wi-Fi fingerprint from `WifiFingerprintCache`

**CALLED BY**:
- `home_screen.dart` - "Enable Community Sensing" button
- `profile_screen.dart` - "Disable Community Sensing" button

**CALLS**:
- `BleService.scan()` - BLE detection
- `WifiScanService.scanNieAccessPoints()` - Wi-Fi scan
- `WifiFingerprintCache.update()` and `get()` - Cache operations
- `CommunityDetectionService.reportDetection()` - Submit detection to backend

**WHY IT EXISTS**: 
- Community sensing = Help others find lost assets
- Background operation requires foreground service (Android requirement)
- Persistent notification keeps service alive

**CRITICAL**: This file orchestrates the entire community detection system. Do NOT modify BLE logic.

---

#### `lib/services/community_detection_service.dart`
**PURPOSE**: Reports detected trackers to backend

**IMPORTANT CLASSES**:
- `CommunityDetectionService` - Singleton

**IMPORTANT FUNCTIONS**:
- `shouldReport(String trackerId)` - Debounce check (60 seconds)
  - Prevents duplicate reports for same tracker
  - Tracks last report time per tracker ID
- `reportDetection({trackerId, rssi, remoteId, detectedAt, wifiFingerprint})` 
  - `POST /api/community/detections`
  - Includes optional Wi-Fi fingerprint for ML prediction
  - Gets current GPS location
  - Backend validates asset is LOST
  - Backend creates notification for owner
  - Returns true if successful

**INPUT**:
- Tracker ID (e.g., "AG-001")
- RSSI (signal strength)
- Optional Wi-Fi fingerprint `Map<String, int>`

**OUTPUT**: Boolean success/failure

**CALLED BY**:
- `community_sensing_service.dart` - For each detected tracker

**CALLS**:
- `LocationService.getPosition()` - GPS coordinates
- `ApiService.post('/api/community/detections')` - Backend API

**DATA USED**: Detection metadata, Wi-Fi fingerprint

**WHY IT EXISTS**: 
- Submits community detections to backend
- Backend handles owner lookup and notification
- Debouncing prevents spam

---

#### `lib/services/notification_service.dart`
**PURPOSE**: Fetches notifications for current user

**IMPORTANT FUNCTIONS**:
- `getNotifications()` - `GET /api/notifications`
  - Returns list of notifications
  - Includes ML room predictions
- `markAsRead(id)` - `PUT /api/notifications/:id/read`
- `markAllAsRead()` - `PUT /api/notifications/read-all`
- `getUnreadCount()` - `GET /api/notifications/unread/count` (for badge)

**CALLED BY**:
- `notifications_screen.dart` - Display notifications
- `home_screen.dart` - Show unread count badge

**WHY IT EXISTS**: Notification management

---

#### `lib/screens/home_screen.dart`
**PURPOSE**: Main dashboard showing asset statistics

**DISPLAYS**:
- Total Assets count
- Lost count (assets with status='LOST')
- Tracking count (LOST assets with recent community detections)
- Quick actions (Add Asset, View Notifications)
- Community Sensing toggle

**CALLS**:
- `DashboardService.getStats()` - `GET /api/dashboard/stats`
- `CommunitySensingService.start()` / `stop()`

**WHY IT EXISTS**: Main screen after login

---

#### `lib/screens/my_assets_screen.dart`
**PURPOSE**: Lists all user's assets

**DISPLAYS**:
- Asset cards (name, tracker ID, status, last seen)
- Tap to view details

**CALLS**:
- `AssetService.getAssets()` - `GET /api/assets`

---

#### `lib/screens/asset_details_screen.dart`
**PURPOSE**: View/edit single asset

**FEATURES**:
- Display asset info
- Edit button → `EditAssetScreen`
- Delete button → `DELETE /api/assets/:id`
- Mark as Lost button → `PUT /api/assets/:id/status` (status='LOST')
- Track Asset button → `TrackAssetScreen`
- Mark as Recovered button (if LOST) → `PUT /api/assets/:id/recover`

**CALLS**:
- `AssetService.markAsLost(id)`
- `AssetService.markAsRecovered(id)`
- `AssetService.deleteAsset(id)`

---

#### `lib/screens/track_asset_screen.dart`
**PURPOSE**: Map showing where asset was detected

**DISPLAYS**:
- Interactive map (`flutter_map` + OpenStreetMap tiles)
- Markers for each community detection
- Popup showing:
  - Detection timestamp
  - RSSI
  - Predicted room (if available)
  - Room confidence (if available)

**CALLS**:
- `GET /api/community/detections/asset/:assetId` - Fetch detection history

**DATA USED**:
- `CommunityDetection` records with latitude/longitude/predictedRoom

**WHY IT EXISTS**: Visual representation of where asset was seen

---

#### `lib/screens/notifications_screen.dart`
**PURPOSE**: List all notifications

**DISPLAYS**:
- Notification cards with:
  - Title, message, timestamp
  - Info chips: Tracker ID, Room (if predicted), RSSI, GPS, Time
  - Unread indicator (blue dot)
  - Room chip uses blue styling: 🚪 Room 310 (38%)

**CALLS**:
- `NotificationService.getNotifications()`
- `NotificationService.markAsRead(id)`

**WHY IT EXISTS**: Shows owner when their asset was detected

---

### BACKEND FILES

#### `backend/server.js`
**PURPOSE**: Entry point for Node.js backend

**IMPORTANT FUNCTIONS**:
- `start()` async function:
  - Loads `.env` environment variables
  - Connects to MongoDB via `connectDB()`
  - Starts Express server on port 5000

**CALLS**:
- `require('./src/app')` - Express app
- `require('./src/config/db')` - MongoDB connection

**WHY IT EXISTS**: Starts the backend server

---

#### `backend/src/app.js`
**PURPOSE**: Express application configuration

**IMPORTANT FUNCTIONS**:
- Sets up middleware:
  - `cors()` - Allow Flutter app to make requests
  - `express.json()` - Parse JSON request bodies
- Registers routes:
  - `/api/auth` → `authRoutes`
  - `/api/assets` → `assetRoutes`
  - `/api/community` → `communityRoutes`
  - `/api/notifications` → `notificationRoutes`
  - `/api/dashboard` → `dashboardRoutes`
- Error handling middleware

**WHY IT EXISTS**: Central Express app configuration

---

#### `backend/src/config/db.js`
**PURPOSE**: MongoDB connection setup

**IMPORTANT FUNCTIONS**:
- `connectDB()` - Connects to MongoDB using `mongoose.connect()`
  - Uses `MONGO_URI` from `.env`
  - Example: `mongodb://localhost:27017/assetguard_db`

**WHY IT EXISTS**: Database connection

---

#### `backend/src/models/User.js`
**PURPOSE**: MongoDB schema for users

**FIELDS**:
- `name` - Full name
- `email` - Unique email (indexed)
- `password` - Bcrypt hashed password
- `emailVerified` - Boolean (production requires verification)
- `emailVerificationToken` - Token for email verification
- `passwordResetToken` - Token for password reset
- `passwordResetExpires` - Token expiration timestamp
- `createdAt, updatedAt` - Timestamps

**METHODS**:
- `userSchema.pre('save')` - Hash password before saving
- `userSchema.methods.matchPassword(enteredPassword)` - Verify password

**WHY IT EXISTS**: User account data

---

#### `backend/src/models/Asset.js`
**PURPOSE**: MongoDB schema for assets

**FIELDS**:
- `name` - Asset name
- `category` - Category
- `description` - Optional description
- `trackerId` - BLE tracker ID (e.g., "AG-001")
- `status` - Enum: 'ACTIVE', 'LOST', 'RECOVERED'
- `lastDetectedLocation` - Location string
- `lastDetectedTime` - Timestamp
- `userId` - Reference to User (owner)
- `createdAt, updatedAt` - Timestamps

**INDEXES**:
- `{userId: 1, trackerId: 1}` - Unique (one tracker per user)
- `userId` - Find all assets for a user

**WHY IT EXISTS**: Asset data belonging to users

---

#### `backend/src/models/CommunityDetection.js`
**PURPOSE**: MongoDB schema for community detections

**FIELDS**:
- `trackerId` - Tracker ID that was detected
- `assetId` - Reference to Asset
- `detectedBy` - User ID of community member (User B)
- `rssi` - Signal strength
- `remoteId` - BLE MAC address
- `detectedAt` - When detected
- `latitude, longitude` - GPS coordinates (optional)
- `predictedRoom` - ML prediction (e.g., "310")
- `roomConfidence` - ML confidence (e.g., 0.38)
- `createdAt` - Timestamp

**INDEXES**:
- `assetId` - Find all detections for an asset
- `detectedBy` - Track who detected what
- `detectedAt` - Sort by time

**WHY IT EXISTS**: Records community detections for Track Asset feature

---

#### `backend/src/models/Notification.js`
**PURPOSE**: MongoDB schema for notifications

**FIELDS**:
- `recipient` - User ID (asset owner)
- `type` - Enum: 'asset_detected', 'asset_status_changed', 'system'
- `title` - Notification title
- `message` - Notification text (includes room if predicted)
- `assetId, detectionId, trackerId` - References
- `latitude, longitude, rssi, detectedAt` - Detection metadata
- `predictedRoom, roomConfidence` - ML prediction data
- `read` - Boolean flag
- `createdAt, updatedAt` - Timestamps

**INDEXES**:
- `{recipient: 1, read: 1, createdAt: -1}` - Efficient notification queries

**WHY IT EXISTS**: Stores notifications for asset owners

---

#### `backend/src/models/CommunityFingerprint.js`
**PURPOSE**: MongoDB schema for Wi-Fi scan data

**FIELDS**:
- `scannedBy` - User ID who scanned
- `wifiFingerprint` - Array of `{bssid: String, rssi: Number}`
- `timestamp` - When scanned
- `createdAt` - Auto timestamp

**WHY IT EXISTS**: Historical record of Wi-Fi scans (for analysis/debugging)

---

#### `backend/src/controllers/authController.js`
**PURPOSE**: Authentication logic

**IMPORTANT FUNCTIONS**:
- `register(req, res)` - `POST /api/auth/register`
  - Validates input
  - Creates user in MongoDB
  - In dev mode (`EMAIL_VERIFICATION_ENABLED=false`): Returns JWT immediately
  - In production: Sends verification email, requires email verification before login
- `login(req, res)` - `POST /api/auth/login`
  - Validates email/password
  - Checks `emailVerified` flag (production only)
  - Returns JWT token
- `verifyEmail(req, res)` - `GET /api/auth/verify-email?token=...`
  - Validates token
  - Sets `emailVerified = true`
  - Returns JWT (user is now logged in)
- `forgotPassword(req, res)` - `POST /api/auth/forgot-password`
  - Generates password reset token
  - Sends email with reset link
- `resetPassword(req, res)` - `POST /api/auth/reset-password`
  - Validates token
  - Updates password
- `getMe(req, res)` - `GET /api/auth/me`
  - Returns current user info (requires JWT)

**CALLS**:
- `User.create()` - MongoDB insert
- `User.findOne()` - MongoDB query
- `bcrypt.hash()` - Password hashing
- `jwt.sign()` - Generate JWT
- `emailService.sendVerificationEmail()` - Send emails

**CALLED BY**: `authRoutes.js` → Express router

**WHY IT EXISTS**: Handles user authentication

---

#### `backend/src/controllers/assetController.js`
**PURPOSE**: Asset CRUD operations

**IMPORTANT FUNCTIONS**:
- `getAssets(req, res)` - `GET /api/assets`
  - Returns all assets for authenticated user (`req.user._id`)
- `getAsset(req, res)` - `GET /api/assets/:id`
  - Returns single asset (ownership verified)
- `createAsset(req, res)` - `POST /api/assets`
  - Creates new asset
  - Sets `userId = req.user._id`
  - Validates unique tracker ID per user
- `updateAsset(req, res)` - `PUT /api/assets/:id`
  - Updates asset fields (ownership verified)
- `deleteAsset(req, res)` - `DELETE /api/assets/:id`
  - Removes asset (ownership verified)
- `updateStatus(req, res)` - `PUT /api/assets/:id/status`
  - Changes asset status to LOST
- `recoverAsset(req, res)` - `PUT /api/assets/:id/recover`
  - Changes status to RECOVERED
  - Future community detections will be ignored

**SECURITY**:
- All routes require JWT authentication (`protect` middleware)
- Ownership verification: `asset.userId === req.user._id`

**CALLED BY**: `assetRoutes.js`

**WHY IT EXISTS**: Asset management logic

---

#### `backend/src/controllers/communityController.js`
**PURPOSE**: Community detection + ML integration

**CRITICAL FUNCTION**: `submitCommunityDetection(req, res)` - `POST /api/community/detections`

**FLOW**:
1. Receives detection from User B:
   - `trackerId` (e.g., "AG-001")
   - `rssi` (signal strength)
   - `detectedAt` (timestamp)
   - `latitude, longitude` (GPS from User B's phone)
   - `wifiFingerprint` (optional: `{bssid: rssi}` map)

2. Looks up asset by `trackerId` (cross-user lookup)

3. **CRITICAL CHECK**: Asset must have `status = 'LOST'`
   - If ACTIVE or RECOVERED → Returns 404 (detection ignored)
   - Prevents notifications for recovered assets

4. **SECURITY CHECK**: Detector cannot be the asset owner
   - If `req.user._id === asset.userId` → Returns 404
   - Prevents owner from reporting their own asset

5. **ML Room Prediction** (if Wi-Fi fingerprint provided):
   - Calls Python ML server: `POST http://10.135.90.221:8000/predict-room`
   - Request body: `{wifi: {bssid: rssi, ...}}`
   - Response: `{room: "310", confidence: 0.376667}`
   - Timeout: 10 seconds
   - Failure: Graceful degradation (detection succeeds without room)

6. Creates `CommunityDetection` record in MongoDB:
   - Stores all detection data
   - Includes `predictedRoom` and `roomConfidence`

7. Creates `Notification` for asset owner:
   - Recipient: `asset.userId` (User A)
   - Type: 'asset_detected'
   - Message:
     - With room: "Your Laptop (AG-001) was detected near Room 310. (38% confidence)"
     - Without room: "Your Laptop (AG-001) was detected at [GPS coords]."
   - Stores `predictedRoom` and `roomConfidence` fields

8. Returns success response with predicted room (if available)

**OTHER FUNCTIONS**:
- `submitScan(req, res)` - `POST /api/community/scan`
  - Stores raw Wi-Fi fingerprint for historical analysis
  - Called by automatic Wi-Fi scanning

**CALLED BY**: `communityRoutes.js`

**CALLS**:
- `Asset.findOne({trackerId})` - Find asset by tracker ID
- `fetch(ML_API_URL)` - Call Python ML server
- `CommunityDetection.create()` - Store detection
- `Notification.create()` - Create notification

**WHY IT EXISTS**: 
- Core community detection logic
- ML integration for room prediction
- Owner notification generation

**CRITICAL**: This is the heart of the community detection system. Do NOT modify the LOST asset check or ML integration without understanding the complete flow.

---

#### `backend/src/controllers/notificationController.js`
**PURPOSE**: Notification management

**IMPORTANT FUNCTIONS**:
- `getNotifications(req, res)` - `GET /api/notifications`
  - Returns notifications for `req.user._id`
  - Sorted: unread first, then newest first
  - Includes all fields (predictedRoom, roomConfidence)
- `markAsRead(req, res)` - `PUT /api/notifications/:id/read`
  - Updates `read = true`
- `markAllAsRead(req, res)` - `PUT /api/notifications/read-all`
  - Bulk update
- `getUnreadCount(req, res)` - `GET /api/notifications/unread/count`
  - Returns count for badge

**CALLED BY**: `notificationRoutes.js`

**WHY IT EXISTS**: Notification retrieval for Flutter app

---

#### `backend/src/controllers/dashboardController.js`
**PURPOSE**: Dashboard statistics

**IMPORTANT FUNCTIONS**:
- `getStats(req, res)` - `GET /api/dashboard/stats`
  - Counts total assets
  - Counts LOST assets
  - Counts "tracking" assets (LOST with recent community detections)
  - Query: LOST assets with CommunityDetection in last 7 days

**CALLED BY**: `dashboardRoutes.js`

**WHY IT EXISTS**: Powers home screen dashboard

---

#### `backend/src/middleware/auth.js`
**PURPOSE**: JWT authentication middleware

**IMPORTANT FUNCTIONS**:
- `protect(req, res, next)` - Verifies JWT token
  - Extracts token from `Authorization: Bearer <token>` header
  - Verifies with `jwt.verify()`
  - Looks up user in MongoDB
  - Attaches user to `req.user`
  - Calls `next()` if valid
  - Returns 401 if invalid

**USED BY**: All protected routes (most routes)

**WHY IT EXISTS**: Secures API endpoints

---

#### `backend/src/routes/*.js`
**PURPOSE**: API endpoint definitions

Example: `backend/src/routes/communityRoutes.js`
```javascript
router.use(protect); // All routes require authentication
router.post('/scan', submitScanValidators, validate, submitScan);
router.post('/detections', submitCommunityDetectionValidators, validate, submitCommunityDetection);
router.get('/detections/asset/:assetId', getDetectionsForAsset);
```

**WHY ROUTES EXIST**: Define HTTP method + path → controller function mapping

---


## PART 3: APPLICATION STARTUP WORKFLOW

### What Happens When You Open the App

```
User taps AssetGuard icon
↓
Android starts app process
↓
lib/main.dart → main() function
↓
WidgetsFlutterBinding.ensureInitialized()  [Initialize Flutter framework]
↓
CommunitySensingService.initForegroundTask()  [Register notification channel for background scanning]
↓
SystemChrome.setPreferredOrientations([portrait])  [Lock screen orientation]
↓
runApp(AssetGuardApp())  [Start Flutter widget tree]
↓
AssetGuardApp builds MaterialApp
↓
First screen: SplashScreen()
↓
SplashScreen.initState() runs
↓
AuthService.instance.tryAutoLogin()  [Check for saved JWT]
  ├─ SharedPreferences.getInstance()  [Read from device storage]
  ├─ prefs.getString('auth_token')  [Get saved token]
  ├─ If no token → Navigate to LoginScreen
  └─ If token exists:
      ├─ ApiService.instance.setToken(token)  [Set token for HTTP requests]
      ├─ GET /api/auth/me  [Validate token with backend]
      ├─ If valid (200 OK) → Parse user data → Navigate to HomeScreen
      └─ If invalid (401) → Clear token → Navigate to LoginScreen
```

**FILES INVOLVED**:
1. `lib/main.dart` - Entry point
2. `lib/screens/splash_screen.dart` - Auto-login check
3. `lib/services/auth_service.dart` - Token validation
4. `lib/services/api_service.dart` - HTTP request
5. `backend/src/controllers/authController.js` - `/api/auth/me` endpoint
6. `backend/src/middleware/auth.js` - JWT verification

---

## PART 4: LOGIN / AUTHENTICATION WORKFLOW

### Registration Flow

```
User fills registration form (name, email, password)
↓
Taps "Register" button
↓
lib/screens/register_screen.dart
↓
AuthService.instance.register(name, email, password)
↓
ApiService.instance.post('/api/auth/register', {name, email, password})
↓
HTTP POST → backend:5000/api/auth/register
↓
backend/src/routes/authRoutes.js receives request
↓
backend/src/controllers/authController.js → register()
↓
Validate input (name not empty, valid email, password >= 6 chars)
↓
Check if email already exists in MongoDB:
  User.findOne({email})
  ├─ If exists → Return 400 "Email already registered"
  └─ If not exists → Continue
↓
Hash password: bcrypt.hash(password, 10)
↓
Create user in MongoDB:
  User.create({name, email, password: hashedPassword})
↓
Check EMAIL_VERIFICATION_ENABLED environment variable:
  ├─ If false (development mode):
  │   ├─ Set emailVerified = true immediately
  │   ├─ Generate JWT: jwt.sign({userId}, SECRET, {expiresIn: '7d'})
  │   └─ Return {token, user, message: "Account created..."}
  └─ If true (production mode):
      ├─ Generate verification token: crypto.randomBytes(32)
      ├─ Save token: user.emailVerificationToken = token
      ├─ Send verification email: emailService.sendVerificationEmail(email, token)
      └─ Return {message: "Please check your email to verify..."}
↓
Flutter receives response:
  ├─ If token included → Auto-login → Navigate to HomeScreen
  └─ If no token → Show "Check your email" message → Stay on RegisterScreen
```

**KEY POINTS**:
- **Development mode**: Bypass email verification for faster testing
- **Production mode**: Require email verification for security
- Passwords are **never** stored in plain text (bcrypt hashing)
- JWT token expires after 7 days

---

### Login Flow

```
User enters email + password
↓
Taps "Login" button
↓
lib/screens/login_screen.dart
↓
AuthService.instance.login(email, password)
↓
ApiService.instance.post('/api/auth/login', {email, password})
↓
HTTP POST → backend:5000/api/auth/login
↓
backend/src/controllers/authController.js → login()
↓
Find user: User.findOne({email}).select('+password')
  ├─ If not found → Return 401 "Invalid credentials"
  └─ If found → Continue
↓
Verify password: bcrypt.compare(enteredPassword, user.password)
  ├─ If mismatch → Return 401 "Invalid credentials"
  └─ If match → Continue
↓
Check emailVerified flag (production only):
  ├─ If false → Return 403 "Please verify your email first"
  └─ If true → Continue
↓
Generate JWT: jwt.sign({userId: user._id}, SECRET, {expiresIn: '7d'})
↓
Return {token, user: {_id, name, email}}
↓
Flutter receives response:
↓
AuthService._handleAuthResponse(data):
  ├─ Store token in memory: ApiService.instance.setToken(token)
  ├─ Store user data: _currentUser = UserModel.fromJson(user)
  └─ Persist token to device: SharedPreferences.setString('auth_token', token)
↓
Navigate to HomeScreen
```

**JWT Token Structure**:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NzU4ZmE5ZjIzNGFiY2RlZjEyMzQ1NjciLCJpYXQiOjE3MzM5NTY4MDAsImV4cCI6MTczNDU2MTYwMH0.signature
```
Decoded payload: `{userId: "...", iat: 1733956800, exp: 1734561600}`

---

### Authenticated API Calls

**Every API request after login**:

```
Flutter service calls ApiService.get() or .post()
↓
ApiService._headers getter:
  {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer <JWT_TOKEN>'  ← Automatically added
  }
↓
HTTP request sent to backend
↓
backend/src/middleware/auth.js → protect() middleware:
  ├─ Extract token from Authorization header
  ├─ Verify signature: jwt.verify(token, SECRET)
  ├─ If invalid → Return 401 "Not authorized"
  ├─ If expired → Return 401 "Token expired"
  └─ If valid:
      ├─ Extract userId from token
      ├─ Look up user: User.findById(userId)
      ├─ Attach to request: req.user = user
      └─ Call next() → Proceed to controller
↓
Controller receives req.user (authenticated user object)
↓
Controller can now:
  ├─ Create records owned by req.user._id
  ├─ Query records filtered by req.user._id
  └─ Verify ownership before update/delete
```

**Example - Creating Asset**:
```javascript
// backend/src/controllers/assetController.js
const createAsset = async (req, res) => {
  const asset = await Asset.create({
    name: req.body.name,
    trackerId: req.body.trackerId,
    userId: req.user._id,  // ← From JWT (User A)
    // ...
  });
};
```

---

### Logout Flow

```
User taps "Logout" button
↓
lib/screens/profile_screen.dart
↓
AuthService.instance.logout()
↓
  ├─ Clear in-memory user: _currentUser = null
  ├─ Clear ApiService token: ApiService.instance.setToken(null)
  └─ Clear persisted token: SharedPreferences.remove('auth_token')
↓
Navigate to LoginScreen
```

**Note**: Backend doesn't track sessions. JWT is stateless. Logout only clears client-side data.

---

## PART 5: ASSET MANAGEMENT

### Creating an Asset

```
User taps "Add Asset" button on HomeScreen
↓
Navigate to AddAssetScreen
↓
User fills form:
  ├─ Asset Name (e.g., "Laptop")
  ├─ Category (e.g., "Electronics")
  ├─ Description (optional)
  └─ Tracker ID (e.g., "AG-001") ← Must be unique per user
↓
Taps "Add Asset" button
↓
lib/screens/add_asset_screen.dart → _submitAsset()
↓
Validate inputs client-side (not empty, tracker ID format)
↓
AssetService.instance.createAsset(asset)
↓
ApiService.instance.post('/api/assets', asset.toJson())
↓
HTTP POST → backend:5000/api/assets
↓
backend/src/middleware/auth.js → protect() verifies JWT
↓
backend/src/controllers/assetController.js → createAsset()
↓
Validate input:
  ├─ name required (max 100 chars)
  ├─ category required (max 50 chars)
  └─ trackerId required (max 50 chars)
↓
Check uniqueness:
  Asset.findOne({userId: req.user._id, trackerId: req.body.trackerId})
  ├─ If exists → Return 400 "Tracker ID already in use"
  └─ If not exists → Continue
↓
Create asset in MongoDB:
  Asset.create({
    name, category, description, trackerId,
    userId: req.user._id,  ← Owner is authenticated user
    status: 'ACTIVE',      ← Default status
    lastDetectedLocation: null,
    lastDetectedTime: null,
  })
↓
Return created asset: {_id, name, category, trackerId, status, ...}
↓
Flutter receives response → Navigate back to MyAssetsScreen
↓
MyAssetsScreen refreshes asset list → New asset appears
```

**KEY POINTS**:
- Tracker ID must be unique **per user** (not globally unique)
- Multiple users can have different assets with same tracker ID
- Asset is immediately in 'ACTIVE' status

---

### Viewing Assets

```
User taps "My Assets" tab
↓
lib/screens/my_assets_screen.dart
↓
initState() → _loadAssets()
↓
AssetService.instance.getAssets()
↓
ApiService.instance.get('/api/assets')
↓
HTTP GET → backend:5000/api/assets
↓
backend/src/controllers/assetController.js → getAssets()
↓
Query MongoDB:
  Asset.find({userId: req.user._id})  ← Only user's own assets
       .sort({createdAt: -1})         ← Newest first
↓
Return array of assets
↓
Flutter converts to List<Asset> → Display as cards
```

---

### Editing an Asset

```
User taps asset card → AssetDetailsScreen
↓
Taps "Edit" button → EditAssetScreen
↓
User modifies name/category/description (Tracker ID cannot be changed)
↓
Taps "Save"
↓
AssetService.instance.updateAsset(asset)
↓
ApiService.instance.put('/api/assets/${asset.id}', asset.toJson())
↓
HTTP PUT → backend:5000/api/assets/:id
↓
backend/src/controllers/assetController.js → updateAsset()
↓
Verify ownership:
  Asset.findOne({_id: req.params.id, userId: req.user._id})
  ├─ If not found → Return 404
  └─ If found → Continue
↓
Update fields:
  asset.name = req.body.name
  asset.category = req.body.category
  asset.description = req.body.description
  await asset.save()
↓
Return updated asset
↓
Flutter updates UI → Navigate back
```

**SECURITY**: Ownership check prevents User A from editing User B's assets

---

### Deleting an Asset

```
User taps "Delete" button on AssetDetailsScreen
↓
Confirmation dialog: "Are you sure?"
↓
User confirms
↓
AssetService.instance.deleteAsset(asset.id)
↓
ApiService.instance.delete('/api/assets/${asset.id}')
↓
HTTP DELETE → backend:5000/api/assets/:id
↓
backend/src/controllers/assetController.js → deleteAsset()
↓
Verify ownership:
  Asset.findOneAndDelete({_id: req.params.id, userId: req.user._id})
  ├─ If not found → Return 404
  └─ If found → Delete from MongoDB
↓
Return success message
↓
Flutter navigates back → Asset removed from list
```

---

## PART 6: ASSET STATES

### Asset Lifecycle

```
ACTIVE (default)
  ↓
  User marks as LOST
  ↓
LOST (community sensing active)
  ↓
  User marks as RECOVERED
  ↓
RECOVERED (detections ignored)
```

### State Transition Details

#### ACTIVE → LOST

```
User taps "Mark as Lost" on AssetDetailsScreen
↓
AssetService.instance.markAsLost(asset.id)
↓
ApiService.instance.put('/api/assets/${asset.id}/status', {status: 'LOST'})
↓
HTTP PUT → backend:5000/api/assets/:id/status
↓
backend/src/controllers/assetController.js → updateStatus()
↓
Verify ownership + update:
  Asset.findOneAndUpdate(
    {_id: req.params.id, userId: req.user._id},
    {status: 'LOST'},
    {new: true}
  )
↓
Return updated asset with status='LOST'
↓
Flutter updates UI:
  ├─ Asset card shows red "LOST" badge
  ├─ "Track Asset" button appears
  └─ "Mark as Recovered" button appears
```

**WHAT HAPPENS WHEN ASSET IS LOST**:

1. **Community Sensing Effect**:
   - Other users' phones (User B, C, D...) running Community Sensing will scan for BLE trackers
   - If they detect this asset's tracker ID (e.g., "AG-001"):
     - Detection sent to backend (`POST /api/community/detections`)
     - Backend checks asset status
     - **ONLY IF status='LOST'** → Create notification for owner
     - If status='ACTIVE' or 'RECOVERED' → Detection ignored (returns 404)

2. **Owner Notification**:
   - User A receives notification: "Your Laptop (AG-001) was detected near Room 310"
   - Notification includes GPS coordinates + ML room prediction

3. **Track Asset**:
   - User A can view map showing all detection locations

---

#### LOST → RECOVERED

```
User finds their asset physically
↓
Taps "Mark as Recovered" on AssetDetailsScreen
↓
AssetService.instance.markAsRecovered(asset.id)
↓
ApiService.instance.put('/api/assets/${asset.id}/recover')
↓
HTTP PUT → backend:5000/api/assets/:id/recover
↓
backend/src/controllers/assetController.js → recoverAsset()
↓
Verify ownership + update:
  Asset.findOneAndUpdate(
    {_id: req.params.id, userId: req.user._id},
    {status: 'RECOVERED'},
    {new: true}
  )
↓
Return updated asset with status='RECOVERED'
↓
Flutter updates UI:
  ├─ Asset card shows green "RECOVERED" badge
  ├─ "Mark as Lost" button reappears
  └─ "Mark as Recovered" button disappears
```

**CRITICAL BEHAVIOR AFTER RECOVERY**:

1. **Future Detections Ignored**:
   - If User B's phone detects "AG-001" again
   - Detection submitted: `POST /api/community/detections`
   - Backend checks: `asset.status === 'LOST'` ?
   - **NO** (status is 'RECOVERED') → Return 404 "Asset not found"
   - **NO notification created**
   - **NO database record created**

2. **Why This Matters**:
   - Prevents spam notifications after user recovers asset
   - User A won't receive "asset detected" notifications for an asset they already have
   - Backend enforces this at API level (line 141 in `communityController.js`):
   ```javascript
   if (asset.status !== 'LOST') {
     return error(res, `Asset not found`, 404);
   }
   ```

3. **Dashboard Impact**:
   - "Lost" count decreases by 1
   - "Tracking" count decreases by 1 (if asset had recent detections)

---

### State Enforcement Files

**Flutter**:
- `lib/models/asset_model.dart` - Status field definition
- `lib/services/asset_service.dart` - `markAsLost()`, `markAsRecovered()` methods
- `lib/screens/asset_details_screen.dart` - UI buttons

**Backend**:
- `backend/src/models/Asset.js` - Status enum validation
- `backend/src/controllers/assetController.js` - `updateStatus()`, `recoverAsset()`
- `backend/src/controllers/communityController.js` - Lines 130-148: **CRITICAL CHECK**

**CRITICAL CODE** (backend/src/controllers/communityController.js):
```javascript
// Only accept detections for LOST assets
if (asset.status !== 'LOST') {
  console.log('[Community] Detection ignored — asset', trackerId, 'is', asset.status);
  return error(res, `Asset with trackerId "${trackerId}" not found`, 404);
}
```
**DO NOT MODIFY THIS CHECK** - It prevents recovered assets from generating notifications.

---


## PART 7: BLE (BLUETOOTH LOW ENERGY) SYSTEM

### Why BLE?

1. **Low Power**: BLE trackers can run for months on a coin battery
2. **Range**: 10-50 meters indoors (enough for campus buildings)
3. **Privacy**: No internet required, works offline
4. **Ubiquitous**: Every modern smartphone has BLE
5. **Proximity Detection**: RSSI (signal strength) indicates distance

---

### BLE Package Used

**Package**: `flutter_blue_plus: ^1.35.5` (in `pubspec.yaml`)

**Why This Package**:
- Most popular Flutter BLE library
- Supports Android + iOS
- Active maintenance
- Platform channels to native Bluetooth APIs

---

### BLE Permissions

**Android Permissions** (in `android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**Why Location Permission for BLE**:
- Android security requirement (Android 6.0+)
- BLE can determine location → Treated as location data
- Even though AssetGuard doesn't use BLE for navigation

**Requested in**: `lib/services/permission_service.dart` and `lib/services/community_sensing_service.dart`

---

### BLE Scanning Process

**File**: `lib/services/ble_service.dart`

**Key Function**: `scan({required Set<String> knownTrackerIds, int durationSeconds = 8})`

```dart
Future<List<BleDevice>> scan({
  required Set<String> knownTrackerIds,
  int durationSeconds = 8,
}) async {
  // 1. Check Bluetooth is available
  if (!await FlutterBluePlus.isSupported) {
    throw BleException('Bluetooth not supported');
  }

  // 2. Check Bluetooth is turned on
  if (await FlutterBluePlus.adapterState != BluetoothAdapterState.on) {
    throw BleException('Bluetooth is turned off');
  }

  // 3. Start scanning
  List<BleDevice> devices = [];
  FlutterBluePlus.scanResults.listen((results) {
    for (ScanResult r in results) {
      // Extract device name (contains tracker ID)
      String deviceName = r.device.platformName;
      String trackerId = _extractTrackerId(deviceName);
      
      // Filter: Only AssetGuard trackers (AG-XXX or known IDs)
      if (_isAssetGuardTracker(trackerId, knownTrackerIds)) {
        devices.add(BleDevice(
          trackerId: trackerId,
          deviceName: deviceName,
          remoteId: r.device.remoteId.toString(),
          rssi: r.rssi,  // Signal strength
          detectedAt: DateTime.now(),
        ));
      }
    }
  });

  // 4. Scan for 8 seconds
  await FlutterBluePlus.startScan(timeout: Duration(seconds: durationSeconds));

  // 5. Return detected devices
  return devices;
}
```

**BLE Scan Parameters**:
- **Duration**: 8 seconds per scan
- **Interval**: Every 15 seconds (controlled by Timer in `community_sensing_service.dart`)
- **Filter**: Only devices matching `AG-XXX` pattern or known tracker IDs

---

### Tracker ID Detection

**How Tracker ID is Extracted**:
1. BLE device broadcasts its name (e.g., "AssetGuard-AG-001")
2. `_extractTrackerId()` extracts "AG-001" from device name
3. Matches against pattern: `^AG-\d+$` (AG- followed by numbers)
4. Also checks against `knownTrackerIds` (user's registered assets)

**Example**:
- Device name: "AssetGuard-AG-001"
- Extracted tracker ID: "AG-001"
- Matches pattern → Detected as AssetGuard tracker

---

### RSSI (Received Signal Strength Indicator)

**What is RSSI?**
- Measure of signal strength in dBm (decibels relative to 1 milliwatt)
- Range: -120 dBm (weak) to 0 dBm (strong)
- Typical values: -90 dBm (far), -67 dBm (medium), -40 dBm (close)

**Example**:
- RSSI = -40 dBm → Tracker is very close (< 1 meter)
- RSSI = -67 dBm → Medium distance (5-10 meters)
- RSSI = -90 dBm → Far away (20+ meters)

**Used For**:
- Proximity estimation
- Debugging (displayed in notifications and Track Asset)
- Not used for room prediction (Wi-Fi fingerprinting is more accurate)

---

### Debounce Logic

**Purpose**: Prevent duplicate notifications for the same tracker

**Implementation**: `lib/services/community_detection_service.dart`

```dart
// In-memory map: trackerId → last reported timestamp
final Map<String, DateTime> _lastReported = {};

bool shouldReport(String trackerId) {
  final lastTime = _lastReported[trackerId];
  if (lastTime == null) return true; // Never reported
  
  final elapsed = DateTime.now().difference(lastTime).inSeconds;
  return elapsed >= 60; // 60 second debounce
}
```

**Flow**:
```
User B detects AG-001 at 10:00:00 → Report to backend ✓
User B detects AG-001 at 10:00:30 → Skip (< 60s) ✗
User B detects AG-001 at 10:01:05 → Report to backend ✓ (>60s elapsed)
```

**Why 60 Seconds?**
- Balance between:
  - Too short → Spam notifications
  - Too long → Miss movement (if asset moves to different room)
- Configurable in `lib/utils/community_detection_config.dart`

---

### BLE Background Scanning

**Challenge**: Android kills background tasks aggressively

**Solution**: Foreground Service with persistent notification

**Implementation**: `lib/services/community_sensing_service.dart`

**Package**: `flutter_foreground_task: ^8.15.0`

**How It Works**:
1. User enables "Community Sensing" → Starts foreground service
2. Android displays persistent notification: "Community sensing active..."
3. Service is protected from being killed (Android requirement for location/BLE)
4. BLE scan runs every 15 seconds via `Timer.periodic()`
5. Runs even when app is in background or screen is off

**Android Requirement**:
- Foreground services **must** show a notification
- User can see service is running
- Transparency: User knows background scanning is active

---

### Complete BLE Detection Flow

```
Timer triggers (every 15 seconds)
↓
community_sensing_service.dart → _performBleScan()
↓
Get known tracker IDs:
  AssetService.instance.getAssets() → Extract trackerId from each asset
↓
BleService.instance.scan(knownTrackerIds, durationSeconds: 8)
↓
flutter_blue_plus starts BLE scan for 8 seconds
↓
For each detected BLE device:
  ├─ Extract device name → Parse tracker ID
  ├─ Filter: Is it AssetGuard tracker? (AG-XXX pattern or in knownTrackerIds)
  ├─ If yes: Create BleDevice(trackerId, rssi, remoteId, detectedAt)
  └─ If no: Ignore
↓
BLE scan completes → Returns List<BleDevice>
↓
For each detected AssetGuard tracker (e.g., "AG-001"):
  ├─ Check debounce: shouldReport(trackerId)?
  │   ├─ If < 60s since last report → Skip
  │   └─ If > 60s or never reported → Continue
  ├─ Get cached Wi-Fi fingerprint:
  │   WifiFingerprintCache.instance.get()
  │   ├─ If available (< 2 min old) → Include in detection
  │   └─ If expired/empty → Detection without Wi-Fi
  └─ Submit detection:
      CommunityDetectionService.instance.reportDetection(
        trackerId: "AG-001",
        rssi: -67,
        remoteId: "AA:BB:CC:DD:EE:FF",
        detectedAt: DateTime.now(),
        wifiFingerprint: {bssid: rssi, ...}  // Optional
      )
↓
reportDetection() sends to backend:
  POST /api/community/detections
  Body: {trackerId, rssi, detectedAt, latitude, longitude, wifiFingerprint}
↓
Backend processes (see PART 13 for details)
```

---

### Files Implementing BLE

**CRITICAL FILES** (Do NOT modify without understanding complete flow):

1. **`lib/services/ble_service.dart`**
   - BLE scanning implementation
   - Device filtering
   - RSSI capture
   - Platform channel communication

2. **`lib/services/community_sensing_service.dart`**
   - Background scan orchestration
   - Timer management (15s interval)
   - Foreground service
   - BLE + Wi-Fi coordination

3. **`lib/services/community_detection_service.dart`**
   - Debounce logic (60s)
   - Detection submission to backend

**Supporting Files**:
- `lib/models/detection_model.dart` - BleDevice data class
- `lib/utils/community_detection_config.dart` - Timing constants
- `android/app/src/main/AndroidManifest.xml` - Permissions

---

## PART 8: WI-FI SYSTEM

### Why Wi-Fi Fingerprinting?

1. **Indoor Accuracy**: GPS doesn't work indoors
2. **Room-Level Precision**: Wi-Fi can distinguish between adjacent rooms
3. **No Additional Hardware**: Uses existing Wi-Fi APs (NIE-STUDENTS, NIE-STAFF)
4. **ML-Ready**: BSSID + RSSI patterns are perfect for machine learning
5. **Passive**: No need to connect to Wi-Fi, just scan

---

### What is a Wi-Fi Fingerprint?

**Simple Definition**:
- A snapshot of all visible Wi-Fi access points and their signal strengths
- Like a "location signature" unique to each room

**Technical Definition**:
- Map of `BSSID → RSSI` pairs
- BSSID = MAC address of Wi-Fi access point (e.g., "84:d8:1b:aa:bb:cc")
- RSSI = Signal strength in dBm (e.g., -67)

**Example Fingerprint** (Room 310):
```json
{
  "84:d8:1b:aa:bb:cc": -43,
  "84:d8:1b:11:22:33": -67,
  "84:d8:1b:44:55:66": -72,
  ... (74 BSSIDs total)
}
```

**Why It Works**:
- Different rooms see different sets of APs
- Same APs have different signal strengths from different locations
- ML model learns these patterns during training

---

### Wi-Fi Scanning Package

**Package**: `wifi_scan: ^0.4.1` (in `pubspec.yaml`)

**Why This Package**:
- Android Wi-Fi scanning API wrapper
- Returns BSSID, SSID, RSSI for each AP
- Doesn't require connecting to Wi-Fi

---

### Wi-Fi Permissions

**Android Permissions** (in `AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

**Why Location Permission for Wi-Fi**:
- Same reason as BLE
- Wi-Fi scanning can determine location
- Android security requirement

---

### Wi-Fi Scanning Process

**File**: `lib/services/wifi_scan_service.dart`

**Key Function**: `scanNieAccessPoints()`

```dart
Future<WifiScanResult> scanNieAccessPoints() async {
  // 1. Check Wi-Fi permission
  final status = await Permission.location.status;
  if (!status.isGranted) {
    return WifiScanFailure('Location permission not granted');
  }

  // 2. Check if Wi-Fi can scan
  final canScan = await WiFiScan.instance.canStartScan();
  if (!canScan) {
    return WifiScanFailure('Cannot start Wi-Fi scan');
  }

  // 3. Start Wi-Fi scan
  await WiFiScan.instance.startScan();

  // 4. Get scan results
  final results = await WiFiScan.instance.getScannedResults();

  // 5. Filter only NIE networks
  final nieAps = results.where((ap) {
    final ssid = ap.ssid.toUpperCase();
    return ssid == 'NIE-STUDENTS' || ssid == 'NIE-STAFF';
  }).toList();

  // 6. If no NIE APs found
  if (nieAps.isEmpty) {
    return WifiScanFailure('No NIE access points found');
  }

  // 7. Convert to AccessPoint objects
  final accessPoints = nieAps.map((ap) => AccessPoint(
    bssid: ap.bssid,  // MAC address
    ssid: ap.ssid,    // Network name
    rssi: ap.level,   // Signal strength
  )).toList();

  // 8. Return success with AP list
  return WifiScanSuccess(accessPoints);
}
```

**Filtering**: Only NIE-STUDENTS and NIE-STAFF networks
- Campus-specific filtering
- Ignores home/mobile hotspot Wi-Fi
- Ensures fingerprints are from campus infrastructure

---

### Automatic Wi-Fi Scanning

**File**: `lib/services/community_sensing_service.dart`

**Implementation**: Timer in main isolate (same pattern as BLE)

```dart
void _startWifiScanTimer() {
  _wifiScanTimer = Timer.periodic(const Duration(seconds: 15), (_) {
    _performWifiScan();
  });
}

Future<void> _performWifiScan() async {
  // 1. Scan for Wi-Fi APs
  final result = await WifiScanService.instance.scanNieAccessPoints();

  if (result is WifiScanSuccess) {
    // 2. Convert to BSSID → RSSI map
    final fingerprint = result.toRssiMap();
    // Example: {"84:d8:1b:aa:bb:cc": -43, ...}

    // 3. Update cache FIRST (critical for BLE detections)
    WifiFingerprintCache.instance.update(fingerprint);

    // 4. Upload to backend for historical tracking
    try {
      await ApiService.instance.post('/api/community/scan', {
        'wifiFingerprint': fingerprint.entries
          .map((e) => {'bssid': e.key, 'rssi': e.value})
          .toList(),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Upload failure doesn't affect cache → Room prediction still works
    }
  }
}
```

**Scan Interval**: 15 seconds (same as BLE)

**Why 15 Seconds?**
- Frequent enough to capture movement
- Not too aggressive (battery/performance)
- Matches BLE interval for coordination

---

### BSSID (Basic Service Set Identifier)

**What is BSSID?**
- MAC address of Wi-Fi access point
- Uniquely identifies each AP
- Format: "XX:XX:XX:XX:XX:XX" (6 hex bytes)
- Example: "84:d8:1b:aa:bb:cc"

**BSSID vs SSID**:
- **SSID**: Network name (e.g., "NIE-STUDENTS") - Same across many APs
- **BSSID**: Specific AP hardware address - Unique per AP

**Why BSSID Matters**:
- Campus has multiple APs with same SSID ("NIE-STUDENTS")
- Each AP has different BSSID
- Different rooms see different BSSIDs
- **BSSID is the feature for ML model**

**Example**:
```
Room 310 sees:
  - BSSID "84:d8:1b:aa:bb:cc" (nearby AP)
  - BSSID "84:d8:1b:11:22:33" (medium distance)
  - BSSID "84:d8:1b:44:55:66" (far)

Room 312 sees:
  - BSSID "84:d8:1b:77:88:99" (nearby AP)  ← Different!
  - BSSID "84:d8:1b:aa:bb:cc" (medium)
  - BSSID "84:d8:1b:11:22:33" (far)
```

ML model learns which BSSID combinations = which room

---

### Wi-Fi Fingerprint Format

**Captured Format** (Flutter):
```dart
Map<String, int> fingerprint = {
  "84:d8:1b:aa:bb:cc": -43,  // Strong signal
  "84:d8:1b:11:22:33": -67,  // Medium signal
  "84:d8:1b:44:55:66": -89,  // Weak signal
  // ... 70+ more BSSIDs
};
```

**Sent to Backend** (API format):
```json
{
  "wifiFingerprint": [
    {"bssid": "84:d8:1b:aa:bb:cc", "rssi": -43},
    {"bssid": "84:d8:1b:11:22:33", "rssi": -67},
    {"bssid": "84:d8:1b:44:55:66": -89}
  ]
}
```

**Sent to ML Server**:
```json
{
  "wifi": {
    "84:d8:1b:aa:bb:cc": -43,
    "84:d8:1b:11:22:33": -67,
    "84:d8:1b:44:55:66": -89
  }
}
```

---

### Manual vs Automatic Wi-Fi Scanning

**Manual Scan**:
- "Scan Wi-Fi" button in app UI
- Diagnostic feature only
- Shows scan results immediately
- **NOT used for community sensing**

**Automatic Scan**:
- Runs every 15 seconds when Community Sensing is ON
- No user interaction needed
- Runs in background
- **THIS is what powers room prediction**

---

## PART 9: WI-FI FINGERPRINT CACHE

### Why the Cache Exists

**Problem**:
- Wi-Fi scan happens independently (every 15s)
- BLE scan happens independently (every 15s)
- BLE scan is instant, Wi-Fi scan takes ~2 seconds
- Scans are not synchronized

**Solution**:
- Cache Wi-Fi fingerprint in memory
- When BLE detects tracker → Retrieve cached Wi-Fi data
- Include Wi-Fi fingerprint in detection request

**Without Cache**:
```
BLE detects AG-001 at 10:00:00
↓
No Wi-Fi data available
↓
Detection sent WITHOUT fingerprint
↓
Backend cannot call ML
↓
No room prediction
```

**With Cache**:
```
Wi-Fi scan at 10:00:05 → Cache updated
↓
BLE detects AG-001 at 10:00:15
↓
Retrieve cached Wi-Fi (10 seconds old)
↓
Detection sent WITH fingerprint
↓
Backend calls ML → Room predicted!
```

---

### Cache Implementation

**File**: `lib/services/wifi_fingerprint_cache.dart`

```dart
class WifiFingerprintCache {
  static final instance = WifiFingerprintCache._();
  
  Map<String, int>? _fingerprint;    // Cached data
  DateTime? _timestamp;               // When cached
  static const _maxAge = Duration(minutes: 2);  // Validity period
  
  // Store new fingerprint
  void update(Map<String, int> fingerprint) {
    _fingerprint = Map.from(fingerprint);
    _timestamp = DateTime.now();
    debugPrint('[WiFiCache] ✓ Fingerprint cached: ${fingerprint.length} BSSIDs');
  }
  
  // Retrieve cached fingerprint if fresh
  Map<String, int>? get() {
    if (_fingerprint == null || _timestamp == null) {
      debugPrint('[WiFiCache] ✗ No fingerprint in cache');
      return null;
    }
    
    final age = DateTime.now().difference(_timestamp!);
    if (age > _maxAge) {
      debugPrint('[WiFiCache] ✗ Fingerprint expired (age: ${age.inSeconds}s)');
      return null;
    }
    
    debugPrint('[WiFiCache] ✓ Fingerprint retrieved (age: ${age.inSeconds}s)');
    return Map.from(_fingerprint!);
  }
}
```

---

### Cache Validity: 2 Minutes

**Why 2 Minutes?**
- Wi-Fi APs don't move → Fingerprint stable over short time
- User might move to different room → Don't want stale data
- Balance between:
  - Too short (1 min) → Cache often empty
  - Too long (10 min) → Stale data if user moved

**Typical Scenario**:
```
10:00:00 - Wi-Fi scan #1 → Cache updated (valid until 10:02:00)
10:00:15 - BLE scan → Use cached Wi-Fi ✓
10:00:30 - BLE scan → Use cached Wi-Fi ✓
10:00:45 - BLE scan → Use cached Wi-Fi ✓
10:01:00 - Wi-Fi scan #2 → Cache refreshed (valid until 10:03:00)
10:01:15 - BLE scan → Use cached Wi-Fi ✓
... (continues)
```

---

### Cache Flow Diagram

```
Main Isolate (where everything runs):

Timer 1 (every 15s):                    Timer 2 (every 15s):
Wi-Fi Scan                              BLE Scan
    ↓                                       ↓
WifiScanService                         BleService
    ↓                                       ↓
Fingerprint created                     Tracker detected (AG-001)
    ↓                                       ↓
WifiFingerprintCache.update()           WifiFingerprintCache.get()
    ↓                                       ↓
Store in memory                         Retrieve from memory
(same instance!)                        (same instance!)
                                            ↓
                                    Include in detection
                                            ↓
                                    Send to backend with Wi-Fi
```

**Critical Point**: Both update and retrieval happen in the **same isolate** (main isolate)

---

### Previous Bug (Now Fixed)

**What Was Wrong**:
```
Task Isolate:                      Main Isolate:
Wi-Fi scan                         BLE scan
    ↓                                  ↓
Create fingerprint                 Cache.get()
    ↓                                  ↓
sendDataToMain()                   Cache is empty! ✗
    ↓                             (Never received update)
Message LOST ✗
(Never arrived at main isolate)
```

**Why It Failed**:
- Inter-isolate messaging (`sendDataToMain`) is unreliable
- Message sent but not received
- Cache update never happened
- BLE scan found empty cache

**Fix Applied**:
- Move Wi-Fi scan to **main isolate** using Timer
- Both Wi-Fi and BLE run in same isolate
- Cache update and retrieval in same memory space
- **No inter-isolate messaging needed**

---

### Current Implementation (Working)

```
Main Isolate:
  ├─ Timer #1 (15s) → Wi-Fi scan → Cache.update() ✓
  └─ Timer #2 (15s) → BLE scan → Cache.get() ✓
      (Same isolate = Same memory = Cache works!)
```

**Files Involved**:
- `lib/services/wifi_fingerprint_cache.dart` - Cache implementation
- `lib/services/community_sensing_service.dart` - Timer orchestration

---


## PART 10: COMMUNITY SENSING

### What is Community Sensing?

**Simple Definition**: Users help each other find lost items by allowing their phones to scan in the background.

**How It Works**:
- User B enables "Community Sensing" on their phone
- App runs in background (even when screen is off)
- Automatically scans for lost BLE trackers every 15 seconds
- If lost tracker detected → Reports to backend → Owner (User A) gets notified

---

### Community Sensing Service Architecture

**File**: `lib/services/community_sensing_service.dart`

**Two Main Components**:

1. **Foreground Service** (Android persistent notification)
   - Required by Android for background BLE/Wi-Fi/Location access
   - Shows notification: "Community sensing active — BLE: X, Wi-Fi: Y, Z detections"
   - Keeps service alive even when app backgrounded

2. **Main Isolate Timers** (Actual scanning)
   - Timer #1: BLE scan every 15 seconds
   - Timer #2: Wi-Fi scan every 15 seconds
   - Both run in main isolate (same memory space)

---

### Service Lifecycle

```
User taps "Enable Community Sensing"
↓
home_screen.dart → CommunitySensingService.instance.start()
↓
1. Request Permissions:
   - Bluetooth Scan (Android 12+)
   - Bluetooth Connect
   - Fine Location
   - Coarse Location
   - Notification (Android 13+)
↓
2. Check permissions:
   ├─ If denied → Return error → Show dialog to user
   └─ If granted → Continue
↓
3. Set up foreground service:
   FlutterForegroundTask.startService(
     notificationTitle: "AssetGuard Community Sensing",
     notificationText: "Starting BLE & Wi-Fi scans...",
     callback: startCommunitySensingCallback,
   )
↓
4. Android displays persistent notification
↓
5. Start BLE timer:
   Timer.periodic(15 seconds, () => _performBleScan())
↓
6. Start Wi-Fi timer:
   Timer.periodic(15 seconds, () => _performWifiScan())
↓
Service is now running!

When user taps "Disable Community Sensing":
↓
profile_screen.dart → CommunitySensingService.instance.stop()
↓
1. Cancel BLE timer
2. Cancel Wi-Fi timer
3. Stop foreground service
4. Remove notification
```

---

### BLE and Wi-Fi Coordination

**Both Run Independently**:

```
Time    BLE Timer              Wi-Fi Timer            Cache
--------------------------------------------------------------
0:00    [Scan starts]          [Scan starts]
        (8s duration)          (2s duration)
0:02                           [Scan complete]        → Update cache
0:08    [Scan complete]
        Found: AG-001
        Get from cache ✓       [Cache valid]          ← Retrieve
        Include in detection
0:15    [Scan starts]          [Scan starts]
0:17                           [Scan complete]        → Update cache
0:23    [Scan complete]
        Found: AG-001
        Get from cache ✓       [Cache valid]          ← Retrieve
0:30    [Scan starts]          [Scan starts]
...
```

**Key Points**:
- Scans are **not synchronized** (start at same time but different durations)
- Wi-Fi cache ensures BLE detection can always access recent Wi-Fi data
- Even if Wi-Fi scan fails → BLE detection still works (just no room prediction)

---

### Permission Flow

**Required Permissions** (Android 12+):
1. `BLUETOOTH_SCAN` - Discover nearby BLE devices
2. `BLUETOOTH_CONNECT` - Connect to BLE devices (not used, but requested for completeness)
3. `ACCESS_FINE_LOCATION` - BLE and Wi-Fi scanning require location
4. `ACCESS_COARSE_LOCATION` - Fallback location
5. `POST_NOTIFICATIONS` - Show notification (Android 13+)

**Request Flow**:
```
User taps "Enable Community Sensing"
↓
Check if permissions granted:
  await Permission.location.status
  await Permission.bluetoothScan.status
↓
If not granted:
  Request permissions:
    await Permission.location.request()
    await Permission.bluetoothScan.request()
    await Permission.notification.request()
↓
If user denies:
  Show dialog: "Bluetooth and Location permissions are required..."
  Offer to open Settings
↓
If user grants:
  Start foreground service
```

---

### Error Handling in Community Sensing

**BLE Scan Errors**:
```dart
try {
  final devices = await BleService.instance.scan();
} on BleException catch (e) {
  debugPrint('[Community BLE] ✗ BLE error: ${e.message}');
  // Continue - don't crash service
  // Will try again in 15 seconds
}
```

**Wi-Fi Scan Errors**:
```dart
try {
  final result = await WifiScanService.instance.scanNieAccessPoints();
  if (result is WifiScanFailure) {
    debugPrint('[CommunityWiFi] Wi-Fi scan failed: ${result.reason}');
    // Continue - BLE detection will work without Wi-Fi
  }
} catch (e) {
  debugPrint('[CommunityWiFi] Wi-Fi scan error: $e');
  // Continue - not critical
}
```

**Backend Errors**:
```dart
try {
  await CommunityDetectionService.instance.reportDetection(...);
} catch (e) {
  debugPrint('[Community] Failed to report detection: $e');
  // Continue - will retry on next detection
}
```

**Principle**: **Never crash the service**. Log errors, continue running, retry on next scan.

---

### Why Foreground Service?

**Android Limitation**: Apps cannot access Bluetooth or Location in background without user awareness.

**Solution**: Foreground Service with **visible notification**

**Requirements**:
- Must show persistent notification (cannot be dismissed by user)
- Notification must be visible while service is running
- User can tap notification to open app
- User can stop service from notification (optional)

**Transparency**: User always knows when Community Sensing is active.

---

### Task Isolate vs Main Isolate

**Previous Architecture** (Had Issues):
```
Task Isolate (foreground service callback):
  ├─ _performWifiScan()
  ├─ sendDataToMain({action: 'uploadWifiScan', fingerprint})
  └─ Message often lost ✗

Main Isolate:
  ├─ _handleDataFromTask() - Sometimes never called
  ├─ _performBleScan()
  └─ WifiFingerprintCache.get() - Often empty
```

**Current Architecture** (Fixed):
```
Task Isolate:
  └─ Minimal - Just keeps foreground service alive

Main Isolate:
  ├─ Timer #1 → _performBleScan()
  ├─ Timer #2 → _performWifiScan()
  └─ WifiFingerprintCache (update and get in same isolate) ✓
```

**Why This Works**:
- No inter-isolate messaging needed
- Both timers in same memory space
- Cache update and retrieval in same isolate
- Reliable, predictable behavior

---

### Notification Text Updates

**Dynamic Updates**:
```dart
void _updateNotification(int lastDetectionCount) {
  FlutterForegroundTask.updateService(
    notificationText: 'Community sensing active — '
        'BLE: $_bleScanCount, Wi-Fi: $_wifiScanCount, $_totalDetections detections',
  );
}
```

**Example Progression**:
```
Initial: "Community sensing active — starting BLE & Wi-Fi scans..."
After 15s: "Community sensing active — BLE: 1, Wi-Fi: 1, 0 detections"
After 30s: "Community sensing active — BLE: 2, Wi-Fi: 2, 0 detections"
Detection!: "Community sensing active — BLE: 3, Wi-Fi: 3, 1 detections"
```

---

## PART 11: BACKEND/API WORKFLOW

### Backend Technology Stack

**Framework**: Express.js (Node.js web framework)  
**Database**: MongoDB (via Mongoose ODM)  
**Authentication**: JWT (jsonwebtoken library)  
**Email**: Resend (email service)  
**Validation**: express-validator  
**Password Hashing**: bcryptjs  

---

### Server Entry Point

**File**: `backend/server.js`

```javascript
require('dotenv').config();              // Load environment variables
const app = require('./src/app');        // Express app
const connectDB = require('./src/config/db');  // MongoDB connection

const PORT = process.env.PORT || 5000;

const start = async () => {
  await connectDB();                     // Connect to MongoDB
  app.listen(PORT, () => {
    console.log(`🚀 AssetGuard API running on port ${PORT}`);
  });
};

start();
```

---

### Express App Configuration

**File**: `backend/src/app.js`

```javascript
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const assetRoutes = require('./routes/assetRoutes');
const communityRoutes = require('./routes/communityRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');

const app = express();

// Middleware
app.use(cors());                      // Allow Flutter app to call API
app.use(express.json());              // Parse JSON request bodies

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/assets', assetRoutes);
app.use('/api/community', communityRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/dashboard', dashboardRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date() });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

module.exports = app;
```

---

### Important API Endpoints

### Authentication Routes (`/api/auth`)

**1. Register**
```
POST /api/auth/register
Body: {name, email, password}
Response: {token, user} (dev) or {message: "Check email"} (prod)
```

**2. Login**
```
POST /api/auth/login
Body: {email, password}
Response: {token, user: {_id, name, email}}
```

**3. Verify Email**
```
GET /api/auth/verify-email?token=xxx
Response: {token, user}
```

**4. Get Current User**
```
GET /api/auth/me
Headers: Authorization: Bearer <JWT>
Response: {_id, name, email}
```

**5. Forgot Password**
```
POST /api/auth/forgot-password
Body: {email}
Response: {message: "Reset email sent"}
```

**6. Reset Password**
```
POST /api/auth/reset-password
Body: {token, password}
Response: {message: "Password reset successful"}
```

---

### Asset Routes (`/api/assets`)

All require `protect` middleware (JWT authentication)

**1. Get All Assets**
```
GET /api/assets
Headers: Authorization: Bearer <JWT>
Response: [{_id, name, trackerId, status, ...}, ...]
```

**2. Get Single Asset**
```
GET /api/assets/:id
Headers: Authorization: Bearer <JWT>
Response: {_id, name, trackerId, status, userId, ...}
```

**3. Create Asset**
```
POST /api/assets
Headers: Authorization: Bearer <JWT>
Body: {name, category, description, trackerId}
Response: {_id, name, trackerId, status: 'ACTIVE', userId, ...}
```

**4. Update Asset**
```
PUT /api/assets/:id
Headers: Authorization: Bearer <JWT>
Body: {name, category, description}
Response: {_id, name, trackerId, ...}
```

**5. Delete Asset**
```
DELETE /api/assets/:id
Headers: Authorization: Bearer <JWT>
Response: {message: "Asset deleted"}
```

**6. Mark as Lost**
```
PUT /api/assets/:id/status
Headers: Authorization: Bearer <JWT>
Body: {status: 'LOST'}
Response: {_id, name, status: 'LOST', ...}
```

**7. Mark as Recovered**
```
PUT /api/assets/:id/recover
Headers: Authorization: Bearer <JWT>
Response: {_id, name, status: 'RECOVERED', ...}
```

---

### Community Routes (`/api/community`)

All require `protect` middleware

**1. Submit Wi-Fi Scan**
```
POST /api/community/scan
Headers: Authorization: Bearer <JWT>
Body: {
  wifiFingerprint: [{bssid, rssi}, ...],
  timestamp: "2026-08-28T10:00:00Z"
}
Response: {message: "Community scan recorded", scanId}
Purpose: Historical Wi-Fi data collection
```

**2. Submit Community Detection** ⭐ CRITICAL
```
POST /api/community/detections
Headers: Authorization: Bearer <JWT>
Body: {
  trackerId: "AG-001",
  rssi: -67,
  remoteId: "AA:BB:CC:DD:EE:FF",
  detectedAt: "2026-08-28T10:00:00Z",
  latitude: 1.3521,
  longitude: 103.8198,
  wifiFingerprint: {
    "84:d8:1b:aa:bb:cc": -43,
    "84:d8:1b:11:22:33": -67
  }
}
Response: {
  message: "Community detection recorded...",
  detectionId,
  predictedRoom: "310",    // If Wi-Fi provided
  confidence: 0.376667
}
```

**3. Get Detections for Asset**
```
GET /api/community/detections/asset/:assetId
Headers: Authorization: Bearer <JWT>
Response: [{
  _id, trackerId, rssi, latitude, longitude,
  predictedRoom, roomConfidence, detectedAt
}, ...]
Purpose: Track Asset map markers
```

---

### Notification Routes (`/api/notifications`)

All require `protect` middleware

**1. Get Notifications**
```
GET /api/notifications?unreadOnly=false&limit=50
Headers: Authorization: Bearer <JWT>
Response: {
  notifications: [{
    _id, type, title, message,
    assetId, trackerId,
    predictedRoom, roomConfidence,
    latitude, longitude, rssi,
    read, createdAt
  }, ...],
  unreadCount: 5
}
```

**2. Get Unread Count**
```
GET /api/notifications/unread/count
Headers: Authorization: Bearer <JWT>
Response: {count: 3}
Purpose: Badge on bell icon
```

**3. Mark as Read**
```
PUT /api/notifications/:id/read
Headers: Authorization: Bearer <JWT>
Response: {message: "Notification marked as read"}
```

**4. Mark All as Read**
```
PUT /api/notifications/read-all
Headers: Authorization: Bearer <JWT>
Response: {message: "All notifications marked as read", count: 5}
```

---

### Dashboard Routes (`/api/dashboard`)

**1. Get Dashboard Stats**
```
GET /api/dashboard/stats
Headers: Authorization: Bearer <JWT>
Response: {
  totalAssets: 10,
  lostAssets: 2,
  trackingAssets: 1    // Lost assets with recent detections
}
```

---

### Middleware Explained

#### Authentication Middleware

**File**: `backend/src/middleware/auth.js`

```javascript
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;

  // 1. Extract token from Authorization header
  if (req.headers.authorization?.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  // 2. Check token exists
  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Not authorized - no token provided',
    });
  }

  try {
    // 3. Verify token signature
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // 4. Get user from database
    req.user = await User.findById(decoded.userId).select('-password');
    
    // 5. Check user exists
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'User not found',
      });
    }

    // 6. Attach user to request, proceed to controller
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Not authorized - token invalid',
    });
  }
};

module.exports = { protect };
```

**Usage**:
```javascript
// In routes
router.get('/assets', protect, getAssets);
//                     ↑ Middleware runs before controller
```

---

#### Validation Middleware

**File**: `backend/src/middleware/validate.js`

```javascript
const { validationResult } = require('express-validator');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array(),
    });
  }
  
  next();
};

module.exports = { validate };
```

**Usage**:
```javascript
// In routes
const { body } = require('express-validator');

const createAssetValidators = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('trackerId').trim().notEmpty().withMessage('Tracker ID is required'),
];

router.post('/assets',
  protect,                    // 1. Check authentication
  createAssetValidators,      // 2. Define validation rules
  validate,                   // 3. Check validation results
  createAsset                 // 4. Run controller
);
```

---

### Environment Variables

**File**: `backend/.env`

```
# Database
MONGO_URI=mongodb://localhost:27017/assetguard_db

# JWT Secret (use strong random string in production)
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production

# Server Port
PORT=5000

# Email Service (Resend)
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxx
EMAIL_FROM=noreply@assetguard.app

# Email Verification (set to 'false' for development)
EMAIL_VERIFICATION_ENABLED=false

# ML Server URL
ML_API_URL=http://10.135.90.221:8000

# Frontend URL (for email links)
FRONTEND_URL=http://localhost:3000
```

**IMPORTANT**: Never commit `.env` to Git (listed in `.gitignore`)

---

## PART 12: MONGODB ARCHITECTURE

### Database Name
`assetguard_db`

### Collections (Tables)

---

### 1. `users` Collection

**Schema**: `backend/src/models/User.js`

```javascript
{
  _id: ObjectId("675..."),
  name: "John Doe",
  email: "john@example.com",          // Unique, indexed
  password: "$2a$10$...",              // Bcrypt hashed
  emailVerified: true,
  emailVerificationToken: null,
  passwordResetToken: null,
  passwordResetExpires: null,
  createdAt: ISODate("2026-08-20T10:00:00Z"),
  updatedAt: ISODate("2026-08-28T14:30:00Z")
}
```

**Indexes**:
- `email: 1` (unique)

**Methods**:
- `userSchema.pre('save')` - Hash password before saving
- `matchPassword(enteredPassword)` - Verify password during login

---

### 2. `assets` Collection

**Schema**: `backend/src/models/Asset.js`

```javascript
{
  _id: ObjectId("675..."),
  name: "Laptop",
  category: "Electronics",
  description: "MacBook Pro 14-inch",
  trackerId: "AG-001",
  status: "LOST",                     // 'ACTIVE', 'LOST', 'RECOVERED'
  lastDetectedLocation: "Room 310",
  lastDetectedTime: ISODate("2026-08-28T14:30:00Z"),
  userId: ObjectId("675..."),         // Reference to users collection
  createdAt: ISODate("2026-08-20T10:00:00Z"),
  updatedAt: ISODate("2026-08-28T14:30:00Z")
}
```

**Indexes**:
- `userId: 1` - Find all assets for a user
- `{userId: 1, trackerId: 1}` - Unique (one tracker ID per user)

**Status Values**:
- `ACTIVE` - Normal state, not lost
- `LOST` - User marked as lost, community sensing active
- `RECOVERED` - User found it, detections ignored

---

### 3. `communitydetections` Collection

**Schema**: `backend/src/models/CommunityDetection.js`

```javascript
{
  _id: ObjectId("675..."),
  trackerId: "AG-001",
  assetId: ObjectId("675..."),        // Reference to assets
  detectedBy: ObjectId("675..."),     // User B (community member)
  rssi: -67,
  remoteId: "AA:BB:CC:DD:EE:FF",
  detectedAt: ISODate("2026-08-28T14:30:00Z"),
  latitude: 1.3521,
  longitude: 103.8198,
  predictedRoom: "310",               // From ML server
  roomConfidence: 0.376667,           // From ML server
  createdAt: ISODate("2026-08-28T14:30:05Z")
}
```

**Indexes**:
- `assetId: 1` - Find all detections for an asset (Track Asset feature)
- `detectedBy: 1` - Track who detected what
- `detectedAt: -1` - Sort by newest first

**Privacy Note**: `detectedBy` field is excluded when sending detections to asset owner

---

### 4. `notifications` Collection

**Schema**: `backend/src/models/Notification.js`

```javascript
{
  _id: ObjectId("675..."),
  recipient: ObjectId("675..."),      // User A (asset owner)
  type: "asset_detected",             // 'asset_detected', 'asset_status_changed', 'system'
  title: "Asset Detected",
  message: "Your Laptop (AG-001) was detected near Room 310. (38% confidence)",
  assetId: ObjectId("675..."),
  detectionId: ObjectId("675..."),
  trackerId: "AG-001",
  latitude: 1.3521,
  longitude: 103.8198,
  rssi: -67,
  detectedAt: ISODate("2026-08-28T14:30:00Z"),
  predictedRoom: "310",
  roomConfidence: 0.376667,
  read: false,
  createdAt: ISODate("2026-08-28T14:30:05Z"),
  updatedAt: ISODate("2026-08-28T14:30:05Z")
}
```

**Indexes**:
- `{recipient: 1, read: 1, createdAt: -1}` - Efficient queries: unread first, newest first

---

### 5. `communityfingerprints` Collection

**Schema**: `backend/src/models/CommunityFingerprint.js`

```javascript
{
  _id: ObjectId("675..."),
  scannedBy: ObjectId("675..."),
  wifiFingerprint: [
    {bssid: "84:d8:1b:aa:bb:cc", rssi: -43},
    {bssid: "84:d8:1b:11:22:33", rssi: -67},
    // ... 70+ more
  ],
  timestamp: ISODate("2026-08-28T14:30:00Z"),
  createdAt: ISODate("2026-08-28T14:30:01Z")
}
```

**Purpose**: Historical Wi-Fi scan data for analysis/debugging (not used for room prediction directly)

---

### Relationships Diagram

```
┌─────────┐
│  users  │
└────┬────┘
     │ 1
     │ owns
     │ *
┌────┴────────┐
│   assets    │ status: LOST
└────┬────────┘
     │ 1
     │ detected in
     │ *
┌────┴─────────────────┐
│ communitydetections  │ wifiFingerprint → ML Server
└────┬─────────────────┘                      ↓
     │                                    predictedRoom
     │ creates                            roomConfidence
     │                                         ↓
┌────┴──────────────┐                         │
│  notifications    │ ←───────────────────────┘
└───────────────────┘
     │
     │ sent to
     ↓
  users (recipient)
```

---

### Database Queries Examples

**Find all assets for a user**:
```javascript
Asset.find({ userId: req.user._id })
```

**Find asset by tracker ID** (cross-user):
```javascript
Asset.findOne({ trackerId: 'AG-001' }).populate('userId', 'name email')
```

**Find recent detections for an asset**:
```javascript
CommunityDetection.find({
  assetId: assetId,
  detectedAt: { $gte: new Date(Date.now() - 7*24*60*60*1000) }  // Last 7 days
}).sort({ detectedAt: -1 })
```

**Count lost assets with recent detections**:
```javascript
const lostAssets = await Asset.find({ userId, status: 'LOST' });
const tracking = await Promise.all(
  lostAssets.map(async (asset) => {
    const detection = await CommunityDetection.findOne({
      assetId: asset._id,
      detectedAt: { $gte: new Date(Date.now() - 7*24*60*60*1000) }
    });
    return detection ? 1 : 0;
  })
);
const trackingCount = tracking.reduce((a, b) => a + b, 0);
```

---

## PART 13: COMMUNITY DETECTION FLOW

### Complete Flow with File Names

```
┌─────────────────────────────────────────────────────────────┐
│ Phone B (User B - Community Member)                         │
└─────────────────────────────────────────────────────────────┘
│
│ Community Sensing ON
│ lib/services/community_sensing_service.dart
│   ├─ Timer #1 (every 15s): _performBleScan()
│   │   └─ lib/services/ble_service.dart → scan()
│   │       └─ flutter_blue_plus → Platform BLE APIs
│   │           └─ Detects: AG-001, RSSI: -67 dBm
│   │
│   └─ Timer #2 (every 15s): _performWifiScan()
│       └─ lib/services/wifi_scan_service.dart → scanNieAccessPoints()
│           └─ wifi_scan package → Android Wi-Fi APIs
│               └─ Results: 74 NIE APs with BSSIDs + RSSIs
│               └─ lib/services/wifi_fingerprint_cache.dart → update()
│
│ BLE Detection Triggered:
│   lib/services/community_sensing_service.dart → _performBleScan()
│   ├─ Check debounce: shouldReport("AG-001")?
│   │   lib/services/community_detection_service.dart
│   │   └─ Last reported > 60s ago? YES → Continue
│   │
│   ├─ Get Wi-Fi from cache:
│   │   lib/services/wifi_fingerprint_cache.dart → get()
│   │   └─ Returns: {bssid: rssi, ...} (74 BSSIDs)
│   │
│   ├─ Get GPS:
│   │   lib/services/location_service.dart → getPosition()
│   │   └─ Returns: (1.3521, 103.8198)
│   │
│   └─ Submit detection:
│       lib/services/community_detection_service.dart → reportDetection()
│       └─ lib/services/api_service.dart → post()
│           └─ HTTP POST to backend
│
↓
│
┌─────────────────────────────────────────────────────────────┐
│ Network: HTTP Request                                        │
└─────────────────────────────────────────────────────────────┘
│
│ POST http://backend:5000/api/community/detections
│ Headers:
│   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
│   Content-Type: application/json
│ Body:
│   {
│     "trackerId": "AG-001",
│     "rssi": -67,
│     "remoteId": "AA:BB:CC:DD:EE:FF",
│     "detectedAt": "2026-08-28T14:30:00.000Z",
│     "latitude": 1.3521,
│     "longitude": 103.8198,
│     "wifiFingerprint": {
│       "84:d8:1b:aa:bb:cc": -43,
│       "84:d8:1b:11:22:33": -67,
│       ... (72 more BSSIDs)
│     }
│   }
│
↓
│
┌─────────────────────────────────────────────────────────────┐
│ Backend (Node.js/Express)                                    │
└─────────────────────────────────────────────────────────────┘
│
│ backend/src/app.js → Express receives request
│   ↓
│ backend/src/routes/communityRoutes.js
│   router.post('/detections', ...)
│   ↓
│ backend/src/middleware/auth.js → protect()
│   ├─ Extract JWT from Authorization header
│   ├─ Verify signature with JWT_SECRET
│   ├─ Look up user: User.findById(decoded.userId)
│   ├─ Attach to request: req.user = User B
│   └─ Call next()
│   ↓
│ backend/src/controllers/communityController.js
│   → submitCommunityDetection()
│
│   Step 1: Look up asset by trackerId
│   ├─ Asset.findOne({ trackerId: "AG-001" })
│   │   .populate('userId', 'name email')
│   ├─ Result: Asset found
│   └─ Owner: User A (_id, name, email)
│
│   Step 2: ⭐ CRITICAL CHECK - Asset status
│   ├─ if (asset.status !== 'LOST')
│   │   └─ return 404 "Asset not found" (prevents spam)
│   └─ Status is 'LOST' → Continue
│
│   Step 3: Security check - Detector ≠ Owner
│   ├─ if (asset.userId._id === req.user._id)
│   │   └─ return 404 (owner cannot report own asset)
│   └─ User B ≠ User A → Continue
│
│   Step 4: ML Room Prediction
│   ├─ if (wifiFingerprint exists && not empty)
│   │   ├─ Call Python ML Server:
│   │   │   fetch('http://10.135.90.221:8000/predict-room', {
│   │   │     method: 'POST',
│   │   │     body: JSON.stringify({
│   │   │       wifi: wifiFingerprint  // {bssid: rssi, ...}
│   │   │     })
│   │   │   })
│   │   │   ↓
│   │   │   Python ML Server processes...
│   │   │   ↓
│   │   │   Response: {
│   │   │     room: "310",
│   │   │     confidence: 0.376667,
│   │   │     top_predictions: [...]
│   │   │   }
│   │   │   ↓
│   │   ├─ Extract: predictedRoom = "310"
│   │   └─ Extract: roomConfidence = 0.376667
│   └─ else: No Wi-Fi → predictedRoom = null
│
│   Step 5: Create CommunityDetection record
│   ├─ CommunityDetection.create({
│   │   trackerId: "AG-001",
│   │   assetId: asset._id,
│   │   detectedBy: req.user._id,  // User B
│   │   rssi: -67,
│   │   remoteId: "AA:BB:CC:DD:EE:FF",
│   │   detectedAt: new Date("2026-08-28T14:30:00Z"),
│   │   latitude: 1.3521,
│   │   longitude: 103.8198,
│   │   predictedRoom: "310",
│   │   roomConfidence: 0.376667,
│   │ })
│   └─ Saved to MongoDB: communitydetections collection
│
│   Step 6: Create Notification for Owner
│   ├─ Build message:
│   │   if (predictedRoom):
│   │     message = "Your Laptop (AG-001) was detected near Room 310. (38% confidence)"
│   │   else if (latitude && longitude):
│   │     message = "Your Laptop (AG-001) was detected at 1.3521, 103.8198."
│   │   else:
│   │     message = "Your Laptop (AG-001) was detected nearby."
│   │
│   ├─ Notification.create({
│   │   recipient: asset.userId._id,  // User A
│   │   type: 'asset_detected',
│   │   title: 'Asset Detected',
│   │   message: message,
│   │   assetId: asset._id,
│   │   detectionId: detection._id,
│   │   trackerId: "AG-001",
│   │   latitude: 1.3521,
│   │   longitude: 103.8198,
│   │   rssi: -67,
│   │   detectedAt: new Date("2026-08-28T14:30:00Z"),
│   │   predictedRoom: "310",
│   │   roomConfidence: 0.376667,
│   │   read: false,
│   │ })
│   └─ Saved to MongoDB: notifications collection
│
│   Step 7: Return response to Phone B
│   └─ res.status(201).json({
│       success: true,
│       message: "Community detection recorded. Asset owner will be notified.",
│       detectionId: detection._id,
│       predictedRoom: "310",
│       confidence: 0.376667
│     })
│
↓
│
┌─────────────────────────────────────────────────────────────┐
│ Phone B receives success response                            │
└─────────────────────────────────────────────────────────────┘
│
│ lib/services/community_detection_service.dart
│   ├─ Log: "[Community] ✓ Detection reported successfully: AG-001"
│   ├─ Log: "[CommunityWiFi] ✓ Predicted room: 310"
│   ├─ Log: "[CommunityWiFi] ✓ Confidence: 0.376667"
│   └─ Update debounce: _lastReported["AG-001"] = now
│
↓
│
┌─────────────────────────────────────────────────────────────┐
│ Phone A (User A - Asset Owner)                               │
└─────────────────────────────────────────────────────────────┘
│
│ Notification Delivery (Multiple Methods):
│
│ Method 1: App Polling (if app is open)
│   lib/screens/home_screen.dart → Timer every 30s
│   └─ NotificationService.instance.getUnreadCount()
│       └─ GET /api/notifications/unread/count
│           └─ Backend returns: {count: 1}
│               └─ Update badge on bell icon
│
│ Method 2: User Opens Notifications Screen
│   lib/screens/notifications_screen.dart → initState()
│   └─ NotificationService.instance.getNotifications()
│       └─ GET /api/notifications
│           ↓
│           Backend: backend/src/controllers/notificationController.js
│           ├─ Notification.find({ recipient: req.user._id })
│           │   .sort({ read: 1, createdAt: -1 })
│           └─ Returns: [{
│               _id: "675...",
│               type: "asset_detected",
│               title: "Asset Detected",
│               message: "Your Laptop (AG-001) was detected near Room 310. (38% confidence)",
│               assetId: "675...",
│               trackerId: "AG-001",
│               predictedRoom: "310",
│               roomConfidence: 0.376667,
│               latitude: 1.3521,
│               longitude: 103.8198,
│               rssi: -67,
│               detectedAt: "2026-08-28T14:30:00Z",
│               read: false,
│               createdAt: "2026-08-28T14:30:05Z"
│             }]
│           ↓
│   lib/models/notification_model.dart → fromJson()
│   └─ Convert to AppNotification objects
│       ↓
│   lib/screens/notifications_screen.dart → _buildNotificationCard()
│   └─ Display notification with:
│       ├─ Title: "Asset Detected"
│       ├─ Message: "Your Laptop (AG-001) was detected near Room 310. (38% confidence)"
│       └─ Info chips:
│           ├─ [AG-001]
│           ├─ [🚪 Room 310 (38%)]  ← Blue chip, prominent
│           ├─ [-67 dBm]
│           ├─ [1.3521, 103.8198]
│           └─ [Aug 28, 2:30 PM]
│
│ User A Taps Notification → Navigate to AssetDetailsScreen
│   └─ User can tap "Track Asset" to see detection on map
│
↓
│
┌─────────────────────────────────────────────────────────────┐
│ Track Asset (Map View)                                       │
└─────────────────────────────────────────────────────────────┘
│
│ lib/screens/track_asset_screen.dart
│   ├─ Fetch detection history:
│   │   GET /api/community/detections/asset/:assetId
│   │   └─ Backend returns all detections (sorted newest first)
│   │
│   ├─ Display map (flutter_map + OpenStreetMap tiles)
│   │
│   └─ Add markers for each detection:
│       ├─ Marker position: (latitude, longitude)
│       ├─ Marker color: Blue for recent, Gray for old
│       └─ Marker popup:
│           ├─ "Detected: Aug 28, 2:30 PM"
│           ├─ "Signal: -67 dBm"
│           ├─ "Room: 310 (38% confidence)"  ← Shows predicted room!
│           └─ "Location: 1.3521, 103.8198"
```

---

## PART 14: ML INTEGRATION

### ML Server is Separate Project

**IMPORTANT**: The Python ML server is a **separate codebase** from the Flutter/backend project.

**ML Server Repository**: Separate Python project (not in this repository)

**ML Server Purpose**: Prediction-only service
- Receives Wi-Fi fingerprint
- Returns predicted room + confidence
- Does **NOT** send notifications
- Does **NOT** access database
- Does **NOT** know about users/assets

---

### ML Server Communication

**Protocol**: HTTP REST API

**ML Server URL**: `http://10.135.90.221:8000` (configured in `backend/.env` as `ML_API_URL`)

**Endpoint**: `POST /predict-room`

**Request Format**:
```json
{
  "wifi": {
    "84:d8:1b:aa:bb:cc": -43,
    "84:d8:1b:11:22:33": -67,
    "84:d8:1b:44:55:66": -89,
    ... (up to 106 BSSIDs)
  }
}
```

**Response Format**:
```json
{
  "room": "310",
  "confidence": 0.376667,
  "top_predictions": [
    {"room": "310", "confidence": 0.376667},
    {"room": "312", "confidence": 0.201234},
    {"room": "308", "confidence": 0.156789}
  ]
}
```

---

### Backend → ML Server Integration

**File**: `backend/src/controllers/communityController.js` (Lines ~159-185)

```javascript
// Only call ML if Wi-Fi fingerprint provided
if (wifiFingerprint && typeof wifiFingerprint === 'object' && Object.keys(wifiFingerprint).length > 0) {
  console.log('[CommunityWiFi] Wi-Fi fingerprint provided with', Object.keys(wifiFingerprint).length, 'BSSIDs');
  console.log('[CommunityWiFi] Calling ML room prediction...');

  try {
    const mlUrl = `${process.env.ML_API_URL || 'http://10.135.90.221:8000'}/predict-room`;
    
    // Create abort controller for timeout
    const mlController = new AbortController();
    const mlTimeoutId = setTimeout(() => mlController.abort(), 10000); // 10 second timeout

    // Call ML server
    const mlResponse = await fetch(mlUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ wifi: wifiFingerprint }),
      signal: mlController.signal,
    });

    clearTimeout(mlTimeoutId);

    // Parse response
    if (mlResponse.ok) {
      const mlData = await mlResponse.json();
      predictedRoom = mlData.room || mlData.predicted_room || mlData.predictedRoom;
      roomConfidence = mlData.confidence;

      console.log('[CommunityWiFi] ✓ ML predicted room:', predictedRoom);
      console.log('[CommunityWiFi] ✓ Confidence:', roomConfidence);
    } else {
      console.log('[CommunityWiFi] ✗ ML API returned status:', mlResponse.status);
    }
  } catch (mlErr) {
    if (mlErr.name === 'AbortError') {
      console.log('[CommunityWiFi] ✗ ML prediction timed out');
    } else {
      console.log('[CommunityWiFi] ✗ ML prediction failed:', mlErr.message);
    }
    // Continue without room prediction - don't fail the detection
  }
}
```

**Key Points**:
- **Timeout**: 10 seconds (prevents hanging if ML server is slow/down)
- **Graceful Degradation**: If ML fails → Detection still succeeds, just no room prediction
- **Error Handling**: Catches network errors, timeouts, invalid responses
- **Flexible Field Names**: Accepts `room`, `predicted_room`, or `predictedRoom`

---

### ML Model Details

**Algorithm**: Random Forest Classifier (scikit-learn)

**Training Data**:
- 22 rooms on NIE campus
- Multiple Wi-Fi fingerprints per room (different positions, times)
- ~10-20 samples per room (estimated)

**Features**:
- **106 BSSID features** (most frequently appearing BSSIDs across campus)
- Each feature = RSSI value for that BSSID
- Missing BSSIDs = -100 dBm (model is trained to handle missing values)

**Example Feature Vector**:
```python
[
  -43,    # BSSID 1 (84:d8:1b:aa:bb:cc)
  -67,    # BSSID 2 (84:d8:1b:11:22:33)
  -100,   # BSSID 3 (not visible)
  -89,    # BSSID 4 (84:d8:1b:44:55:66)
  ... (102 more features)
]
```

**Output Classes**:
- 22 room numbers: "310", "312", "314", "316", "318", "320", etc.
- String labels (not numeric)

**Accuracy**: **97.96%** on test set

**Why Random Forest?**:
1. High accuracy on Wi-Fi fingerprinting tasks
2. Handles missing features naturally (some BSSIDs not always visible)
3. Fast prediction (~50-100ms)
4. Robust to outliers
5. No need for feature scaling
6. Interpretable (can see which BSSIDs are important)

---

### Data Flow: Flutter → Backend → ML → Notification

```
Flutter Wi-Fi Scan:
  Map<String, int> fingerprint = {
    "84:d8:1b:aa:bb:cc": -43,
    "84:d8:1b:11:22:33": -67,
    ...
  };
  ↓
Backend Receives:
  wifiFingerprint: {
    "84:d8:1b:aa:bb:cc": -43,
    "84:d8:1b:11:22:33": -67,
    ...
  }
  ↓
Backend → ML Server:
  POST /predict-room
  Body: {wifi: {...}}
  ↓
ML Server Processes:
  1. Extract RSSI for each of 106 known BSSIDs
  2. Build feature vector: [-43, -67, -100, -89, ...]
  3. Pass to Random Forest model
  4. Get predictions for all 22 rooms
  5. Return top prediction + confidence
  ↓
ML Server → Backend:
  {room: "310", confidence: 0.376667}
  ↓
Backend Stores:
  CommunityDetection: {predictedRoom: "310", roomConfidence: 0.376667}
  Notification: {predictedRoom: "310", roomConfidence: 0.376667}
  ↓
Backend → Flutter:
  Response: {predictedRoom: "310", confidence: 0.376667}
  ↓
Flutter Displays:
  Notification: "...detected near Room 310. (38% confidence)"
  Room chip: [🚪 Room 310 (38%)]
```

---

### What if ML Server is Down?

**Scenario**: ML server is offline, unreachable, or times out

**Behavior**:
```javascript
try {
  const mlResponse = await fetch(mlUrl, {timeout: 10s});
  // ...
} catch (mlErr) {
  console.log('[CommunityWiFi] ✗ ML prediction failed:', mlErr.message);
  // predictedRoom remains null
}

// Detection continues WITHOUT room prediction
const detection = await CommunityDetection.create({
  predictedRoom: null,  // ← No room
  roomConfidence: null,
  // ... other fields
});

// Notification created WITHOUT room in message
const message = latitude && longitude
  ? `Your ${asset.name} (${trackerId}) was detected at ${latitude}, ${longitude}.`
  : `Your ${asset.name} (${trackerId}) was detected nearby.`;
```

**Result**: System still works, just falls back to GPS-only notification

---

### ML Server vs Backend Responsibilities

| Responsibility | ML Server | Backend |
|----------------|-----------|---------|
| Wi-Fi fingerprint → Room prediction | ✅ | ❌ |
| User authentication | ❌ | ✅ |
| Asset lookup | ❌ | ✅ |
| Status check (LOST) | ❌ | ✅ |
| Notification creation | ❌ | ✅ |
| Database access | ❌ | ✅ |
| Send notifications to users | ❌ | ✅ |

**Separation of Concerns**: ML server only does prediction, backend handles all business logic

---


## PART 15: NOTIFICATIONS

### Notification System Architecture

**Creation**: Backend creates notifications in MongoDB  
**Delivery**: Flutter polls backend API  
**Display**: Flutter notifications screen  
**No Push Notifications**: Currently uses polling (could add FCM later)

---

### Notification Creation (Backend)

**File**: `backend/src/controllers/communityController.js` (Lines ~190-220)

```javascript
// Create notification for asset owner
try {
  let message;
  let title = 'Asset Detected';
  
  // Build message based on available data
  if (predictedRoom) {
    // Room prediction available
    message = `Your ${asset.name} (${trackerId}) was detected near Room ${predictedRoom}.`;
    if (roomConfidence) {
      const confidencePercent = Math.round(roomConfidence * 100);
      message += ` (${confidencePercent}% confidence)`;
    }
  } else if (latitude && longitude) {
    // GPS location available but no room
    message = `Your ${asset.name} (${trackerId}) was detected at ${latitude.toFixed(4)}, ${longitude.toFixed(4)}.`;
  } else {
    // Basic detection
    message = `Your ${asset.name} (${trackerId}) was detected nearby.`;
  }

  // Create notification record
  const notification = await Notification.create({
    recipient: asset.userId._id,     // Owner's user ID
    type: 'asset_detected',
    title,
    message,
    assetId: asset._id,
    detectionId: detection._id,
    trackerId: asset.trackerId,
    latitude: latitude || null,
    longitude: longitude || null,
    rssi,
    detectedAt: new Date(detectedAt),
    predictedRoom,                   // From ML server
    roomConfidence,                  // From ML server
    read: false,
  });

  console.log('[Community] Owner notification created:', notification._id);
  console.log('[Community] Notification sent to:', asset.userId.email);
  console.log('[Community]   title   :', notification.title);
  console.log('[Community]   message :', notification.message);
} catch (notifErr) {
  // DO NOT fail the detection if notification creation fails
  console.error('[Community] Failed to create notification:', notifErr);
  console.error('[Community] Detection still recorded successfully');
}
```

**Notification Types**:
1. **With Room Prediction**: "Your Laptop (AG-001) was detected near Room 310. (38% confidence)"
2. **With GPS Only**: "Your Laptop (AG-001) was detected at 1.3521, 103.8198."
3. **Basic**: "Your Laptop (AG-001) was detected nearby."

---

### Notification Retrieval (Flutter)

**File**: `lib/services/notification_service.dart`

```dart
class NotificationService {
  static final instance = NotificationService._();

  // Fetch all notifications
  Future<List<AppNotification>> getNotifications({bool unreadOnly = false}) async {
    try {
      final queryParams = unreadOnly ? '?unreadOnly=true' : '';
      final response = await ApiService.instance.get('/api/notifications$queryParams');
      
      final List<dynamic> notifList = response['notifications'];
      return notifList.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[Notifications] Failed to fetch: $e');
      rethrow;
    }
  }

  // Get unread count (for badge)
  Future<int> getUnreadCount() async {
    try {
      final response = await ApiService.instance.get('/api/notifications/unread/count');
      return response['count'] as int;
    } catch (e) {
      return 0;
    }
  }

  // Mark single notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await ApiService.instance.put('/api/notifications/$notificationId/read', {});
      return true;
    } catch (e) {
      debugPrint('[Notifications] Failed to mark as read: $e');
      return false;
    }
  }

  // Mark all as read
  Future<bool> markAllAsRead() async {
    try {
      await ApiService.instance.put('/api/notifications/read-all', {});
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

---

### Notification Model (Flutter)

**File**: `lib/models/notification_model.dart`

```dart
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? assetId;
  final String? detectionId;
  final String? trackerId;
  final double? latitude;
  final double? longitude;
  final int? rssi;
  final DateTime? detectedAt;
  final String? predictedRoom;        // ← ML prediction
  final double? roomConfidence;       // ← ML confidence
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      assetId: json['assetId'] as String?,
      detectionId: json['detectionId'] as String?,
      trackerId: json['trackerId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rssi: json['rssi'] as int?,
      detectedAt: json['detectedAt'] != null
          ? DateTime.parse(json['detectedAt'] as String)
          : null,
      predictedRoom: json['predictedRoom'] as String?,
      roomConfidence: (json['roomConfidence'] as num?)?.toDouble(),
      read: json['read'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
```

---

### Notification Display (UI)

**File**: `lib/screens/notifications_screen.dart`

**Key Features**:
1. List of notifications (newest first, unread first)
2. Each notification shows:
   - Title + message
   - Info chips: Tracker ID, Room (if predicted), RSSI, GPS, Time
   - Unread indicator (blue dot)
   - Blue background for unread
3. Tap notification → Navigate to AssetDetailsScreen
4. "Mark all read" button

**Room Chip Implementation**:
```dart
Widget _buildRoomChip(String room, double? confidence) {
  final confidencePercent = confidence != null ? (confidence * 100).round() : null;
  final displayText = confidencePercent != null 
      ? 'Room $room ($confidencePercent%)'
      : 'Room $room';
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.primaryColor.withAlpha(26),      // Light blue background
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.primaryColor.withAlpha(77)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.meeting_room_outlined,
          size: 14,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          displayText,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
```

**Visual Example**:
```
┌─────────────────────────────────────────────┐
│ 📍 Asset Detected                       ●   │
│    2m ago                                    │
│                                              │
│ Your Laptop (AG-001) was detected           │
│ near Room 310. (38% confidence)             │
│                                              │
│ [AG-001] [🚪 Room 310 (38%)] [-67 dBm]     │
│ [1.3521, 103.8198] [Aug 28, 2:30 PM]       │
└─────────────────────────────────────────────┘
```

---

### Mark as Read Behavior

**Before Fix** (Bug):
```dart
// Old code - LOST predictedRoom and roomConfidence
_notifications[index] = AppNotification(
  id: notification.id,
  // ... other fields
  read: true,
  // ❌ predictedRoom and roomConfidence NOT copied
);
```

**After Fix**:
```dart
// New code - PRESERVES all fields
_notifications[index] = AppNotification(
  id: notification.id,
  // ... other fields
  predictedRoom: notification.predictedRoom,       // ✓ Preserved
  roomConfidence: notification.roomConfidence,     // ✓ Preserved
  read: true,
);
```

**Why This Matters**: Room chip must remain visible after marking notification as read

---

### Notification Polling

**Home Screen** (`lib/screens/home_screen.dart`):
```dart
Timer.periodic(Duration(seconds: 30), (_) {
  _loadUnreadCount();  // Updates badge on bell icon
});

Future<void> _loadUnreadCount() async {
  final count = await NotificationService.instance.getUnreadCount();
  setState(() {
    _unreadCount = count;
  });
}
```

**Notifications Screen** (`lib/screens/notifications_screen.dart`):
```dart
@override
void initState() {
  super.initState();
  _loadNotifications();  // Load on screen open
}

// Also supports pull-to-refresh
RefreshIndicator(
  onRefresh: _loadNotifications,
  child: ListView(...),
)
```

**No Real-Time Push**: Currently uses polling. Could be improved with:
- Firebase Cloud Messaging (FCM)
- WebSocket connection
- Server-Sent Events (SSE)

---

## PART 16: TRACK ASSET

### Purpose

**Track Asset** shows a map with all community detection locations for a specific asset.

**Use Case**: After receiving notification "Your Laptop detected in Room 310", user wants to see detection history on a map.

---

### Track Asset Screen

**File**: `lib/screens/track_asset_screen.dart`

**Features**:
1. Interactive map (OpenStreetMap tiles)
2. Marker for each community detection
3. Popup showing detection details
4. Zoom/pan controls
5. Center on most recent detection

---

### Data Flow

```
User taps "Track Asset" on AssetDetailsScreen
↓
Navigate to TrackAssetScreen(asset: asset)
↓
initState() → _loadDetections()
↓
GET /api/community/detections/asset/:assetId
↓
Backend: backend/src/controllers/communityController.js → getDetectionsForAsset()
  ├─ Verify ownership: Asset.findOne({_id: assetId, userId: req.user._id})
  ├─ Fetch detections: CommunityDetection.find({assetId})
  │   .select('-detectedBy')  // Privacy: Hide detector identity
  │   .sort({detectedAt: -1}) // Newest first
  └─ Return: [{
      _id, trackerId, rssi,
      latitude, longitude,
      predictedRoom, roomConfidence,
      detectedAt, createdAt
    }, ...]
↓
Flutter: Convert to CommunityDetectionModel objects
↓
Build map with markers
```

---

### Map Implementation

**Package**: `flutter_map: ^7.0.2` + `latlong2: ^0.9.1`

```dart
FlutterMap(
  options: MapOptions(
    initialCenter: LatLng(
      _detections.first.latitude,
      _detections.first.longitude,
    ),
    initialZoom: 17.0,  // Room-level zoom
  ),
  children: [
    // Map tiles
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    
    // Detection markers
    MarkerLayer(
      markers: _detections.map((detection) {
        return Marker(
          point: LatLng(detection.latitude, detection.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showDetectionPopup(detection),
            child: Icon(
              Icons.location_on,
              color: _isRecent(detection) ? Colors.blue : Colors.grey,
              size: 40,
            ),
          ),
        );
      }).toList(),
    ),
  ],
)
```

---

### Detection Marker Popup

```dart
void _showDetectionPopup(CommunityDetectionModel detection) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Detection Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('Detected:', DateFormat('MMM d, h:mm a').format(detection.detectedAt)),
          _buildRow('Signal:', '${detection.rssi} dBm'),
          if (detection.predictedRoom != null) ...[
            _buildRow('Room:', detection.predictedRoom!),
            if (detection.roomConfidence != null)
              _buildRow('Confidence:', '${(detection.roomConfidence! * 100).round()}%'),
          ],
          _buildRow('Location:', '${detection.latitude.toStringAsFixed(4)}, ${detection.longitude.toStringAsFixed(4)}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}
```

---

### Example Display

**Map View**:
```
┌─────────────────────────────────────┐
│  🗺️ OpenStreetMap                    │
│                                      │
│         Building                     │
│    ┌──────────────┐                 │
│    │   📍 (blue)  │  ← Most recent  │
│    │   Room 310   │                 │
│    │              │                 │
│    │   📍 (grey)  │  ← Older        │
│    │   Room 312   │                 │
│    └──────────────┘                 │
│                                      │
│  [+ Zoom In] [- Zoom Out]           │
└─────────────────────────────────────┘
```

**Marker Popup**:
```
┌─────────────────────────────────┐
│ Detection Details               │
├─────────────────────────────────┤
│ Detected:    Aug 28, 2:30 PM    │
│ Signal:      -67 dBm            │
│ Room:        310                │
│ Confidence:  38%                │
│ Location:    1.3521, 103.8198   │
├─────────────────────────────────┤
│                  [Close]         │
└─────────────────────────────────┘
```

---

### Marker Color Logic

```dart
bool _isRecent(CommunityDetectionModel detection) {
  final age = DateTime.now().difference(detection.detectedAt);
  return age.inHours < 24;  // Blue if < 24 hours old, grey otherwise
}
```

---

### Security: Detector Privacy

**Backend excludes detector identity**:
```javascript
const detections = await CommunityDetection.find({ assetId })
  .select('-detectedBy')  // ← Remove detectedBy field
  .lean();
```

**Why**: Owner (User A) should NOT know who detected their asset (User B). Privacy protection for community members.

---

## PART 17: DASHBOARD

### Dashboard Statistics

**Screen**: `lib/screens/home_screen.dart`

**Three Key Metrics**:
1. **Total Assets**: Count of all user's assets (any status)
2. **Lost**: Count of assets with `status = 'LOST'`
3. **Tracking**: Count of LOST assets with recent community detections

---

### Dashboard API

**Endpoint**: `GET /api/dashboard/stats`

**File**: `backend/src/controllers/dashboardController.js`

```javascript
const getStats = async (req, res) => {
  try {
    const userId = req.user._id;

    // 1. Count total assets
    const totalAssets = await Asset.countDocuments({ userId });

    // 2. Count lost assets
    const lostAssets = await Asset.countDocuments({ userId, status: 'LOST' });

    // 3. Calculate "tracking" count
    // Definition: Lost assets with community detections in last 7 days
    const lostAssetsList = await Asset.find({ userId, status: 'LOST' });
    
    const trackingPromises = lostAssetsList.map(async (asset) => {
      const recentDetection = await CommunityDetection.findOne({
        assetId: asset._id,
        detectedAt: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }  // Last 7 days
      });
      return recentDetection ? 1 : 0;
    });
    
    const trackingResults = await Promise.all(trackingPromises);
    const trackingAssets = trackingResults.reduce((sum, val) => sum + val, 0);

    res.json({
      success: true,
      totalAssets,
      lostAssets,
      trackingAssets,
    });
  } catch (err) {
    console.error('[Dashboard] getStats error:', err);
    res.status(500).json({ success: false, message: 'Failed to get stats' });
  }
};
```

---

### "Tracking" Calculation Explained

**Definition**: "Tracking" = LOST assets that have been recently detected by community

**Algorithm**:
```
1. Find all assets with status='LOST'
2. For each lost asset:
   a. Query CommunityDetection collection
   b. Check if any detection in last 7 days
   c. If yes → Count as "tracking"
   d. If no → Not tracking
3. Sum the count
```

**Example Scenario**:
```
User A has:
- Asset 1 (Laptop): LOST, detected yesterday → Tracking ✓
- Asset 2 (Wallet): LOST, detected 10 days ago → Not tracking ✗
- Asset 3 (Keys): LOST, never detected → Not tracking ✗
- Asset 4 (Bag): ACTIVE → Not applicable

Dashboard shows:
- Total Assets: 4
- Lost: 3
- Tracking: 1  (only Asset 1)
```

---

### Dashboard UI

**File**: `lib/screens/home_screen.dart`

```dart
Widget _buildStatsCards() {
  return Row(
    children: [
      Expanded(
        child: _buildStatCard(
          title: 'Total Assets',
          count: _stats?.totalAssets ?? 0,
          icon: Icons.inventory_2_outlined,
          color: Colors.blue,
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: _buildStatCard(
          title: 'Lost',
          count: _stats?.lostAssets ?? 0,
          icon: Icons.search_outlined,
          color: Colors.red,
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: _buildStatCard(
          title: 'Tracking',
          count: _stats?.trackingAssets ?? 0,
          icon: Icons.radar_outlined,
          color: Colors.green,
        ),
      ),
    ],
  );
}
```

**Visual Display**:
```
┌─────────────────────────────────────┐
│ Dashboard                            │
├─────────────────────────────────────┤
│ ┌───────┐ ┌───────┐ ┌───────┐      │
│ │  📦   │ │  🔍   │ │  📡   │      │
│ │   10  │ │   2   │ │   1   │      │
│ │ Total │ │ Lost  │ │Track  │      │
│ └───────┘ └───────┘ └───────┘      │
└─────────────────────────────────────┘
```

---

### What "Tracking" Means

**User Perspective**: "How many of my lost items are actively being tracked?"

**Technical Meaning**: Lost assets with recent (< 7 days) community detections

**Why 7 Days?**: Balance between:
- Too short (1 day): Asset might be tracking but shows as not tracking
- Too long (30 days): Stale data, asset might have moved elsewhere

**Use Case**: If "Tracking" count is 0, user knows community hasn't seen their lost asset recently → Consider expanding search area

---

## PART 18: MARK AS RECOVERED

### Purpose

User finds their lost asset physically → Marks it as recovered → System stops generating notifications

---

### Recovery Flow

```
User finds Laptop physically
↓
Opens AssetDetailsScreen
↓
Taps "Mark as Recovered" button
↓
Confirmation dialog: "Have you recovered this asset?"
↓
User confirms
↓
lib/services/asset_service.dart → markAsRecovered(asset.id)
↓
lib/services/api_service.dart → put('/api/assets/${asset.id}/recover')
↓
HTTP PUT → backend:5000/api/assets/:id/recover
↓
backend/src/middleware/auth.js → protect() [Verify JWT]
↓
backend/src/controllers/assetController.js → recoverAsset()
  ├─ Verify ownership:
  │   Asset.findOne({_id: req.params.id, userId: req.user._id})
  ├─ If not found → 404
  └─ If found:
      ├─ Update status: asset.status = 'RECOVERED'
      ├─ Save: await asset.save()
      └─ Return updated asset
↓
Flutter receives response: {_id, name, status: 'RECOVERED', ...}
↓
Update UI:
  ├─ AssetDetailsScreen shows green "RECOVERED" badge
  ├─ "Mark as Lost" button reappears
  └─ "Mark as Recovered" button disappears
↓
Navigate back to MyAssetsScreen
↓
Asset list refreshed → Laptop shows "RECOVERED" status
```

---

### Critical Behavior After Recovery

**Future Detection Scenario**:
```
User A marks Laptop as RECOVERED
↓
User B's phone detects AG-001 again (maybe User A is carrying it on campus)
↓
POST /api/community/detections {trackerId: "AG-001", ...}
↓
Backend: Asset.findOne({trackerId: "AG-001"})
↓
Asset found, but status = 'RECOVERED' (not 'LOST')
↓
backend/src/controllers/communityController.js:
  if (asset.status !== 'LOST') {
    return error(res, 'Asset not found', 404);  ← Detection rejected
  }
↓
NO CommunityDetection record created
NO Notification created
User A does NOT receive notification
↓
User B's phone logs: "[Community] ✗ Detection rejected by backend"
```

---

### Code Implementation

**Backend** (`backend/src/controllers/assetController.js`):
```javascript
const recoverAsset = async (req, res) => {
  try {
    // Find asset owned by authenticated user
    const asset = await Asset.findOne({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!asset) {
      return res.status(404).json({
        success: false,
        message: 'Asset not found',
      });
    }

    // Update status to RECOVERED
    asset.status = 'RECOVERED';
    await asset.save();

    console.log('[Asset] Asset recovered:', asset.trackerId);
    console.log('[Asset] Status changed: LOST → RECOVERED');

    res.json({
      success: true,
      message: 'Asset marked as recovered',
      asset,
    });
  } catch (err) {
    console.error('[Asset] recoverAsset error:', err);
    res.status(500).json({
      success: false,
      message: 'Failed to recover asset',
    });
  }
};
```

**Flutter** (`lib/services/asset_service.dart`):
```dart
Future<Asset> markAsRecovered(String assetId) async {
  try {
    final response = await ApiService.instance.put('/api/assets/$assetId/recover', {});
    return Asset.fromJson(response['asset']);
  } catch (e) {
    debugPrint('[AssetService] Failed to mark as recovered: $e');
    rethrow;
  }
}
```

---

### UI Changes

**AssetDetailsScreen Before Recovery**:
```
┌─────────────────────────────────────┐
│ Laptop                               │
│ AG-001                  🔴 LOST     │
├─────────────────────────────────────┤
│ Category: Electronics                │
│ Description: MacBook Pro             │
├─────────────────────────────────────┤
│ [Edit] [Delete]                      │
│ [Track Asset]                        │
│ [Mark as Recovered] ← Button appears │
└─────────────────────────────────────┘
```

**AssetDetailsScreen After Recovery**:
```
┌─────────────────────────────────────┐
│ Laptop                               │
│ AG-001              🟢 RECOVERED    │
├─────────────────────────────────────┤
│ Category: Electronics                │
│ Description: MacBook Pro             │
├─────────────────────────────────────┤
│ [Edit] [Delete]                      │
│ [Mark as Lost] ← Button reappears    │
│                                      │
└─────────────────────────────────────┘
```

---

### Dashboard Impact

**Before Recovery**:
```
Total Assets: 10
Lost: 2 (Laptop + Wallet)
Tracking: 1 (Laptop has recent detections)
```

**After Recovery**:
```
Total Assets: 10 (unchanged)
Lost: 1 (only Wallet now)
Tracking: 0 (Laptop no longer LOST, so not counted)
```

---

### Why Status Check is Critical

**Without Status Check** (Bad):
```
User A recovers asset → Marks as RECOVERED
But backend still accepts detections
User A receives notifications forever
Spam notifications even though asset is found
```

**With Status Check** (Good):
```
User A recovers asset → Marks as RECOVERED
Backend rejects future detections (status check fails)
NO notifications after recovery
Clean user experience
```

**Code Location**: `backend/src/controllers/communityController.js` (Line ~141)

---

## PART 19: ERROR HANDLING

### Permission Errors

**Bluetooth Permission Denied**:
```
User enables Community Sensing
↓
Request permissions: await Permission.bluetoothScan.request()
↓
User denies permission
↓
Return error: CommunitySensingStartResult.bluetoothPermissionDenied
↓
Show dialog: "Bluetooth permission required for community sensing..."
Offer "Open Settings" button
```

**Location Permission Denied**:
```
Similar flow to Bluetooth
Show rationale: "Location permission required to detect nearby trackers"
```

---

### Wi-Fi Scan Errors

**Wi-Fi Unavailable**:
```dart
try {
  final result = await WifiScanService.instance.scanNieAccessPoints();
  if (result is WifiScanFailure) {
    debugPrint('[CommunityWiFi] Wi-Fi scan failed: ${result.reason}');
    // Continue - BLE detection still works
    // Just no room prediction
  }
} catch (e) {
  debugPrint('[CommunityWiFi] Wi-Fi error: $e');
  // Continue - graceful degradation
}
```

**No NIE Networks Found**:
```
Wi-Fi scan succeeds, but filters return empty list
Log: "[CommunityWiFi] Wi-Fi scan completed — no NIE APs nearby"
Detection proceeds without Wi-Fi fingerprint
No room prediction, but detection still recorded
```

---

### Backend/API Errors

**Authentication Failure**:
```
Flutter makes API call with invalid/expired JWT
↓
Backend middleware: protect()
  jwt.verify(token, SECRET) → throws error
↓
Return 401 "Not authorized - token invalid"
↓
Flutter ApiService catches:
  if (statusCode == 401) {
    // Token expired - log out user
    AuthService.instance.logout();
    Navigate to LoginScreen;
  }
```

**Asset Not Found** (404):
```
User B detects tracker "AG-999"
↓
POST /api/community/detections {trackerId: "AG-999"}
↓
Backend: Asset.findOne({trackerId: "AG-999"})
↓
Result: null (no asset with that tracker ID)
↓
Return 404 "Asset not found"
↓
Flutter logs: "[Community] ℹ Tracker AG-999 not LOST or not found — this is normal"
↓
Continue scanning (not an error, just not registered)
```

**Detection Rejected** (Asset not LOST):
```
Asset is ACTIVE or RECOVERED
Backend returns 404 (same response as "not found" for security)
Flutter logs: "[Community] ℹ Tracker rejected — might be owned by current user"
Continue scanning
```

---

### ML Server Errors

**ML Server Unreachable**:
```javascript
try {
  const mlResponse = await fetch(mlUrl, {timeout: 10s});
} catch (mlErr) {
  if (mlErr.name === 'AbortError') {
    console.log('[CommunityWiFi] ✗ ML prediction timed out');
  } else {
    console.log('[CommunityWiFi] ✗ ML prediction failed:', mlErr.message);
  }
  // Continue without room prediction
  predictedRoom = null;
  roomConfidence = null;
}

// Detection still succeeds
const detection = await CommunityDetection.create({
  predictedRoom: null,  // No room
  roomConfidence: null,
  // ... other fields
});
```

**Result**: Notification sent without room number (GPS only or basic message)

---

### Database Errors

**MongoDB Connection Failure**:
```javascript
// backend/src/config/db.js
try {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('MongoDB connected');
} catch (err) {
  console.error('MongoDB connection error:', err);
  process.exit(1);  // Exit if database unavailable
}
```

**Duplicate Key Error** (Asset tracker ID):
```
User tries to create asset with tracker ID that already exists
↓
Asset.create({userId, trackerId: "AG-001"}) throws MongoError
↓
Catch in assetController.js:
  if (err.code === 11000) {
    return res.status(400).json({
      message: 'Tracker ID already in use',
    });
  }
```

---

### Notification Failure

**Notification Creation Fails**:
```javascript
try {
  const notification = await Notification.create({...});
  console.log('[Community] Notification created');
} catch (notifErr) {
  // DO NOT fail the detection
  console.error('[Community] Failed to create notification:', notifErr);
  console.error('[Community] Detection still recorded successfully');
}
// Detection record still saved
// Owner won't get notification, but data is preserved
```

**Why Non-Critical**: Detection is more important than notification. Notification can be recreated later if needed.

---

### Network Errors (Flutter)

**No Internet Connection**:
```dart
// lib/services/api_service.dart
try {
  final response = await http.post(url, ...);
} on SocketException {
  throw ApiException(0, 'No internet connection');
} on TimeoutException {
  throw ApiException(0, 'Request timed out');
} catch (e) {
  throw ApiException(0, 'Network error: $e');
}
```

**User Feedback**:
```dart
try {
  await AssetService.instance.createAsset(asset);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Asset created successfully')),
  );
} on ApiException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.message),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

### Error Logging

**Flutter Logging**:
```dart
debugPrint('[Service] Error description');  // Console output
```

**Backend Logging**:
```javascript
console.log('[Controller] Info message');
console.error('[Controller] Error:', err);
console.error('[Controller] Stack trace:', err.stack);
```

**Production Logging**: In production, use proper logging service (Winston, Sentry, etc.)

---

## PART 20: SECURITY

### Authentication

**JWT (JSON Web Token)**:
- Generated on login/register
- Contains user ID (not sensitive data)
- Signed with secret key (`JWT_SECRET`)
- Expires after 7 days
- Verified on every protected route

**Password Security**:
- Never stored in plain text
- Hashed with bcrypt (10 salt rounds)
- Even database admins cannot see passwords
- Password reset requires email verification

**Example**:
```javascript
// Hashing password before saving
const hashedPassword = await bcrypt.hash(password, 10);
user.password = hashedPassword;

// Verifying password during login
const isMatch = await bcrypt.compare(enteredPassword, user.password);
```

---

### Authorization

**Ownership Verification**:

Every operation that modifies/reads an asset checks ownership:

```javascript
// Get asset
const asset = await Asset.findOne({
  _id: assetId,
  userId: req.user._id,  // ← Only user's own asset
});

if (!asset) {
  return res.status(404).json({ message: 'Asset not found' });
}
```

**Why**: Prevents User A from accessing/modifying User B's assets

---

### API Protection

**Protected Routes**:
```javascript
// All routes require JWT
router.use(protect);  // Middleware applied to all routes below

router.get('/assets', getAssets);           // Protected
router.post('/assets', createAsset);        // Protected
router.delete('/assets/:id', deleteAsset);  // Protected
```

**Public Routes** (No authentication required):
```javascript
router.post('/auth/register', register);  // Create account
router.post('/auth/login', login);        // Get JWT
router.get('/auth/verify-email', verifyEmail);  // Email verification
```

---

### Data Privacy

**Detector Identity Hidden**:
```javascript
// When fetching detections for Track Asset
const detections = await CommunityDetection.find({ assetId })
  .select('-detectedBy')  // ← Remove detector user ID
  .lean();
```

**Why**: User A should NOT know that User B detected their asset (privacy)

**Only Shared**:
- Detection location (GPS)
- Detection time
- Signal strength (RSSI)
- Predicted room

**Not Shared**:
- Who detected it (User B's identity)
- User B's personal information

---

### Input Validation

**Backend Validation** (express-validator):
```javascript
const createAssetValidators = [
  body('name')
    .trim()
    .notEmpty().withMessage('Name is required')
    .isLength({ max: 100 }).withMessage('Name too long'),
  body('trackerId')
    .trim()
    .notEmpty().withMessage('Tracker ID required')
    .matches(/^AG-\d+$/).withMessage('Invalid tracker ID format'),
];

router.post('/assets', createAssetValidators, validate, createAsset);
```

**Flutter Validation**:
```dart
if (nameController.text.trim().isEmpty) {
  setState(() => _error = 'Name is required');
  return;
}

if (!RegExp(r'^AG-\d+$').hasMatch(trackerIdController.text)) {
  setState(() => _error = 'Tracker ID must be AG-XXX format');
  return;
}
```

**Defense in Depth**: Validate on both client (UX) and server (security)

---

### Environment Variables

**File**: `backend/.env`

```
# Sensitive data (NEVER commit to Git)
JWT_SECRET=abc123...
RESEND_API_KEY=re_xxx...
MONGO_URI=mongodb://localhost:27017/assetguard_db
ML_API_URL=http://10.135.90.221:8000
```

**`.gitignore` Protection**:
```
# backend/.gitignore
.env           ← Git will not track this file
node_modules/
```

**Why**: Secrets in Git history are permanent and can be exploited

---

### Security Best Practices

**1. Never Log Sensitive Data**:
```javascript
// ❌ Bad
console.log('[Auth] Token:', token);  // Exposes JWT

// ✅ Good
console.log('[Auth] Token provided:', !!token);  // Just boolean
```

**2. Always Verify Ownership**:
```javascript
// ❌ Bad
const asset = await Asset.findById(assetId);  // Any asset

// ✅ Good
const asset = await Asset.findOne({ _id: assetId, userId: req.user._id });
```

**3. Use HTTPS in Production**:
- Development: `http://localhost:5000` (OK)
- Production: `https://api.assetguard.app` (Required)

**4. Rate Limiting** (Not implemented, but should be):
```javascript
// Limit login attempts to prevent brute force
const rateLimit = require('express-rate-limit');
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 5,  // 5 attempts per IP
});
router.post('/auth/login', loginLimiter, login);
```

---

### What is NOT Secure (Development Mode)

**Email Verification Bypass**:
```javascript
if (process.env.EMAIL_VERIFICATION_ENABLED === 'false') {
  // Development: Auto-verify email
  user.emailVerified = true;
}
```

**Why**: Faster development/testing. **Must enable** in production!

**No HTTPS**:
- Development uses HTTP
- JWTs transmitted in plain text
- **Must use HTTPS** in production

**Weak JWT Secret**:
- Development may use simple secret
- **Must use strong random secret** in production (e.g., 64-character random string)

---

## PART 21: COMPLETE END-TO-END WORKFLOW

### Complete User Journey with File Names

```
═══════════════════════════════════════════════════════════
PHASE 1: USER A (ASSET OWNER) SETUP
═══════════════════════════════════════════════════════════

User A opens app
├─ lib/main.dart → main()
├─ lib/screens/splash_screen.dart → Check auto-login
├─ lib/services/auth_service.dart → tryAutoLogin()
│   └─ No token found → Navigate to LoginScreen
│
User A creates account
├─ lib/screens/register_screen.dart
│   ├─ Enter: name="Alice", email="alice@example.com", password="pass123"
│   └─ Tap "Register"
├─ lib/services/auth_service.dart → register()
├─ lib/services/api_service.dart → post('/api/auth/register')
│   └─ POST http://backend:5000/api/auth/register
├─ backend/src/routes/authRoutes.js → POST /auth/register
├─ backend/src/controllers/authController.js → register()
│   ├─ Validate input
│   ├─ Hash password: bcrypt.hash()
│   ├─ backend/src/models/User.js → User.create()
│   │   └─ MongoDB: users collection → INSERT {name, email, password}
│   ├─ Generate JWT: jwt.sign({userId}, SECRET, {expiresIn: '7d'})
│   └─ Return: {token, user}
├─ Flutter receives response
├─ lib/services/auth_service.dart → Save token to SharedPreferences
└─ Navigate to HomeScreen
│
User A creates asset
├─ lib/screens/home_screen.dart → Tap "Add Asset"
├─ lib/screens/add_asset_screen.dart
│   ├─ Enter: name="Laptop", category="Electronics", trackerId="AG-001"
│   └─ Tap "Add Asset"
├─ lib/services/asset_service.dart → createAsset()
├─ lib/services/api_service.dart → post('/api/assets', {name, category, trackerId})
│   ├─ Headers: Authorization: Bearer <Alice's JWT>
│   └─ POST http://backend:5000/api/assets
├─ backend/src/routes/assetRoutes.js → POST /assets
├─ backend/src/middleware/auth.js → protect()
│   ├─ Extract JWT from header
│   ├─ Verify JWT: jwt.verify(token, SECRET)
│   ├─ Look up user: User.findById(decoded.userId)
│   ├─ Attach to request: req.user = Alice
│   └─ Call next()
├─ backend/src/controllers/assetController.js → createAsset()
│   ├─ backend/src/models/Asset.js → Asset.create()
│   └─ MongoDB: assets collection → INSERT
│       {
│         name: "Laptop",
│         category: "Electronics",
│         trackerId: "AG-001",
│         status: "ACTIVE",
│         userId: Alice._id
│       }
├─ Return: {_id, name, trackerId, status, ...}
└─ Flutter: Navigate back, refresh asset list
│
Asset appears in My Assets:
├─ lib/screens/my_assets_screen.dart
│   └─ Shows: "Laptop" (AG-001) - Green "ACTIVE" badge

═══════════════════════════════════════════════════════════
PHASE 2: USER A LOSES ASSET
═══════════════════════════════════════════════════════════

User A loses Laptop
├─ lib/screens/my_assets_screen.dart → Tap "Laptop"
├─ lib/screens/asset_details_screen.dart → Tap "Mark as Lost"
├─ lib/services/asset_service.dart → markAsLost(asset.id)
├─ lib/services/api_service.dart → put('/api/assets/${asset.id}/status', {status: 'LOST'})
│   ├─ Headers: Authorization: Bearer <Alice's JWT>
│   └─ PUT http://backend:5000/api/assets/:id/status
├─ backend/src/middleware/auth.js → protect() [Verify Alice]
├─ backend/src/controllers/assetController.js → updateStatus()
│   ├─ Find asset: Asset.findOne({_id, userId: Alice._id})
│   ├─ Verify ownership ✓
│   ├─ Update: asset.status = 'LOST'
│   ├─ Save to MongoDB
│   └─ Return updated asset
└─ Flutter: Update UI → Red "LOST" badge, "Mark as Recovered" button appears

Dashboard changes:
├─ GET /api/dashboard/stats
├─ backend/src/controllers/dashboardController.js → getStats()
│   ├─ totalAssets: 1
│   ├─ lostAssets: 1
│   └─ trackingAssets: 0 (no detections yet)
└─ lib/screens/home_screen.dart → Display updated stats

═══════════════════════════════════════════════════════════
PHASE 3: USER B (COMMUNITY MEMBER) SETUP
═══════════════════════════════════════════════════════════

User B opens app, registers, logs in (similar flow to User A)
│
User B enables Community Sensing
├─ lib/screens/home_screen.dart → Tap "Enable Community Sensing"
├─ lib/services/community_sensing_service.dart → start()
│   ├─ Request permissions:
│   │   ├─ Permission.bluetoothScan.request()
│   │   ├─ Permission.location.request()
│   │   └─ Permission.notification.request()
│   ├─ User grants permissions ✓
│   ├─ FlutterForegroundTask.startService()
│   │   ├─ Android displays persistent notification
│   │   └─ "AssetGuard Community Sensing - Starting..."
│   ├─ _startBleScanTimer()
│   │   └─ Timer.periodic(15 seconds, _performBleScan)
│   └─ _startWifiScanTimer()
│       └─ Timer.periodic(15 seconds, _performWifiScan)
└─ Service is now running in background

═══════════════════════════════════════════════════════════
PHASE 4: AUTOMATIC BACKGROUND SCANNING (USER B)
═══════════════════════════════════════════════════════════

Every 15 seconds - Wi-Fi Scan:
├─ lib/services/community_sensing_service.dart → _performWifiScan()
├─ lib/services/wifi_scan_service.dart → scanNieAccessPoints()
│   ├─ wifi_scan package → Android Wi-Fi APIs
│   └─ Returns: 74 NIE access points with BSSIDs + RSSIs
├─ Filter: Only NIE-STUDENTS and NIE-STAFF
├─ Convert to Map: {"84:d8:1b:aa:bb:cc": -43, ...}
├─ lib/services/wifi_fingerprint_cache.dart → update(fingerprint)
│   ├─ Store in memory: _fingerprint = fingerprint
│   └─ Store timestamp: _timestamp = now
└─ Upload to backend:
    ├─ POST /api/community/scan {wifiFingerprint: [...]}
    ├─ backend/src/controllers/communityController.js → submitScan()
    └─ MongoDB: communityfingerprints → INSERT (historical record)

Every 15 seconds - BLE Scan:
├─ lib/services/community_sensing_service.dart → _performBleScan()
├─ Get known tracker IDs:
│   ├─ lib/services/asset_service.dart → getAssets()
│   └─ Extract: ["AG-001", "AG-002", ...] (User B's assets + any visible)
├─ lib/services/ble_service.dart → scan(knownTrackerIds, 8)
│   ├─ flutter_blue_plus → FlutterBluePlus.startScan(timeout: 8s)
│   ├─ Android Bluetooth stack scans for BLE devices
│   └─ Returns: List of detected devices with names + RSSIs
├─ Filter AssetGuard trackers:
│   ├─ Check device name matches: "AssetGuard-AG-XXX"
│   ├─ Extract tracker ID: "AG-001"
│   └─ Verify: Starts with "AG-" or in knownTrackerIds
└─ Result: [BleDevice(trackerId: "AG-001", rssi: -67, ...)]

═══════════════════════════════════════════════════════════
PHASE 5: DETECTION HAPPENS (AG-001 FOUND!)
═══════════════════════════════════════════════════════════

BLE detects AG-001:
├─ lib/services/community_sensing_service.dart → _performBleScan()
│   └─ Detected: AG-001, RSSI: -67 dBm
├─ Check debounce:
│   ├─ lib/services/community_detection_service.dart → shouldReport("AG-001")
│   └─ Last reported > 60s ago? YES → Continue
├─ Get cached Wi-Fi:
│   ├─ lib/services/wifi_fingerprint_cache.dart → get()
│   ├─ Check age: < 2 minutes? YES
│   └─ Return: {"84:d8:1b:aa:bb:cc": -43, ... (74 BSSIDs)}
├─ Get GPS:
│   ├─ lib/services/location_service.dart → getPosition()
│   └─ Returns: Latitude: 1.3521, Longitude: 103.8198
└─ Submit detection:
    lib/services/community_detection_service.dart → reportDetection()
    ├─ Build payload:
    │   {
    │     trackerId: "AG-001",
    │     rssi: -67,
    │     remoteId: "AA:BB:CC:DD:EE:FF",
    │     detectedAt: "2026-08-28T14:30:00Z",
    │     latitude: 1.3521,
    │     longitude: 103.8198,
    │     wifiFingerprint: {"84:d8:1b:aa:bb:cc": -43, ...}
    │   }
    ├─ lib/services/api_service.dart → post('/api/community/detections', payload)
    │   ├─ Headers: Authorization: Bearer <Bob's JWT>
    │   └─ POST http://backend:5000/api/community/detections
    └─ Logs: "[Community] ► SUBMITTING DETECTION TO BACKEND"

═══════════════════════════════════════════════════════════
PHASE 6: BACKEND PROCESSES DETECTION
═══════════════════════════════════════════════════════════

Backend receives detection:
├─ backend/src/routes/communityRoutes.js → POST /detections
├─ backend/src/middleware/auth.js → protect()
│   └─ Verify JWT → Extract User B
├─ backend/src/controllers/communityController.js → submitCommunityDetection()
│
│   Step 1: Look up asset
│   ├─ backend/src/models/Asset.js → Asset.findOne({trackerId: "AG-001"})
│   │   .populate('userId', 'name email')
│   ├─ MongoDB: assets collection → FIND {trackerId: "AG-001"}
│   └─ Result: Asset found
│       ├─ _id: "675..."
│       ├─ name: "Laptop"
│       ├─ trackerId: "AG-001"
│       ├─ status: "LOST"  ← CRITICAL
│       ├─ userId: Alice (populated)
│       └─ Owner: Alice (_id, name, email)
│
│   Step 2: ⭐ CRITICAL CHECK - Status must be LOST
│   ├─ if (asset.status !== 'LOST')
│   │   └─ return 404 "Asset not found"
│   ├─ asset.status === 'LOST' ✓
│   └─ Continue
│
│   Step 3: Security check - Detector ≠ Owner
│   ├─ if (asset.userId._id === req.user._id)
│   │   └─ return 404 "Cannot report own asset"
│   ├─ User B ≠ Alice ✓
│   └─ Continue
│
│   Step 4: ML Room Prediction
│   ├─ Check: wifiFingerprint exists and not empty? YES
│   ├─ Call Python ML Server:
│   │   ├─ URL: http://10.135.90.221:8000/predict-room
│   │   ├─ Method: POST
│   │   ├─ Body: {wifi: {"84:d8:1b:aa:bb:cc": -43, ...}}
│   │   ├─ Timeout: 10 seconds
│   │   └─ fetch(mlUrl, {method: 'POST', body: JSON.stringify({wifi})})
│   │
│   ├─ ═══ ML SERVER PROCESSES (Separate Python Project) ═══
│   │   ├─ Receive Wi-Fi fingerprint
│   │   ├─ Extract RSSI for 106 known BSSIDs
│   │   ├─ Build feature vector: [-43, -67, -100, -89, ...]
│   │   ├─ Pass to Random Forest model (97.96% accuracy)
│   │   ├─ Model predicts probabilities for 22 rooms
│   │   └─ Return top prediction:
│   │       {
│   │         room: "310",
│   │         confidence: 0.376667,
│   │         top_predictions: [...]
│   │       }
│   │
│   ├─ Backend receives ML response: HTTP 200 OK
│   ├─ Extract: predictedRoom = "310"
│   ├─ Extract: roomConfidence = 0.376667
│   └─ Logs:
│       "[CommunityWiFi] ✓ ML predicted room: 310"
│       "[CommunityWiFi] ✓ Confidence: 0.376667"
│
│   Step 5: Create CommunityDetection record
│   ├─ backend/src/models/CommunityDetection.js → CommunityDetection.create()
│   └─ MongoDB: communitydetections collection → INSERT
│       {
│         _id: "675...",
│         trackerId: "AG-001",
│         assetId: Alice's asset _id,
│         detectedBy: Bob's user _id,
│         rssi: -67,
│         remoteId: "AA:BB:CC:DD:EE:FF",
│         detectedAt: ISODate("2026-08-28T14:30:00Z"),
│         latitude: 1.3521,
│         longitude: 103.8198,
│         predictedRoom: "310",  ← From ML
│         roomConfidence: 0.376667,  ← From ML
│         createdAt: ISODate("2026-08-28T14:30:05Z")
│       }
│
│   Step 6: Build notification message
│   ├─ predictedRoom exists? YES
│   ├─ message = "Your Laptop (AG-001) was detected near Room 310."
│   ├─ Add confidence: message += " (38% confidence)"
│   └─ Final: "Your Laptop (AG-001) was detected near Room 310. (38% confidence)"
│
│   Step 7: Create Notification for Owner (Alice)
│   ├─ backend/src/models/Notification.js → Notification.create()
│   └─ MongoDB: notifications collection → INSERT
│       {
│         _id: "675...",
│         recipient: Alice's user _id,
│         type: "asset_detected",
│         title: "Asset Detected",
│         message: "Your Laptop (AG-001) was detected near Room 310. (38% confidence)",
│         assetId: Alice's asset _id,
│         detectionId: Detection _id,
│         trackerId: "AG-001",
│         latitude: 1.3521,
│         longitude: 103.8198,
│         rssi: -67,
│         detectedAt: ISODate("2026-08-28T14:30:00Z"),
│         predictedRoom: "310",
│         roomConfidence: 0.376667,
│         read: false,
│         createdAt: ISODate("2026-08-28T14:30:05Z")
│       }
│
│   Step 8: Return response to User B
│   └─ res.status(201).json({
│       success: true,
│       message: "Community detection recorded. Asset owner will be notified.",
│       detectionId: "675...",
│       predictedRoom: "310",
│       confidence: 0.376667
│     })

Flutter (User B) receives response:
├─ lib/services/community_detection_service.dart
├─ Logs:
│   "[Community] ◄ BACKEND RESPONSE RECEIVED"
│   "[CommunityWiFi] ✓ Predicted room: 310"
│   "[CommunityWiFi] ✓ Confidence: 0.376667"
└─ Update debounce: _lastReported["AG-001"] = now

═══════════════════════════════════════════════════════════
PHASE 7: USER A (ALICE) RECEIVES NOTIFICATION
═══════════════════════════════════════════════════════════

Alice opens app (or refreshes):
├─ lib/screens/home_screen.dart → Timer polls every 30s
├─ lib/services/notification_service.dart → getUnreadCount()
│   ├─ GET http://backend:5000/api/notifications/unread/count
│   ├─ backend/src/controllers/notificationController.js → getUnreadCount()
│   ├─ MongoDB: notifications.countDocuments({recipient: Alice._id, read: false})
│   └─ Returns: {count: 1}
└─ Update bell icon badge: Shows "1"

Alice taps "Notifications":
├─ lib/screens/notifications_screen.dart → initState()
├─ lib/services/notification_service.dart → getNotifications()
│   ├─ GET http://backend:5000/api/notifications
│   ├─ backend/src/controllers/notificationController.js → getNotifications()
│   ├─ MongoDB: notifications.find({recipient: Alice._id})
│   │   .sort({read: 1, createdAt: -1})  // Unread first, newest first
│   └─ Returns: [{
│       _id: "675...",
│       type: "asset_detected",
│       title: "Asset Detected",
│       message: "Your Laptop (AG-001) was detected near Room 310. (38% confidence)",
│       assetId: "675...",
│       trackerId: "AG-001",
│       predictedRoom: "310",
│       roomConfidence: 0.376667,
│       latitude: 1.3521,
│       longitude: 103.8198,
│       rssi: -67,
│       detectedAt: "2026-08-28T14:30:00Z",
│       read: false,
│       createdAt: "2026-08-28T14:30:05Z"
│     }]
├─ lib/models/notification_model.dart → AppNotification.fromJson()
└─ lib/screens/notifications_screen.dart → _buildNotificationCard()
    └─ Display:
        ┌─────────────────────────────────────────┐
        │ 📍 Asset Detected                   ●   │
        │    2m ago                                │
        │                                          │
        │ Your Laptop (AG-001) was detected       │
        │ near Room 310. (38% confidence)         │
        │                                          │
        │ [AG-001] [🚪 Room 310 (38%)] [-67 dBm] │
        │ [1.3521, 103.8198] [Aug 28, 2:30 PM]   │
        └─────────────────────────────────────────┘

Alice taps notification:
├─ Navigate to AssetDetailsScreen(asset: Laptop)
└─ Alice sees: "Track Asset" button

═══════════════════════════════════════════════════════════
PHASE 8: ALICE VIEWS TRACK ASSET MAP
═══════════════════════════════════════════════════════════

Alice taps "Track Asset":
├─ lib/screens/track_asset_screen.dart → initState()
├─ _loadDetections()
│   ├─ GET http://backend:5000/api/community/detections/asset/:assetId
│   ├─ backend/src/controllers/communityController.js → getDetectionsForAsset()
│   │   ├─ Verify ownership: Asset.findOne({_id: assetId, userId: Alice._id})
│   │   ├─ Fetch detections: CommunityDetection.find({assetId})
│   │   │   .select('-detectedBy')  // Hide User B identity
│   │   │   .sort({detectedAt: -1})
│   │   └─ Returns: [{
│   │       _id, trackerId, rssi,
│   │       latitude: 1.3521,
│   │       longitude: 103.8198,
│   │       predictedRoom: "310",
│   │       roomConfidence: 0.376667,
│   │       detectedAt: "2026-08-28T14:30:00Z"
│   │     }]
│   └─ Convert to CommunityDetectionModel objects
└─ Build map:
    ├─ flutter_map widget
    ├─ OpenStreetMap tiles
    ├─ Center: (1.3521, 103.8198)
    ├─ Zoom level: 17 (room-level detail)
    └─ Marker:
        ├─ Position: (1.3521, 103.8198)
        ├─ Icon: Blue location pin
        └─ Popup on tap:
            ┌─────────────────────────────────┐
            │ Detection Details               │
            ├─────────────────────────────────┤
            │ Detected:    Aug 28, 2:30 PM    │
            │ Signal:      -67 dBm            │
            │ Room:        310                │
            │ Confidence:  38%                │
            │ Location:    1.3521, 103.8198   │
            ├─────────────────────────────────┤
            │                  [Close]         │
            └─────────────────────────────────┘

Alice knows: "My Laptop was seen in Room 310!"

═══════════════════════════════════════════════════════════
PHASE 9: ALICE RECOVERS ASSET
═══════════════════════════════════════════════════════════

Alice physically finds Laptop in Room 310
├─ Opens AssetDetailsScreen
└─ Taps "Mark as Recovered"

Recovery flow:
├─ Confirmation dialog: "Have you recovered this asset?"
├─ Alice taps "Yes"
├─ lib/services/asset_service.dart → markAsRecovered(asset.id)
├─ lib/services/api_service.dart → put('/api/assets/${asset.id}/recover')
│   └─ PUT http://backend:5000/api/assets/:id/recover
├─ backend/src/middleware/auth.js → protect() [Verify Alice]
├─ backend/src/controllers/assetController.js → recoverAsset()
│   ├─ Find: Asset.findOne({_id, userId: Alice._id})
│   ├─ Update: asset.status = 'RECOVERED'
│   ├─ Save to MongoDB
│   └─ Logs:
│       "[Asset] Asset recovered: AG-001"
│       "[Asset] Status changed: LOST → RECOVERED"
└─ Return: {_id, name, status: 'RECOVERED', ...}

Flutter updates UI:
├─ AssetDetailsScreen
│   ├─ Status badge: Red "LOST" → Green "RECOVERED"
│   ├─ "Mark as Recovered" button disappears
│   └─ "Mark as Lost" button reappears
└─ Navigate back to MyAssetsScreen
    └─ Laptop shows green "RECOVERED" badge

Dashboard updates:
├─ GET /api/dashboard/stats
└─ New stats:
    ├─ totalAssets: 1 (unchanged)
    ├─ lostAssets: 0 (was 1, now 0)
    └─ trackingAssets: 0 (was 1, now 0)

═══════════════════════════════════════════════════════════
PHASE 10: FUTURE DETECTIONS IGNORED
═══════════════════════════════════════════════════════════

Later, User B detects AG-001 again (maybe Alice is carrying Laptop on campus):
├─ lib/services/community_sensing_service.dart → _performBleScan()
├─ Detected: AG-001, RSSI: -72 dBm
├─ lib/services/community_detection_service.dart → reportDetection()
├─ POST http://backend:5000/api/community/detections
├─ backend/src/controllers/communityController.js → submitCommunityDetection()
│   ├─ Find asset: Asset.findOne({trackerId: "AG-001"})
│   └─ ⭐ CRITICAL CHECK:
│       if (asset.status !== 'LOST') {
│         // status is 'RECOVERED', not 'LOST'
│         return res.status(404).json({ message: 'Asset not found' });
│       }
└─ Backend returns 404 to User B

Flutter (User B):
├─ Receives 404 error
└─ Logs: "[Community] ℹ Tracker AG-001 rejected — might be owned by current user"

Result:
├─ NO CommunityDetection record created
├─ NO Notification created
└─ Alice does NOT receive notification (as expected!)

System correctly prevents spam after recovery! ✅

═══════════════════════════════════════════════════════════
END OF COMPLETE WORKFLOW
═══════════════════════════════════════════════════════════
```

---

## PART 22: FILE DEPENDENCY MAP

```
┌─────────────────────────────────────────────────────────┐
│ ANDROID DEVICE                                           │
└─────────────────────────────────────────────────────────┘
                      │
                      │ User launches app
                      ↓
          ┌───────────────────────┐
          │ lib/main.dart         │ Entry point
          └───────────┬───────────┘
                      │
                      ↓
          ┌───────────────────────┐
          │ lib/screens/          │ UI Layer
          │ splash_screen.dart    │
          │ login_screen.dart     │
          │ home_screen.dart      │
          │ my_assets_screen.dart │
          │ asset_details_screen.dart │
          │ track_asset_screen.dart │
          │ notifications_screen.dart │
          └───────────┬───────────┘
                      │
                      │ Calls
                      ↓
          ┌───────────────────────┐
          │ lib/services/         │ Business Logic Layer
          │ auth_service.dart     │
          │ asset_service.dart    │
          │ notification_service.dart │
          │ community_sensing_service.dart │
          │ ble_service.dart      │
          │ wifi_scan_service.dart │
          │ community_detection_service.dart │
          └───────────┬───────────┘
                      │
                      │ Calls
                      ↓
          ┌───────────────────────┐
          │ lib/services/         │ Network Layer
          │ api_service.dart      │
          └───────────┬───────────┘
                      │
                      │ HTTP Requests
                      ↓
        ┌─────────────────────────────────┐
        │ Network: HTTP/HTTPS              │
        └─────────┬───────────────────────┘
                  │
                  ↓
    ┌─────────────────────────────────────┐
    │ backend/server.js                    │ Entry Point
    └─────────────┬───────────────────────┘
                  │
                  ↓
    ┌─────────────────────────────────────┐
    │ backend/src/app.js                   │ Express Config
    └─────────────┬───────────────────────┘
                  │
                  ├─→ backend/src/routes/*.js     [Route Definitions]
                  │       ├─→ authRoutes.js
                  │       ├─→ assetRoutes.js
                  │       ├─→ communityRoutes.js
                  │       ├─→ notificationRoutes.js
                  │       └─→ dashboardRoutes.js
                  │
                  ├─→ backend/src/middleware/
                  │       ├─→ auth.js              [JWT Verification]
                  │       └─→ validate.js          [Input Validation]
                  │
                  ↓
    ┌─────────────────────────────────────┐
    │ backend/src/controllers/*.js         │ Business Logic
    │ authController.js                    │
    │ assetController.js                   │
    │ communityController.js ⭐            │ [ML Integration]
    │ notificationController.js            │
    │ dashboardController.js               │
    └─────────────┬───────────────────────┘
                  │
                  ├─→ backend/src/models/*.js     [MongoDB Schemas]
                  │       ├─→ User.js
                  │       ├─→ Asset.js
                  │       ├─→ CommunityDetection.js
                  │       ├─→ Notification.js
                  │       └─→ CommunityFingerprint.js
                  │
                  ├─→ MongoDB Database
                  │       └─→ assetguard_db
                  │           ├─→ users collection
                  │           ├─→ assets collection
                  │           ├─→ communitydetections collection
                  │           ├─→ notifications collection
                  │           └─→ communityfingerprints collection
                  │
                  └─→ HTTP Request to ML Server
                          ↓
        ┌─────────────────────────────────────┐
        │ Python ML Server (Separate Project)  │
        │ http://10.135.90.221:8000            │
        │                                      │
        │ POST /predict-room                   │
        │ Input: Wi-Fi fingerprint             │
        │ Output: Room + Confidence            │
        │ Model: Random Forest (97.96%)        │
        └─────────────────────────────────────┘
```

---

## PART 23: VIVA QUESTIONS & ANSWERS

### Architecture & Design (Q1-Q5)

**Q1: Why did you choose Flutter instead of native Android/iOS development?**

**A**: We chose Flutter for several reasons:
1. **Single codebase**: Write once, deploy on both Android and iOS, reducing development time by ~50%
2. **Hot reload**: Instant UI updates during development, faster iteration
3. **Performance**: Compiles to native code, not a WebView wrapper
4. **Rich UI**: Material Design widgets built-in, beautiful UI without extra effort
5. **Community**: Large ecosystem, packages for BLE, Wi-Fi, maps available
6. **Learning**: Team already familiar with Dart/Flutter from previous projects

Trade-off: Slightly larger APK size (~20MB) compared to pure native, but acceptable for our use case.

---

**Q2: Why Node.js for the backend instead of Python, Java, or .NET?**

**A**: Node.js was chosen because:
1. **JavaScript full-stack**: Same language as Flutter's Dart syntax (similar), easier team coordination
2. **Async/await**: Perfect for I/O-heavy operations (database queries, HTTP requests to ML server)
3. **Fast development**: Express.js is minimalist, quick to build REST APIs
4. **JSON-native**: JavaScript handles JSON naturally (same format as MongoDB and API responses)
5. **npm ecosystem**: Large package repository (bcrypt, jsonwebtoken, mongoose readily available)

Why not Python: Python is better for ML, but our ML server is separate. Node.js is faster for API servers.

---

**Q3: Why MongoDB instead of MySQL or PostgreSQL?**

**A**: MongoDB advantages for this project:
1. **Flexible schema**: Easy to add new fields (like `predictedRoom`, `roomConfidence`) without migrations
2. **JSON documents**: Perfect match for JavaScript objects and API responses
3. **Nested data**: Can embed arrays (Wi-Fi fingerprints) directly in documents
4. **Geospatial queries**: Built-in support for latitude/longitude queries (future feature)
5. **Horizontal scaling**: Can shard across multiple servers if user base grows

When SQL is better: If we needed complex joins or strict referential integrity. But our data model is relatively simple (users → assets → detections).

---

**Q4: Why separate the ML server from the main backend?**

**A**: Several reasons for separation:
1. **Different tech stacks**: Python (scikit-learn) for ML, Node.js for API - each excels at its purpose
2. **Independent scaling**: ML server can scale separately if prediction load increases
3. **Security isolation**: ML server doesn't need database access, reducing attack surface
4. **Independent deployment**: Can update ML model without touching backend API
5. **Modularity**: ML server could be replaced with different implementation without affecting backend

Communication via HTTP REST API keeps them loosely coupled.

---

**Q5: Explain the complete three-tier architecture.**

**A**: AssetGuard uses a three-tier architecture:

**Tier 1: Presentation Layer (Flutter App)**
- Runs on user's Android phone
- Handles UI, user input, local data (SharedPreferences for JWT)
- Makes HTTP requests to backend
- Performs BLE/Wi-Fi scanning via platform channels

**Tier 2: Application Layer (Node.js Backend + Python ML Server)**
- Node.js handles business logic:
  - User authentication (JWT)
  - Asset management (CRUD)
  - Community detection processing
  - Notification creation
- Python ML server handles prediction:
  - Receives Wi-Fi fingerprint
  - Returns room number + confidence
  - No database access, prediction only

**Tier 3: Data Layer (MongoDB)**
- Persistent storage for:
  - User accounts
  - Assets
  - Community detections
  - Notifications
- Handles queries from backend
- Provides indexing for fast lookups

**Data Flow**: Flutter → Node.js → MongoDB (for data) + Python ML (for predictions) → Node.js → Flutter

---

### Bluetooth Questions (Q6-Q10)

**Q6: Why BLE (Bluetooth Low Energy) instead of classic Bluetooth?**

**A**: BLE is specifically designed for IoT applications like ours:
1. **Power efficiency**: BLE uses 1/100th the power of classic Bluetooth. A tracker can run for 6-12 months on a coin battery
2. **Always-on advertising**: BLE devices can broadcast their presence continuously without draining battery
3. **No pairing required**: Phones can scan for BLE devices without user interaction or pairing
4. **Ubiquitous support**: Every modern smartphone (Android 4.3+, iOS 7+) supports BLE
5. **Optimized for proximity**: BLE range (10-50m) is perfect for indoor room-level detection

Classic Bluetooth would require pairing and drain the tracker battery in days.

---

**Q7: What is RSSI and how does it indicate proximity?**

**A**: RSSI = Received Signal Strength Indicator

**Technical**:
- Measured in dBm (decibels relative to 1 milliwatt)
- Range: -120 dBm (extremely weak) to 0 dBm (maximum signal)
- Logarithmic scale: -40 dBm is 10x stronger than -50 dBm

**Proximity relationship**:
- **-20 to -40 dBm**: Very close (< 1 meter) - tracker is right next to phone
- **-40 to -70 dBm**: Medium distance (1-10 meters) - same room or nearby
- **-70 to -90 dBm**: Far (10-30 meters) - different room or building sections
- **Below -90 dBm**: Very far or blocked by walls

**Use in AssetGuard**:
- We display RSSI in notifications ("Signal: -67 dBm")
- Helps user estimate proximity: lower number (closer to 0) = closer
- Not used for room prediction (Wi-Fi fingerprinting is more accurate)

**Why not use RSSI alone?**: RSSI fluctuates due to obstacles, interference, phone orientation. Wi-Fi fingerprinting with 74+ BSSIDs gives much more stable location signature.

---

**Q8: Why scan for 8 seconds every 15 seconds?**

**A**: This is a carefully balanced configuration:

**8-second scan duration**:
- **Minimum**: BLE devices advertise every 1-2 seconds. Need multiple advertising packets to reliably detect
- **Too short (2-3s)**: Might miss devices that happen to advertise right after scan ends
- **Too long (15s+)**: Battery drain, no benefit (all devices already discovered)
- **8 seconds**: Sweet spot - catches multiple advertisement cycles, ensures detection

**15-second interval**:
- **Too frequent (5s)**: Excessive battery drain, CPU usage
- **Too infrequent (60s+)**: Misses fast-moving people, delayed detections
- **15 seconds**: Balance between responsiveness and battery life
- User walking at 1 m/s covers 15 meters in 15 seconds (reasonable detection window)

**Real-world measurement**: On test phone, battery drain is ~10-15% over 8 hours with Community Sensing enabled. Acceptable trade-off.

---

**Q9: Explain the 60-second debounce logic and why it's necessary.**

**A**: Debounce prevents duplicate notifications for the same tracker.

**Problem without debounce**:
```
15:00:00 - User B detects AG-001 → Notification sent to User A
15:00:15 - User B still detects AG-001 → Notification sent again
15:00:30 - User B still detects AG-001 → Notification sent again
... (User A gets 240 notifications per hour!)
```

**Solution with 60s debounce**:
```
15:00:00 - User B detects AG-001 → Report to backend ✓, Mark timestamp
15:00:15 - User B detects AG-001 → Skip (< 60s elapsed) ✗
15:00:30 - User B detects AG-001 → Skip (< 60s elapsed) ✗
15:00:45 - User B detects AG-001 → Skip (< 60s elapsed) ✗
15:01:05 - User B detects AG-001 → Report to backend ✓ (> 60s elapsed)
```

**Why 60 seconds?**:
- **Too short (15s)**: Still get multiple notifications per minute
- **Too long (300s)**: Miss when asset moves to different room
- **60 seconds**: User gets updated location every minute if asset is moving, not overwhelming

**Implementation**: In-memory map `{trackerId: lastReportedTime}` in `CommunityDetectionService`

---

**Q10: Why does BLE scanning require location permission on Android?**

**A**: This is an Android security/privacy requirement, not our choice.

**Reason**: Bluetooth beacons can be used for location tracking
- Stores, malls use BLE beacons for indoor positioning
- App could determine your location by scanning nearby BLE beacons (even without GPS)
- Android treats this as location data

**Android's logic**:
- Android 5.0+: BLE scanning requires `ACCESS_COARSE_LOCATION`
- Android 10+: Requires `ACCESS_FINE_LOCATION`
- Android 12+: Introduced `BLUETOOTH_SCAN` permission (but still often needs location)

**Why AssetGuard truly needs it**:
- We're literally doing proximity detection (finding lost items nearby)
- We also use GPS to include detection location in notifications
- So we legitimately need location permission anyway

**Transparency**: We show clear rationale dialog explaining why permission is needed before requesting it.

---


### Wi-Fi Questions (Q11-Q15)

**Q11: What is Wi-Fi fingerprinting and how does it work?**

**A**: Wi-Fi fingerprinting is a technique for indoor localization using the unique pattern of Wi-Fi signals at each location.

**Concept**:
- Every location "sees" a different set of Wi-Fi access points
- Each AP has different signal strength from different positions
- This creates a unique "signature" or "fingerprint" for each room

**Example**:
```
Room 310 fingerprint:
- AP1 (84:d8:1b:aa:bb:cc): -43 dBm (nearby)
- AP2 (84:d8:1b:11:22:33): -67 dBm (medium)
- AP3 (84:d8:1b:44:55:66): -89 dBm (far)

Room 312 fingerprint:
- AP1: -89 dBm (far now)
- AP2: -55 dBm (closer)
- AP4: -42 dBm (new nearby AP)
```

**How it works**:
1. **Training phase**: Collect fingerprints from known rooms
2. **ML training**: Model learns patterns (which BSSID combinations = which room)
3. **Prediction phase**: New fingerprint → Model predicts room

**Advantages over GPS**:
- GPS doesn't work indoors (no satellite signal)
- Wi-Fi achieves room-level accuracy (3-5 meters)
- Uses existing infrastructure (no new hardware needed)

---

**Q12: What is BSSID and why is it more useful than SSID?**

**A**: BSSID vs SSID comparison:

**SSID** (Service Set Identifier):
- Network name that users see (e.g., "NIE-STUDENTS")
- Same SSID across many access points on campus
- Cannot distinguish between individual APs
- Not useful for location determination

**BSSID** (Basic Service Set Identifier):
- MAC address of specific access point hardware
- Format: 6 hex bytes (e.g., "84:d8:1b:aa:bb:cc")
- Globally unique identifier for each AP
- Each AP has different BSSID even with same SSID

**Why BSSID for fingerprinting**:
```
Imagine campus has 100 APs, all broadcasting "NIE-STUDENTS"

Using SSID only:
Room 310: Sees "NIE-STUDENTS" at -50 dBm
Room 312: Sees "NIE-STUDENTS" at -50 dBm
→ Cannot distinguish! (same SSID, similar signal)

Using BSSID:
Room 310:
  - BSSID 84:d8:1b:aa:bb:cc: -43 dBm (AP#1, nearby)
  - BSSID 84:d8:1b:11:22:33: -67 dBm (AP#5, far)

Room 312:
  - BSSID 84:d8:1b:aa:bb:cc: -78 dBm (AP#1, far)
  - BSSID 84:d8:1b:77:88:99: -45 dBm (AP#8, nearby)
→ Can distinguish! (different BSSID patterns)
```

**AssetGuard usage**: Our ML model uses 106 BSSID features (not SSIDs)

---

**Q13: Why filter only NIE-STUDENTS and NIE-STAFF networks?**

**A**: Filtering is essential for consistent and accurate fingerprinting:

**Campus infrastructure**:
- NIE-STUDENTS and NIE-STAFF are official campus Wi-Fi networks
- Managed by campus IT, stable and consistent
- APs are fixed locations (don't move)
- Sufficient coverage across all buildings

**What we filter out**:
1. **Personal hotspots**: "John's iPhone", "Samsung Galaxy" - these move with people
2. **Neighboring buildings**: Residential Wi-Fi from nearby apartments
3. **Mobile Wi-Fi**: Buses, cars passing by
4. **Temporary networks**: Event/conference networks

**Without filtering**:
```
Room 310 scan at 10 AM:
- NIE-STUDENTS APs (stable) ✓
- "John's iPhone" hotspot (John is in room) ✗

Room 310 scan at 2 PM:
- NIE-STUDENTS APs (same as morning) ✓
- "Mary's Hotspot" (different person) ✗

ML model gets confused - fingerprint changed even though location same!
```

**With filtering**:
```
Both scans show only NIE-STUDENTS APs → Consistent fingerprint → Accurate prediction
```

**Implementation**: `wifi_scan_service.dart` filters by SSID: `ssid == 'NIE-STUDENTS' || ssid == 'NIE-STAFF'`

---

**Q14: Why cache Wi-Fi fingerprints for 2 minutes?**

**A**: The cache solves a timing problem:

**The problem**: BLE and Wi-Fi scans are independent
```
10:00:00 - Wi-Fi scan (takes 2 seconds)
10:00:02 - Wi-Fi complete, but not synchronized with BLE
10:00:08 - BLE scan completes, finds AG-001
10:00:08 - Need Wi-Fi data NOW for detection
```

**Without cache**:
- BLE scan can't wait for Wi-Fi scan (would block detection)
- Could trigger Wi-Fi scan synchronously (adds 2s delay to every detection)
- Or submit detection without Wi-Fi (no room prediction)

**With 2-minute cache**:
```
10:00:02 - Wi-Fi scan complete → Cache fingerprint (valid until 10:02:02)
10:00:08 - BLE detects AG-001 → Check cache → Found! (6 seconds old)
10:00:15 - Another BLE detection → Check cache → Still valid! (13 seconds old)
10:01:00 - BLE detection → Check cache → Still valid! (58 seconds old)
10:02:15 - Wi-Fi scan → Cache refreshed (valid until 10:04:15)
```

**Why 2 minutes?**:
- **Too short (30s)**: Cache often expired when BLE detects something
- **Too long (10 min)**: User could move to different room, stale data
- **2 minutes**: Wi-Fi APs don't move, user likely in same area, balance

**Technical**: `lib/services/wifi_fingerprint_cache.dart` stores timestamp, checks age on retrieval

---

**Q15: What happens if Wi-Fi fingerprint is unavailable?**

**A**: System uses graceful degradation:

**Scenario 1: Wi-Fi scan fails**
```
Wi-Fi disabled on phone / Permission denied / No NIE networks nearby
→ Cache empty
→ BLE detects AG-001
→ Check cache: null
→ Submit detection WITHOUT wifiFingerprint field
→ Backend receives detection (no Wi-Fi)
→ Backend skips ML call (no fingerprint to send)
→ Notification created with GPS only: "Detected at 1.3521, 103.8198"
```

**Scenario 2: ML server is down**
```
Wi-Fi scan succeeds, fingerprint included
→ Backend calls ML server
→ ML server timeout (10 seconds) / Connection error
→ Catch error, log it
→ predictedRoom = null
→ Notification created with GPS: "Detected at 1.3521, 103.8198"
```

**Scenario 3: No GPS either**
```
Wi-Fi failed, GPS permission denied
→ Basic notification: "Your Laptop (AG-001) was detected nearby."
```

**Key principle**: Detection **never fails** due to missing Wi-Fi/ML
- Detection record always saved
- Notification always sent
- Room prediction is a nice-to-have feature, not critical

**Code**: `backend/src/controllers/communityController.js` wraps ML call in try-catch, continues on error

---

### Machine Learning Questions (Q16-Q20)

**Q16: Why Random Forest classifier instead of neural networks?**

**A**: Random Forest is better suited for this specific problem:

**Random Forest advantages**:
1. **Handles missing features naturally**: Not all 106 BSSIDs visible from every location, Random Forest handles sparse data well
2. **No feature scaling needed**: RSSI values are already in similar range (-120 to 0 dBm)
3. **Fast training**: Hours vs days for neural networks
4. **Fast prediction**: <100ms per prediction (important for real-time system)
5. **Interpretable**: Can see which BSSIDs are most important for predictions
6. **Robust to outliers**: Wi-Fi RSSI can fluctuate, Random Forest is stable
7. **Small model size**: ~50MB vs GB for neural networks
8. **High accuracy**: 97.96% on our dataset (diminishing returns with more complex models)

**When neural networks might be better**:
- Much larger dataset (we have ~200-400 samples)
- More complex patterns (our problem is relatively straightforward: BSSID patterns → room)
- Need transfer learning from pre-trained models

**Decision**: Occam's Razor - simpler model that works is better than complex model with minimal improvement

---

**Q17: Why 106 BSSID features specifically?**

**A**: 106 is the result of feature selection:

**Process**:
1. **Collected all BSSIDs**: During training data collection, found ~200+ unique BSSIDs across campus
2. **Frequency analysis**: Counted how often each BSSID appears across all training samples
3. **Selected top 106**: Most frequently appearing BSSIDs (appeared in at least 30% of samples)

**Why not all BSSIDs (~200)?**:
- Many BSSIDs appear rarely (mobile hotspots, temporary networks)
- Rare BSSIDs add noise, don't improve accuracy
- More features = larger model, slower prediction
- Overfitting risk

**Why not fewer (e.g., top 20)?**:
- Losing important spatial information
- Tested: 20 features = 85% accuracy, 50 features = 92%, 106 features = 97.96%
- Diminishing returns after 106

**Feature vector structure**:
```python
# For a given location
feature_vector = [
  rssi_for_bssid_1,   # -43 if visible, -100 if not
  rssi_for_bssid_2,   # -67
  rssi_for_bssid_3,   # -100 (not visible)
  ...
  rssi_for_bssid_106  # -55
]
```

**-100 dBm for missing BSSIDs**: Indicates "not visible" (weaker than weakest possible signal)

---

**Q18: How many training samples and from how many rooms?**

**A**: Training dataset details:

**Rooms**: 22 rooms on NIE campus
- Classrooms, labs, corridors
- Distributed across multiple floors/buildings
- Chosen to cover different areas where assets might be lost

**Samples per room**: ~10-20 fingerprints per room
- Total: ~200-400 training samples
- Collected at different times of day (Wi-Fi load varies)
- Different positions within each room (corners, center, near door)

**Why multiple samples per room?**:
- Wi-Fi RSSI fluctuates (±5 dBm normally)
- People moving affects signals
- Model learns robust patterns, not noise

**Data collection process**:
1. Walk to Room 310
2. Open app, tap "Scan Wi-Fi"
3. Record fingerprint + label "310"
4. Move to different spot in room, repeat
5. Repeat for all 22 rooms

**Training**:
- 80/20 train/test split
- 10-fold cross-validation
- Random Forest: 100 trees, max depth 20

**Result**: 97.96% accuracy on test set (unseen samples)

---

**Q19: What does 97.96% accuracy mean in practice?**

**A**: Accuracy interpretation:

**Definition**:
- Out of 100 predictions, 97-98 are correct room numbers
- Only 2-3 are wrong

**Confusion matrix (simplified)**:
```
Actual Room 310 → Predicted:
  - Room 310: 95% (correct)
  - Room 312: 3% (adjacent room, close!)
  - Room 308: 1% (nearby)
  - Room 510: 1% (different floor)
```

**What this means for users**:
- Most of the time: "Your Laptop detected in Room 310" → It's actually in 310 ✓
- Rarely: "Detected in Room 312" → Actually in 310 (but 312 is next door) ≈

**Error types**:
1. **Adjacent rooms** (most common errors): ML sometimes confuses neighboring rooms (similar Wi-Fi patterns)
2. **Same floor**: Rarely predicts wrong room on same floor
3. **Wrong floor**: Very rare (different floors have very different AP visibility)

**User impact**: Even with 3% error, user still gets useful information (correct floor, correct building, often correct or adjacent room)

**Confidence score helps**:
- High confidence (>70%): Very likely correct
- Medium confidence (40-70%): Probably correct, but check nearby rooms
- Low confidence (<40%): Uncertain, use GPS as backup

**Example**: "Detected in Room 310 (38% confidence)" means "Most likely 310, but could be nearby room, check the area"

---

**Q20: Why is the ML server separate from the backend?**

**A**: Architectural decision with multiple benefits:

**1. Technology stack separation**:
- **ML Server**: Python (scikit-learn, numpy, pandas) - Best for ML/data science
- **Backend**: Node.js (Express) - Best for REST APIs, async I/O
- Each uses best tool for its job

**2. Independent scaling**:
- If prediction load increases → Scale ML server independently
- Can run multiple ML server instances behind load balancer
- Backend scaling needs are different (handles auth, CRUD operations)

**3. Security isolation**:
- ML server doesn't need:
  - Database access (no user data, asset data)
  - JWT verification (Backend pre-validates)
  - User authentication logic
- Reduced attack surface

**4. Independent deployment**:
- Update ML model without redeploying backend
- Retrain model with new rooms → Just restart ML server
- Backend API remains stable

**5. Fault isolation**:
- If ML server crashes → Backend continues working (degrades to GPS-only)
- If backend crashes → ML server unaffected
- No cascading failures

**6. Testability**:
- Can test ML server independently (curl POST /predict-room)
- Can mock ML server in backend tests
- Clear contract (HTTP API)

**Communication**: Simple HTTP REST API
```
Backend → POST /predict-room {wifi: {...}}
ML Server → {room: "310", confidence: 0.38}
```

**Trade-off**: Extra network hop (~10-50ms), but negligible compared to benefits

---

### Community Sensing Questions (Q21-Q25)

**Q21: How does Community Sensing benefit both users?**

**A**: Mutual benefit system:

**For User A (Asset Owner)**:
- Someone finds their lost asset without User A having to be there
- Gets notification with location (room number)
- Can recover asset faster
- "Crowdsourced" search - multiple people helping passively

**For User B (Community Member)**:
- Helps others (altruistic)
- Passive help - phone does it automatically, no effort
- Might receive help in return when they lose something
- Builds community trust

**Network Effect**:
- More users with Community Sensing = faster detection
- If 50% of students enable it → Lost asset detected within minutes as people walk by
- Creates incentive to participate (help others to be helped)

**Privacy preserved**:
- User A never knows who detected their asset (User B identity hidden)
- User B never knows whose asset they detected (sees only tracker ID "AG-001")
- Both parties anonymous to each other

**Analogy**: Like neighborhood watch, but automatic and digital

---

**Q22: Why does foreground service require persistent notification?**

**A**: This is an Android OS requirement, not our choice.

**Android's reasoning**:
- Background apps could abuse location/BLE access (stalking, surveillance)
- Users must be aware when apps access sensitive sensors
- Persistent notification ensures transparency

**Requirement** (Android 8.0+):
- Foreground services MUST show visible notification
- Notification cannot be dismissed by user (swipe doesn't remove it)
- Only stopping the service removes notification

**Our implementation**:
```
Notification shows:
- Title: "AssetGuard Community Sensing"
- Text: "Community sensing active — BLE: 5, Wi-Fi: 5, 2 detections"
- Icon: AssetGuard logo
- Tap to open app
```

**Benefits**:
1. **Transparency**: User always knows service is running
2. **Control**: User can stop service (tap notification → profile → disable)
3. **Status**: Shows scan counts (user sees it's working)

**Why users accept it**:
- Explicit opt-in (not default)
- Clear value proposition (help others, get helped)
- Can disable anytime

**Alternative** (if Android didn't require): Could use background service with no notification, but that's exactly what Android wants to prevent (hidden tracking)

---

**Q23: How do you prevent User A from reporting their own asset?**

**A**: Backend security check:

**Code** (`backend/src/controllers/communityController.js`, line ~145):
```javascript
// SECURITY: Prevent owner from reporting their own asset
if (asset.userId._id.toString() === req.user._id.toString()) {
  console.log('[Community] ✗ Owner attempting to report own asset');
  return error(res, 'Asset not found', 404);
}
```

**Why this check?**:
- Prevent self-spam: User A could repeatedly "detect" their own asset to inflate detection count
- Abuse prevention: Could game the system
- Conceptual: Community sensing is for *others* to help, not self-reporting

**Why return 404 instead of 403?**:
- 404 "Asset not found" same as "Asset not LOST" or "Asset doesn't exist"
- Don't reveal to potential attacker: "This asset exists but you can't report it"
- Security through obscurity (minor)

**How check works**:
1. Detection received from User B (identified by JWT)
2. Look up asset by tracker ID
3. Asset owner is User A (asset.userId)
4. Compare: User B._id === User A._id?
5. If match → Reject (owner trying to report own asset)
6. If no match → Continue (legitimate community detection)

**Edge case**: User could create second account to report own asset, but requires effort and provides no real benefit

---

**Q24: Explain the complete notification delivery mechanism.**

**A**: Notification flow (currently polling-based):

**Backend creates notification** (when detection happens):
```javascript
const notification = await Notification.create({
  recipient: asset.userId._id,  // User A
  type: 'asset_detected',
  message: "Your Laptop (AG-001) was detected near Room 310. (38% confidence)",
  predictedRoom: "310",
  roomConfidence: 0.376667,
  read: false,
  // ... other fields
});
// Saved to MongoDB notifications collection
```

**Flutter retrieves notifications** (polling):

**Method 1: Unread count polling** (every 30 seconds if app open):
```dart
// home_screen.dart
Timer.periodic(Duration(seconds: 30), (_) {
  final count = await NotificationService.instance.getUnreadCount();
  // GET /api/notifications/unread/count
  // Updates badge on bell icon
});
```

**Method 2: User opens Notifications screen**:
```dart
// notifications_screen.dart
@override
void initState() {
  _loadNotifications();
  // GET /api/notifications
  // Fetches all notifications, displays list
}
```

**Method 3: Pull-to-refresh**:
```dart
RefreshIndicator(
  onRefresh: _loadNotifications,
  // User swipes down to manually refresh
)
```

**Limitations of polling**:
- Delay: Up to 30 seconds before user sees new notification (if app open)
- If app closed: No notification until user opens app
- Battery: Periodic API calls drain battery (though minimal)

**Better alternative (not implemented)**:
- **Firebase Cloud Messaging (FCM)**: Push notifications instantly when created
- **WebSocket**: Real-time bidirectional connection
- **Server-Sent Events (SSE)**: Server pushes updates to client

**Why polling for now**: Simpler implementation, good enough for MVP, works offline (cached data)

---

**Q25: What prevents spam after marking asset as RECOVERED?**

**A**: Critical status check in backend:

**The check** (`backend/src/controllers/communityController.js`, line ~141):
```javascript
// CRITICAL: Only accept detections for LOST assets
if (asset.status !== 'LOST') {
  console.log('[Community] Detection ignored — asset', trackerId, 'is', asset.status);
  return error(res, 'Asset not found', 404);
}
```

**Status lifecycle**:
```
ACTIVE → (user marks as lost) → LOST → (user marks as recovered) → RECOVERED
         ↓                      ↓                                   ↓
      No notifications    Notifications generated            No notifications
```

**Scenario without check**:
```
1. User A marks Laptop as RECOVERED
2. User A carries Laptop to campus next day
3. User B's phone detects AG-001 → Reports to backend
4. Backend creates notification → User A receives
5. User A confused: "I already have my Laptop! Why notification?"
6. Spam continues every time someone near User A
```

**Scenario with check**:
```
1. User A marks Laptop as RECOVERED
2. Backend updates: asset.status = 'RECOVERED'
3. User A carries Laptop to campus next day
4. User B's phone detects AG-001 → Reports to backend
5. Backend checks: asset.status === 'LOST'? NO (status is 'RECOVERED')
6. Backend returns 404 → Detection rejected
7. NO notification created
8. User A has peace of mind
```

**Why 404 response?**:
- Security: Don't reveal "Asset exists but is RECOVERED" to potential attacker
- Consistency: Same response as "Asset doesn't exist" or "Asset is ACTIVE"
- Flutter logs: "Tracker not LOST or not found — this is normal"

**Implementation**:
- Status stored in MongoDB: `assets.status` field
- Enum: ['ACTIVE', 'LOST', 'RECOVERED']
- Enforced by Mongoose schema validation
- Check happens early in detection flow (before ML, before notification)

**This is THE most critical check in the entire system** - without it, users would hate the app (constant spam)

---

### Technical Implementation Questions (Q26-Q30)

**Q26: How does JWT authentication work in your system?**

**A**: Complete JWT flow:

**1. Login** (JWT generation):
```javascript
// backend/src/controllers/authController.js
const login = async (req, res) => {
  // Verify email/password
  const user = await User.findOne({ email });
  const isMatch = await bcrypt.compare(password, user.password);
  
  if (!isMatch) return error(res, 'Invalid credentials', 401);
  
  // Generate JWT
  const token = jwt.sign(
    { userId: user._id },           // Payload (user identifier)
    process.env.JWT_SECRET,          // Secret key (server-side only)
    { expiresIn: '7d' }              // Expiration (7 days)
  );
  
  res.json({ token, user: { _id, name, email } });
};
```

**JWT structure** (3 parts, dot-separated):
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NzUuLi4iLCJpYXQiOjE3MzM5NTY4MDAsImV4cCI6MTczNDU2MTYwMH0.signature_hash

Part 1 (Header):     {"alg": "HS256", "typ": "JWT"}
Part 2 (Payload):    {"userId": "675...", "iat": 1733956800, "exp": 1734561600}
Part 3 (Signature):  HMACSHA256(base64(header) + base64(payload), SECRET)
```

**2. Flutter stores token**:
```dart
// lib/services/auth_service.dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token);  // Persistent storage

ApiService.instance.setToken(token);         // In-memory for current session
```

**3. Every API request** (Flutter includes token):
```dart
// lib/services/api_service.dart
Map<String, String> get _headers => {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',  // ← Automatically added
};

final response = await http.post(url, headers: _headers, body: body);
```

**4. Backend verifies token**:
```javascript
// backend/src/middleware/auth.js
const protect = async (req, res, next) => {
  // Extract token
  const token = req.headers.authorization?.split(' ')[1];  // "Bearer TOKEN"
  
  if (!token) return res.status(401).json({ message: 'No token' });
  
  try {
    // Verify signature and expiration
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    // decoded = {userId: "675...", iat: 1733956800, exp: 1734561600}
    
    // Get user from database
    req.user = await User.findById(decoded.userId);
    
    if (!req.user) return res.status(401).json({ message: 'User not found' });
    
    next();  // Token valid, proceed to controller
  } catch (err) {
    return res.status(401).json({ message: 'Invalid token' });
  }
};
```

**Security features**:
- **Signature**: Prevents tampering (changing userId in payload would break signature)
- **Expiration**: Token invalid after 7 days (user must re-login)
- **Server-side secret**: Only backend can generate valid tokens
- **Stateless**: Backend doesn't store session data, scales horizontally

**Why JWT over sessions**:
- No server-side session storage needed (scales better)
- Works across multiple backend servers (no session sharing needed)
- Mobile-friendly (token stored in SharedPreferences, persists across app restarts)

---

**Q27: Explain the asset ownership verification mechanism.**

**A**: Ownership verification ensures users can only access their own assets:

**Every asset operation checks ownership**:

**Example: Get single asset**:
```javascript
// backend/src/controllers/assetController.js
const getAsset = async (req, res) => {
  // Find asset by ID AND verify ownership
  const asset = await Asset.findOne({
    _id: req.params.id,
    userId: req.user._id,  // ← Ownership check!
  });
  
  if (!asset) {
    // Asset doesn't exist OR doesn't belong to user
    return res.status(404).json({ message: 'Asset not found' });
  }
  
  // Asset found and belongs to authenticated user
  res.json({ asset });
};
```

**Example: Update asset**:
```javascript
const updateAsset = async (req, res) => {
  // Find + verify ownership in one query
  const asset = await Asset.findOneAndUpdate(
    {
      _id: req.params.id,
      userId: req.user._id,  // ← Only update if owner
    },
    { name: req.body.name, category: req.body.category },
    { new: true }
  );
  
  if (!asset) return res.status(404).json({ message: 'Asset not found' });
  
  res.json({ asset });
};
```

**Example: Delete asset**:
```javascript
const deleteAsset = async (req, res) => {
  const asset = await Asset.findOneAndDelete({
    _id: req.params.id,
    userId: req.user._id,  // ← Only delete if owner
  });
  
  if (!asset) return res.status(404).json({ message: 'Asset not found' });
  
  res.json({ message: 'Asset deleted' });
};
```

**How it works**:
1. **JWT contains user ID**: Token payload has `{userId: "675..."}`
2. **Middleware extracts user**: `req.user` = authenticated user object
3. **Query filters by user**: `userId: req.user._id` in MongoDB query
4. **MongoDB returns**: Only assets WHERE userId matches

**Attack scenario prevented**:
```
Attacker (User B) tries to access User A's asset:
1. User B gets their own JWT (contains User B's ID)
2. User B calls: GET /api/assets/[User A's asset ID]
3. Middleware: req.user = User B
4. Query: Asset.findOne({ _id: A's asset, userId: User B })
5. MongoDB: No match (A's asset has userId = User A, not User B)
6. Returns 404 "Asset not found"
7. User B cannot access User A's asset ✓
```

**Why 404 instead of 403**:
- 404: "Asset not found" (could be non-existent or not owned)
- 403: "Forbidden" (reveals asset exists but access denied)
- Security through obscurity: Don't reveal which assets exist

**Database-level enforcement**:
- Every asset has `userId` field (required)
- Every query includes `userId: req.user._id`
- No way to bypass in application code

---

**Q28: What are the main MongoDB collections and their relationships?**

**A**: Five main collections with clear relationships:

**1. users** (account data):
```javascript
{
  _id: ObjectId("675..."),
  name: "Alice",
  email: "alice@example.com",
  password: "$2a$10$..." // hashed
}
```

**2. assets** (belongings):
```javascript
{
  _id: ObjectId("675..."),
  name: "Laptop",
  trackerId: "AG-001",
  status: "LOST",
  userId: ObjectId("675...") → references users._id
}
```

**3. communitydetections** (detection records):
```javascript
{
  _id: ObjectId("675..."),
  trackerId: "AG-001",
  assetId: ObjectId("675...") → references assets._id,
  detectedBy: ObjectId("675...") → references users._id (User B),
  rssi: -67,
  latitude: 1.3521,
  longitude: 103.8198,
  predictedRoom: "310",
  roomConfidence: 0.376667,
  detectedAt: ISODate("...")
}
```

**4. notifications** (messages to owners):
```javascript
{
  _id: ObjectId("675..."),
  recipient: ObjectId("675...") → references users._id (User A),
  type: "asset_detected",
  message: "Your Laptop detected...",
  assetId: ObjectId("675...") → references assets._id,
  detectionId: ObjectId("675...") → references communitydetections._id,
  predictedRoom: "310",
  roomConfidence: 0.376667,
  read: false
}
```

**5. communityfingerprints** (historical Wi-Fi data):
```javascript
{
  _id: ObjectId("675..."),
  scannedBy: ObjectId("675...") → references users._id,
  wifiFingerprint: [
    {bssid: "84:d8:1b:aa:bb:cc", rssi: -43},
    // ... more
  ],
  timestamp: ISODate("...")
}
```

**Relationship diagram**:
```
users (Alice)
  ├─→ assets (Laptop, AG-001, LOST)
  │     ├─→ communitydetections (User B detected it)
  │     │     └─→ notifications (Tell Alice)
  │     └─→ notifications (One notification per detection)
  │
  └─→ communityfingerprints (Alice's Wi-Fi scans)

users (Bob)
  ├─→ communitydetections (Bob detected something)
  └─→ communityfingerprints (Bob's Wi-Fi scans)
```

**Query examples**:

*Get all detections for User A's asset*:
```javascript
const asset = await Asset.findOne({ userId: userA._id, trackerId: "AG-001" });
const detections = await CommunityDetection.find({ assetId: asset._id });
```

*Get User A's unread notifications*:
```javascript
const notifications = await Notification.find({
  recipient: userA._id,
  read: false
}).sort({ createdAt: -1 });
```

*Count User A's lost assets with recent detections*:
```javascript
const lostAssets = await Asset.find({ userId: userA._id, status: 'LOST' });
const tracking = await Promise.all(
  lostAssets.map(async asset => {
    const recent = await CommunityDetection.findOne({
      assetId: asset._id,
      detectedAt: { $gte: new Date(Date.now() - 7*24*60*60*1000) }
    });
    return recent ? 1 : 0;
  })
);
const trackingCount = tracking.reduce((a, b) => a + b, 0);
```

---

**Q29: How do you handle errors gracefully without crashing?**

**A**: Multiple layers of error handling:

**Layer 1: Try-Catch Blocks**

Flutter:
```dart
try {
  final assets = await AssetService.instance.getAssets();
  setState(() => _assets = assets);
} on ApiException catch (e) {
  // Network/API error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message), backgroundColor: Colors.red),
  );
} catch (e) {
  // Unexpected error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Unexpected error: $e')),
  );
}
```

Backend:
```javascript
try {
  const asset = await Asset.create({...});
  res.json({ asset });
} catch (err) {
  console.error('[Asset] Error:', err);
  res.status(500).json({ message: 'Failed to create asset' });
}
```

**Layer 2: Graceful Degradation**

Wi-Fi unavailable:
```dart
// BLE detection still works, just no room prediction
if (wifiFingerprint != null) {
  // Include Wi-Fi
} else {
  // Continue without Wi-Fi - graceful degradation
}
```

ML server down:
```javascript
try {
  const mlResponse = await fetch(mlUrl, {timeout: 10s});
  // ... process ML response
} catch (mlErr) {
  console.log('[ML] Prediction failed:', mlErr.message);
  predictedRoom = null;  // Degrade gracefully
}
// Detection continues without room prediction
```

**Layer 3: Non-Critical Operations**

Notification creation failure:
```javascript
try {
  const notification = await Notification.create({...});
  console.log('[Community] Notification created');
} catch (notifErr) {
  // DO NOT fail the detection
  console.error('[Community] Failed to create notification:', notifErr);
  console.error('[Community] Detection still recorded successfully');
}
// Detection record saved successfully, notification is bonus
```

**Layer 4: User Feedback**

Show errors to user:
```dart
// Clear error messages
setState(() => _error = 'Name is required');

// Snackbar for API errors
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Failed to create asset. Please try again.')),
);

// Retry button
if (_error != null) {
  ElevatedButton(
    onPressed: _retry,
    child: Text('Retry'),
  );
}
```

**Layer 5: Logging**

Debug logs for diagnosis:
```dart
debugPrint('[Service] Operation failed: $e');
debugPrint('[Service] Stack trace: $stackTrace');
```

Backend logs:
```javascript
console.log('[Controller] Info message');
console.error('[Controller] Error:', err);
console.error('[Controller] Stack trace:', err.stack);
```

**Layer 6: Defensive Programming**

Null safety:
```dart
// Check before using
if (notification.predictedRoom != null) {
  _buildRoomChip(notification.predictedRoom!, notification.roomConfidence);
}

// Provide defaults
final count = response['count'] ?? 0;
```

**Principle**: **Never let one failure cascade into system failure**
- Wi-Fi fails → BLE continues
- ML fails → Detection continues
- Notification fails → Detection record preserved
- One user's error doesn't affect others

---

**Q30: What are the system's main limitations and how would you improve them?**

**A**: Current limitations and future improvements:

**Limitation 1: Android Only**
- Current: Flutter app doesn't support iOS background BLE
- Reason: iOS restricts background BLE scanning severely
- Impact: iPhone users cannot use Community Sensing
- Improvement: Use iBeacon protocol for iOS, different implementation

**Limitation 2: Polling for Notifications**
- Current: App polls every 30 seconds
- Impact: Delay in notification delivery, battery drain
- Improvement: Implement Firebase Cloud Messaging (FCM) for push notifications

**Limitation 3: No Real-Time Updates**
- Current: Must refresh manually or wait for poll
- Impact: Stale data in UI
- Improvement: WebSocket connection for real-time updates

**Limitation 4: Limited ML Accuracy (97.96%)**
- Current: Sometimes predicts wrong room (usually adjacent)
- Impact: User might check wrong room first
- Improvement:
  - Collect more training data
  - Add accelerometer/magnetometer data (user orientation)
  - Use RSSI from BLE + Wi-Fi together

**Limitation 5: Campus-Specific**
- Current: Hardcoded NIE-STUDENTS/NIE-STAFF networks
- Impact: Doesn't work on other campuses
- Improvement: Auto-detect campus Wi-Fi, or let user configure

**Limitation 6: Battery Drain**
- Current: ~10-15% extra battery per 8 hours
- Impact: Users might disable Community Sensing
- Improvement:
  - Adaptive scan frequency (scan less when stationary)
  - Use Android JobScheduler for smarter background work
  - Reduce scan duration when no assets detected recently

**Limitation 7: Single Tracker Per Asset**
- Current: One tracker ID per asset
- Impact: If tracker battery dies, asset becomes untrackable
- Improvement: Support multiple trackers per asset (redundancy)

**Limitation 8: No Tracker Battery Indicator**
- Current: User doesn't know when tracker battery is low
- Impact: Tracker dies, user doesn't know
- Improvement: BLE can read battery level (if tracker supports)

**Limitation 9: Privacy Concerns**
- Current: Anyone with Community Sensing ON is tracked (aggregate location data collected)
- Impact: Some users uncomfortable with continuous BLE/Wi-Fi scanning
- Improvement:
  - End-to-end encryption for detection data
  - Anonymize data before storing
  - Let users schedule Community Sensing (e.g., only during day)

**Limitation 10: No Recovery Verification**
- Current: User marks as recovered, but could be lying
- Impact: Lost asset still out there, but owner marks recovered (claim fraud)
- Improvement: Require photo proof or QR code scan of tracker

**Scalability Improvements**:
- Redis caching for frequently accessed data
- CDN for static assets
- Database sharding as user base grows
- Load balancer for multiple backend instances

**Most Important**: iOS support (expands user base) and Push notifications (better UX)

---

## TOP 10 FILES TO KNOW FOR PRESENTATION

### Flutter (Mobile App)

**1. `lib/main.dart`**
- **Why**: Entry point of the entire application
- **Key Points**: Initializes foreground task, sets up deep links, launches first screen (SplashScreen)
- **Know**: `main()` function, `CommunitySensingService.initForegroundTask()`, deep link handling for email verification

---

**2. `lib/services/community_sensing_service.dart`** ⭐ MOST CRITICAL
- **Why**: Orchestrates the entire community detection system (BLE + Wi-Fi)
- **Key Points**:
  - Two Timers running every 15 seconds (BLE and Wi-Fi) in main isolate
  - Foreground service with persistent notification
  - `_performBleScan()` - BLE detection logic
  - `_performWifiScan()` - Wi-Fi fingerprint collection
  - Cache integration for Wi-Fi data
- **Know**: Why timers run in main isolate (inter-isolate messaging was unreliable), 15-second interval reasoning, debounce (60s)

---

**3. `lib/services/ble_service.dart`** ⭐ CRITICAL
- **Why**: Core BLE scanning implementation
- **Key Points**:
  - `scan()` method using `flutter_blue_plus`
  - 8-second scan duration
  - Filters AssetGuard trackers (AG-XXX pattern)
  - Captures RSSI for proximity estimation
- **Know**: Why 8 seconds, what RSSI means, how tracker ID is extracted from device name

---

**4. `lib/services/wifi_scan_service.dart`**
- **Why**: Wi-Fi fingerprint collection for ML
- **Key Points**:
  - `scanNieAccessPoints()` - filters only NIE-STUDENTS/NIE-STAFF
  - Returns BSSID + RSSI pairs
  - `toRssiMap()` converts to `Map<String, int>`
- **Know**: BSSID vs SSID, why filter campus networks only, typical scan yields 70-100 BSSIDs

---

**5. `lib/services/auth_service.dart`**
- **Why**: Authentication and JWT token management
- **Key Points**:
  - `login()`, `register()`, `logout()`
  - Stores JWT in SharedPreferences
  - `tryAutoLogin()` on app startup
- **Know**: JWT structure, where token is stored, how it's included in API requests

---

### Backend (Node.js API)

**6. `backend/src/controllers/communityController.js`** ⭐ MOST CRITICAL
- **Why**: Heart of community detection + ML integration + notification creation
- **Key Points**:
  - `submitCommunityDetection()` - processes detections from User B
  - **Line ~141**: Critical status check `if (asset.status !== 'LOST')` - prevents spam after recovery
  - **Line ~159-185**: ML server integration (POST /predict-room)
  - **Line ~190-220**: Notification creation with room prediction
- **Know**: Complete flow from detection received → ML called → notification created, why status check is critical, graceful degradation if ML fails

---

**7. `backend/src/controllers/authController.js`**
- **Why**: User authentication and JWT generation
- **Key Points**:
  - `register()` - creates user, hashes password with bcrypt
  - `login()` - verifies password, generates JWT
  - `verifyEmail()` - email verification flow
- **Know**: JWT generation (`jwt.sign()`), password hashing, email verification bypass in dev mode

---

**8. `backend/src/models/Asset.js`**
- **Why**: Asset schema with critical status field
- **Key Points**:
  - Status enum: 'ACTIVE', 'LOST', 'RECOVERED'
  - `userId` field links to owner
  - `trackerId` must be unique per user
- **Know**: Asset lifecycle (ACTIVE → LOST → RECOVERED), why status field matters

---

**9. `backend/src/middleware/auth.js`**
- **Why**: JWT verification on every protected route
- **Key Points**:
  - `protect()` middleware extracts and verifies JWT
  - Attaches `req.user` for controllers to use
  - Returns 401 if token invalid/expired
- **Know**: How JWT is extracted from Authorization header, signature verification, user lookup

---

**10. `backend/src/models/CommunityDetection.js`**
- **Why**: Stores detection records with ML predictions
- **Key Points**:
  - `predictedRoom` and `roomConfidence` fields from ML
  - `detectedBy` field (User B, hidden from owner for privacy)
  - `latitude`, `longitude` for Track Asset map
- **Know**: All fields stored in detection record, privacy (detectedBy excluded in API responses)

---

## KEY TAKEAWAYS FOR PRESENTATION

**Memorize These Numbers**:
- **22 rooms**: ML model output classes
- **106 BSSIDs**: ML model input features
- **97.96%**: ML model accuracy
- **15 seconds**: BLE and Wi-Fi scan interval
- **8 seconds**: BLE scan duration
- **60 seconds**: Debounce period
- **2 minutes**: Wi-Fi cache validity
- **10 seconds**: ML API timeout
- **7 days**: JWT expiration
- **10-15%**: Battery drain per 8 hours with Community Sensing

**Critical Code Locations**:
- **Status check**: `backend/src/controllers/communityController.js` line ~141
- **ML integration**: Same file, lines ~159-185
- **Notification creation**: Same file, lines ~190-220
- **BLE Timer**: `lib/services/community_sensing_service.dart` line ~242
- **Wi-Fi Timer**: Same file, line ~256
- **Cache update**: Same file, line ~296
- **Cache retrieval**: Same file, line ~388

**Be Ready to Explain**:
1. Why BLE + Wi-Fi (not just GPS)
2. Why Random Forest (not neural network)
3. Why separate ML server
4. Why foreground service with notification
5. Why status check prevents spam
6. Complete detection flow (User B → Backend → ML → User A)
7. How Wi-Fi fingerprinting works
8. What happens if ML server is down (graceful degradation)
9. JWT authentication flow
10. Asset lifecycle (ACTIVE → LOST → RECOVERED)

**Demo Flow** (4 minutes):
1. Show User A marks asset as LOST (30s)
2. Show User B enables Community Sensing (30s)
3. Bring phones close, show logs (90s)
4. Show User A receives notification with room (30s)
5. Show Track Asset map (30s)

**Common Questions You'll Get**:
- "Why not use GPS?" → Doesn't work indoors
- "Why Random Forest?" → High accuracy, fast, handles missing features
- "How accurate is it?" → 97.96%, even wrong predictions usually adjacent rooms
- "What if Wi-Fi is off?" → Graceful degradation, works without room prediction
- "Privacy concerns?" → Detector identity hidden, end-to-end could be added
- "Battery drain?" → 10-15% per 8 hours, acceptable for community benefit

---

**GOOD LUCK WITH YOUR PRESENTATION! 🎓**

You now have complete documentation of the entire AssetGuard project. Review the PRESENTATION_GUIDE.md for a condensed version and the 30 viva questions. Practice explaining the detection flow diagram and you'll do great!

