# StepWise

A Flutter-based mobile application designed to track daily steps and promote a healthier lifestyle.

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Setup and Installation](#setup-and-installation)
- [Known Issues](#known-issues)
- [Contributing](#contributing)
- [License](#license)

## Project Overview

StepWise is a step counter application built with Flutter. It aims to provide users with a simple and intuitive interface to monitor their physical activity, stay motivated, and engage with a community of fellow users. The app leverages Firebase for user authentication and the device's built-in sensors for step tracking.

## Features

- **Daily Step Counting**: Tracks steps for the current day, resetting at midnight.
- **User Authentication**: Secure sign-up and sign-in using Email/Password and Google Sign-In, powered by Firebase Authentication.
- **Dashboard**: A central screen displaying today's step count and other key metrics.
- **Activity Log**: A detailed view of past activity.
- **Health & Tips**: A dedicated section for health-related articles and tips.
- **Leaderboard**: A screen to see how you rank against other users.
- **User Profile**: Manage your account and settings, including a sign-out option.
- **Notifications**: A page for app-related notifications.
- **Consistent Theming**: A unified and modern UI with custom color schemes and text styles.

## Screenshots

### Dashboard
![Dashboard](assets/screenshots/dashboard.png)

### Activity Log
![Activity Log](assets/screenshots/activity_log.png)

### Health & Wellness Tips
![Health & Wellness Tips](assets/screenshots/health_tips.png)

### Profile Page
![Profile Page](assets/screenshots/profile.png)

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: [Dart](https://dart.dev/)
- **Backend & Authentication**: [Firebase](https://firebase.google.com/) (Firebase Auth)
- **State Management**: `setState` (for current features)
- **Dependencies**:
  - `firebase_core`: For initializing Firebase.
  - `firebase_auth`: For authentication.
  - `google_sign_in`: For Google Sign-In functionality.
  - `pedometer`: For accessing step count data.
  - `permission_handler`: For requesting runtime permissions.
  - `shared_preferences`: for persisting daily step data.

## Project Structure

The project follows a feature-driven directory structure to keep the code organized and scalable.

```
stepwise/
└── lib/
    ├── main.dart             # App entry point, routes, and initialization
    ├── screens/              # Individual screen widgets
    │   ├── welcome_page.dart
    │   ├── login_page.dart
    │   ├── register_page.dart
    │   ├── dashboard_page.dart
    │   └── ...
    ├── widgets/              # Reusable UI components
    │   └── bottom_nav_bar.dart
    └── theme/                # App-wide theme, colors, and text styles
        ├── app_colors.dart
        └── app_text_styles.dart
```

## Setup and Installation

To get the project up and running on your local machine, follow these steps:

1.  **Clone the Repository**
    ```sh
    git clone <repository-url>
    cd StepWise/stepwise
    ```

2.  **Install Dependencies**
    ```sh
    flutter pub get
    ```

3.  **Firebase Setup (Android)**
    - This project is configured to use Firebase on Android.
    - You must add your own `google-services.json` file to the `stepwise/android/app/` directory. You can obtain this file from your own Firebase project console.

4.  **Run the Application**
    ```sh
    flutter run
    ```

## Known Issues

1.  **Google Sign-In Error**: There is a known issue on Android where Google Sign-In fails after account selection with the error: `type 'List<Object>' is not a subtype of type 'PigeonUserDetails?'`. This appears to be a bug within the native Firebase/Google Sign-In plugins and not a direct issue with the Dart implementation.
2.  **Linter Warnings**: The project currently has several linter warnings related to unused variables and missing `const` constructors. These are pending cleanup.

## Contributing

Contributions are welcome! If you'd like to contribute, please fork the repository and create a pull request.

## License

This project is licensed under the MIT License.
