# Firebase Dynamic Migration Demo

> Demo project for dynamic Firebase project switching and data migration.

---

## IMPORTANT: Firebase Setup Required

**This project will NOT work without proper Firebase configuration!**

The included `GoogleService-Info-*.plist` files contain **placeholder values** and must be replaced with real configuration files from your Firebase project.

### Quick Setup (5 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project (or use existing)
3. Click "Add app" -> iOS
4. Enter Bundle ID: `com.example.FirebaseDynamicMigrationDemo`
5. Download `GoogleService-Info.plist`
6. Rename to `GoogleService-Info-Sandbox.plist`
7. Replace the file in `FirebaseDynamicMigrationDemo/Resources/Firebase/`
8. Build and run!

Without this setup, the app will show a "Firebase Setup Required" screen with instructions.

<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2025-12-26 at 15 45 07" src="https://github.com/user-attachments/assets/59615092-d2e2-4608-81cd-fa0e1f464585" />


---

## Description

This project demonstrates:

1. **Dynamic Firebase project switching** - how to connect to different Firebase projects at runtime
2. **Simultaneous work with multiple projects** - using named Firebase Apps
3. **Data migration between projects** - transferring user data from OldApp to NewApp
4. **Using Firebase without registered Bundle ID** - when it works and when it doesn't

## Architecture

```
+-------------------------------------------------------------+
|                    OldApp (this application)                |
+-------------------------------------------------------------+
|  Default Firebase App          |   Named Firebase App       |
|  (Production or Sandbox)       |   (Migration)              |
|                                |                            |
|  +-------------------------+   |   +---------------------+  |
|  |    OldAppFB / SandboxFB |   |   |      NewAppFB       |  |
|  |    (main project)       |   |   |  (migration project)|  |
|  +-------------------------+   |   +---------------------+  |
+-------------------------------------------------------------+
                                          |
                                          v
                               +---------------------+
                               |   Firestore NewApp  |
                               |   users/{userId}    |
                               +---------------------+
                                          |
                                          v
+-------------------------------------------------------------+
|                          NewApp                              |
|  +-----------------------------------------------------+    |
|  |             Default Firebase App                     |    |
|  |                   NewAppFB                           |    |
|  |            (directly connected)                      |    |
|  +-----------------------------------------------------+    |
+-------------------------------------------------------------+
```

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/your-repo/FirebaseDynamicMigrationDemo.git
cd FirebaseDynamicMigrationDemo
```

### 2. Configure Firebase (REQUIRED!)

#### Create Firebase projects

You will need at least 1 Firebase project for basic testing:
- **Sandbox** - for development (required)
- **Migration** - NewApp project (optional, can use same as Sandbox for testing)

#### Add plist files

**Option A: Single project (minimal setup)**

1. Download `GoogleService-Info.plist` from Firebase Console
2. Rename to `GoogleService-Info-Sandbox.plist`
3. Place in `FirebaseDynamicMigrationDemo/Resources/Firebase/`
4. Done! The app will work in Sandbox mode.

**Option B: Multiple projects (full demo)**

1. Download plist files from each Firebase project
2. Rename them:
   - `GoogleService-Info-Production.plist` (optional)
   - `GoogleService-Info-Sandbox.plist` (required)
   - `GoogleService-Info-Migration.plist` (for migration demo)
3. Place all in `FirebaseDynamicMigrationDemo/Resources/Firebase/`

#### Update expected Project IDs (optional)

In `FBConfigurationType.swift`, update `expectedProjectId` with your actual project IDs:

```swift
var expectedProjectId: String {
    switch self {
    case .production:
        return "your-actual-production-project-id"
    case .sandbox:
        return "your-actual-sandbox-project-id"
    case .migration:
        return "your-actual-migration-project-id"
    }
}
```

### 3. Configure Firestore Rules (for migration demo)

In Firebase Console -> Firestore Database -> Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Allow read/write for everyone (for demo only!)
      // WARNING: Use stricter rules in production!
      allow read, write: if true;
    }
  }
}
```

### 4. Open project in Xcode

```bash
open FirebaseDynamicMigrationDemo.xcodeproj
```

### 5. Run the application

Select simulator and press Run (Cmd+R).

## Project Structure

