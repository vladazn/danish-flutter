# DanishVocab

A Flutter application for learning Danish vocabulary with spaced repetition and custom vocabulary sets.

## Features

- Vocabulary management with custom sets
- Spaced repetition learning system
- Practice sessions for specific vocabulary sets
- Google Sign-In authentication
- Firebase backend integration

## Getting Started

### Prerequisites

- Flutter SDK (^3.8.0)
- Dart SDK
- Firebase project setup

### Environment Setup

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Configure Firebase credentials in `.env`:**
   ```env
   FIREBASE_API_KEY=your_actual_api_key
   FIREBASE_APP_ID=your_actual_app_id
   FIREBASE_MESSAGING_SENDER_ID=your_actual_sender_id
   FIREBASE_PROJECT_ID=your_actual_project_id
   FIREBASE_STORAGE_BUCKET=your_actual_storage_bucket
   FIREBASE_AUTH_DOMAIN=your_actual_auth_domain
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

### Important Notes

- **Never commit `.env`** - it contains sensitive Firebase credentials
- **Always commit `.env.example`** - shows required environment variables
- The `.gitignore` file is configured to exclude sensitive files

## Development

This project uses:
- **Riverpod** for state management
- **Firebase** for backend services
- **Material Design** for UI components

### Local Development with Web

To run the project locally with web build and serve it using Python's built-in HTTP server:

1. **Build the web version:**
   ```bash
   flutter build web
   ```

2. **Serve the built web files:**
   ```bash
   python3 -m http.server 8080
   ```

3. **Open your browser and navigate to:**
   ```
   http://localhost:8080
   ```

**Note:** Make sure you have the `make` command available and the project's Makefile configured for the `build web` target.

## Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web (requires Node.js)
npm run build:web
flutter build web --release
```

### Web Build Setup

For web builds, you need to generate the environment configuration:

1. **Install Node.js dependencies:**
   ```bash
   npm install
   ```

2. **Build environment variables:**
   ```bash
   npm run build:web
   ```

3. **Build Flutter web:**
   ```bash
   flutter build web --release
   ```

**Note:** The `web/env.js` file is automatically generated and should not be committed to git.
