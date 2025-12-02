# my_project

A Flutter application that captures photos, uploads them to Firebase Storage, detects human faces using Firebase ML Kit, and supports push notifications through Firebase Cloud Messaging.


# Features

* Camera Integration: Capture photos using device camera
* Firebase Storage: Upload captured images to cloud storage
* Face Detection: Detect human faces in images using Firebase ML Kit
* Push Notifications: Receive notifications through Firebase Cloud Messaging
* Result Display: Show face detection results via Snackbar


# Usage

Taking Photos and Face Detection

1. Launch the app
2. Grant camera permissions when prompted
3. Tap the "Camera" button to take a photo, or tap the "Assets" button to select a stored image
4. Upload the image to Firebase Storage
5. The app will automatically:
(1) Analyze the image for human faces using ML Kit
(2) Display results in a Snackbar ("Face detected!" or "No face detected")