```
FirebaseDynamicMigrationDemo/
|-- Sources/
|   |-- App/
|   |   +-- FirebaseDynamicMigrationDemoApp.swift    # Entry point
|   |
|   |-- Views/
|   |   |-- ContentView.swift                        # Main screen
|   |   |-- FirebaseStatusView.swift                 # Connection status
|   |   |-- MigrationView.swift                      # Migration UI (OldApp)
|   |   |-- ImportView.swift                         # Import UI (NewApp)
|   |   +-- FirebaseConfigView.swift                 # Firebase settings
|   |
|   |-- ViewModels/
|   |   |-- MigrationViewModel.swift                 # Migration logic
|   |   +-- ImportViewModel.swift                    # Import logic
|   |
|   |-- FBConfigurationType.swift                    # Configuration types
|   |-- FirebaseConfigurationManager.swift           # Firebase manager
|   |-- DataMigrationManager.swift                   # Migration manager
|   |-- DataImporter.swift                           # Data import
|   +-- MigrationError.swift                         # Errors
|
|-- Resources/
|   |-- Assets.xcassets/                             # Resources
|   +-- Firebase/
|       |-- GoogleService-Info-Production.plist      # Production (replace!)
|       |-- GoogleService-Info-Sandbox.plist         # Sandbox (replace!)
|       +-- GoogleService-Info-Migration.plist       # Migration (replace!)
|
+-- Preview Content/
    +-- Preview Assets.xcassets/                     # Preview resources
```

## Key Components

### FBConfigurationType

Enum defining Firebase configuration types:

```swift
enum FBConfigurationType {
    case production  // Default app, production
    case sandbox     // Default app, sandbox
    case migration   // Named app, migration
    
    var usesDefaultApp: Bool { ... }
    var firebaseAppName: String { ... }
    var firebaseApp: FirebaseApp? { ... }
}
```

### FirebaseConfigurationManager

Singleton for managing configurations:

```swift
// Switch configuration
FirebaseConfigurationManager.shared.switchConfiguration(to: .sandbox)

// Enable migration mode
FirebaseConfigurationManager.shared.setMigrationMode(true)

// Check if Firebase is properly configured
if FirebaseConfigurationManager.shared.isFirebaseConfigured {
    // Perform Firebase operations
}
```

### DataMigrationManager

Performs data migration:

```swift
DataMigrationManager.shared.migrateData(userId: "user@example.com") { result in
    switch result {
    case .success:
        print("Success!")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## Important Notes

### Bundle ID and Firebase

Not all Firebase services work with a "foreign" Bundle ID:

| Service | Works without Bundle ID? |
|---------|-------------------------|
| Firestore | Yes |
| Authentication | Yes |
| Cloud Messaging (FCM) | No |
| Remote Config | Partially |
| Analytics | No |
| Crashlytics | No |

### Security

1. **Never commit** real GoogleService-Info.plist files to Git
2. Add to `.gitignore`:
   ```
   GoogleService-Info-*.plist
   !GoogleService-Info-*.plist.template
   ```
3. Use strict Firestore Rules in production

### User ID for Migration

WARNING: **Do NOT use Firebase UID** as migration key!

Firebase UID is bound to a specific project and will be different in OldApp and NewApp.

Use instead:
- User email
- External ID from your system
- UUID generated at registration

## Troubleshooting

### "Firebase Setup Required" screen

This means the plist files contain placeholder values. Follow the setup instructions above.

### App crashes on launch

Check that:
1. GoogleService-Info-Sandbox.plist exists in Resources/Firebase/
2. The file contains valid Firebase configuration (not placeholder values)
3. The GOOGLE_APP_ID format is correct: `1:123456789:ios:abcdef123456`

### "Configuration fails" error

This error occurs when GOOGLE_APP_ID in the plist is invalid. Download a fresh GoogleService-Info.plist from Firebase Console.

## Related Materials

- [Medium: Dynamic Firebase Project Switching (eng)](https://medium.com/@fbcdaccfebbdeaaddc/firebase-dynamic-switching-of-projects-in-an-ios-app-8a00aa5dc130?postPublishedType=initial)
- [Habr: Dynamic Firebase Project Switching (rus)](https://habr.com/ru/articles/982284/)
- [Firebase iOS SDK Documentation](https://firebase.google.com/docs/ios/setup)
- [FirebaseApp.configure() API](https://firebase.google.com/docs/reference/swift/firebasecore/api/reference/Classes/FirebaseApp)

## License

MIT License
