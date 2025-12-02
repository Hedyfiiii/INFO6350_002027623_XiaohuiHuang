import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Human Face Detection App',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Firebase instances
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseFirestore fb = FirebaseFirestore.instance;
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // ML Kit face detector
  late final FaceDetector faceDetector;

  // Selected image
  File? _image;
  bool isLoading = false;
  String? fcmToken;

  // List of asset images
  List<String> assetImages = [];

  @override
  void initState() {
    super.initState();
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
    _loadAssetImages();
    _initializeNotifications();
  }

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  // Initialize Firebase Cloud Messaging
  Future<void> _initializeNotifications() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }

      // Get FCM token
      fcmToken = await messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $fcmToken');
      }

      // Save token to Firestore (optional - for targeted notifications)
      if (fcmToken != null) {
        await fb.collection('fcm_tokens').doc('current_device').set({
          'token': fcmToken,
          'created_at': FieldValue.serverTimestamp(),
          'platform': Platform.isAndroid ? 'android' : 'ios',
        });
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          print('FCM Token refreshed: $newToken');
        }
        setState(() {
          fcmToken = newToken;
        });
        // Update token in Firestore
        fb.collection('fcm_tokens').doc('current_device').set({
          'token': newToken,
          'created_at': FieldValue.serverTimestamp(),
          'platform': Platform.isAndroid ? 'android' : 'ios',
        });
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message in foreground!');
          print('Message data: ${message.data}');
        }

        if (message.notification != null) {
          if (kDebugMode) {
            print('Message also contained a notification: ${message.notification}');
          }
          
          // Show dialog when app is in foreground
          _showNotificationDialog(
            message.notification!.title ?? 'Notification',
            message.notification!.body ?? '',
          );
        }
      });

      // Handle notification taps when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Notification tapped!');
          print('Message data: ${message.data}');
        }
        
        // Navigate to SecondPage when notification is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SecondPage()),
        );
      });

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('App opened from notification!');
        }
        // Navigate to SecondPage
        Future.delayed(Duration.zero, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecondPage()),
          );
        });
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  // Show notification dialog when app is in foreground
  void _showNotificationDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SecondPage()),
              );
            },
            child: const Text('View Images'),
          ),
        ],
      ),
    );
  }

  // Load list of images from assets
  Future<void> _loadAssetImages() async {
    final List<String> imageNames = [
      'image1.jpeg',
      'image2.jpeg',
      // Add as need
    ];

    List<String> validImages = [];
    
    for (String imageName in imageNames) {
      try {
        await rootBundle.load('assets/images/$imageName');
        validImages.add('assets/images/$imageName');
      } catch (e) {
        if (kDebugMode) {
          print('Asset not found: assets/images/$imageName');
        }
      }
    }

    setState(() {
      assetImages = validImages;
    });
  }

  // Take picture with camera
  Future<void> takePicture() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _image = File(image.path);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Camera error: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error accessing camera')),
      );
    }
  }

  // Pick image from assets
  Future<void> pickFromAssets() async {
    if (assetImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No images found in assets/images/ folder'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final String? selectedAsset = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image from Assets'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: assetImages.length,
              itemBuilder: (context, index) {
                final assetPath = assetImages[index];
                final fileName = path.basename(assetPath);
                
                return ListTile(
                  leading: Image.asset(
                    assetPath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error);
                    },
                  ),
                  title: Text(fileName),
                  onTap: () {
                    Navigator.pop(context, assetPath);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedAsset != null) {
      try {
        final ByteData data = await rootBundle.load(selectedAsset);
        final List<int> bytes = data.buffer.asUint8List();
        
        final Directory tempDir = await getTemporaryDirectory();
        final String fileName = path.basename(selectedAsset);
        final File tempFile = File('${tempDir.path}/$fileName');
        
        await tempFile.writeAsBytes(bytes);
        
        setState(() {
          _image = tempFile;
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error loading asset: $e');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading image from assets')),
        );
      }
    }
  }

  // Save image: Upload and navigate to detection
  Future<void> saveImage() async {
    if (_image == null) return;

    setState(() {
      isLoading = true;
    });

    final String imagePath = _image!.path;

    try {
      String fileName = path.basename(_image!.path);
      String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      TaskSnapshot snapshot = await storage.ref(uniqueFileName).putFile(_image!);

      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        // Save with FCM token for notification targeting
        DocumentReference docRef = await fb.collection("images").add({
          "url": downloadUrl,
          "path": uniqueFileName,
          "original_filename": fileName,
          "uploaded_by": "User",
          "description": "Uploaded image",
          "has_face": false,
          "face_count": 0,
          "uploaded_at": FieldValue.serverTimestamp(),
          "face_detection_status": "pending",
          "fcm_token": fcmToken, // Store token for targeted notification
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded! Detecting faces...'),
            duration: Duration(seconds: 2),
          ),
        );

        setState(() {
          _image = null;
          isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SecondPage(
              detectImageId: docRef.id,
              detectImagePath: imagePath,
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Upload error: $e');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: ${e.toString()}')),
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Human Face Detection App'),
        centerTitle: true,
        actions: [
          // Show FCM token status
          if (fcmToken != null)
            IconButton(
              icon: const Icon(Icons.notifications_active),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Push notifications enabled ✓'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Notifications Enabled',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // FCM Token Display (for testing)
            if (kDebugMode && fcmToken != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token (for testing):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      fcmToken!,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),

            // Camera and Assets buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  onPressed: isLoading ? null : takePicture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.folder),
                  label: const Text("Assets"),
                  onPressed: isLoading ? null : pickFromAssets,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Display selected image
            _image == null
                ? Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No image selected',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_image!, fit: BoxFit.contain),
                    ),
                  ),

            const SizedBox(height: 20),

            // Loading indicator or Save button
            isLoading
                ? const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Uploading image...',
                          style: TextStyle(fontSize: 14)),
                    ],
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text("Upload & Detect Faces"),
                    onPressed: _image == null ? null : saveImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                    ),
                  ),

            const SizedBox(height: 30),

            // Navigate to SecondPage to view saved images
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text("View Saved Images"),
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SecondPage()),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Second page to display saved images with face detection
class SecondPage extends StatefulWidget {
  final String? detectImageId;
  final String? detectImagePath;

  const SecondPage({super.key, this.detectImageId, this.detectImagePath});

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final FirebaseFirestore fb = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();
    if (widget.detectImageId != null && widget.detectImagePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _detectFaceForUploadedImage();
      });
    }
  }

  // Send FCM notification via HTTP
  Future<void> _sendFCMNotification(String fcmToken, bool hasFace, int faceCount) async {
    const String serverKey = 'YOUR_SERVER_KEY_HERE'; // Replace with your Firebase Server Key
    
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': fcmToken,
          'notification': {
            'title': 'Face Detection Complete! ✅',
            'body': hasFace
                ? 'Found $faceCount face(s) in your image'
                : 'No faces detected in your image',
            'sound': 'default',
          },
          'data': {
            'image_id': widget.detectImageId,
            'face_count': faceCount.toString(),
            'has_face': hasFace.toString(),
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('FCM notification sent successfully');
        }
      } else {
        if (kDebugMode) {
          print('Failed to send FCM notification: ${response.statusCode}');
          print('Response: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending FCM notification: $e');
      }
    }
  }

  // Detect faces for the newly uploaded image
  Future<void> _detectFaceForUploadedImage() async {
    if (widget.detectImageId == null || widget.detectImagePath == null) return;

    setState(() {
      isDetecting = true;
    });

    FaceDetector? faceDetector;

    try {
      faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableClassification: true,
        ),
      );

      final File imageFile = File(widget.detectImagePath!);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      final inputImage = InputImage.fromFilePath(widget.detectImagePath!);
      final List<Face> faces = await faceDetector.processImage(inputImage);
      int faceCount = faces.length;
      bool hasFace = faceCount > 0;

      // Get the document to retrieve FCM token
      final docSnapshot = await fb.collection("images").doc(widget.detectImageId).get();
      final fcmToken = docSnapshot.data()?['fcm_token'] as String?;

      // Update Firestore with face detection results
      await fb.collection("images").doc(widget.detectImageId).update({
        "has_face": hasFace,
        "face_count": faceCount,
        "face_detection_status": "completed",
        "detection_completed_at": FieldValue.serverTimestamp(),
      });

      // Send actual FCM notification
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _sendFCMNotification(fcmToken, hasFace, faceCount);
      }

      if (!mounted) return;

      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasFace
              ? '✅ Face detection complete! Found $faceCount face(s)\n🔔 Push notification sent!'
              : '✅ Face detection complete! No faces detected\n🔔 Push notification sent!'),
          duration: const Duration(seconds: 4),
          backgroundColor: hasFace ? Colors.green : Colors.blue,
        ),
      );

      setState(() {
        isDetecting = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Face detection error: $e');
      }

      try {
        await fb.collection("images").doc(widget.detectImageId).update({
          "face_detection_status": "error",
          "error_message": e.toString(),
        });
      } catch (firestoreError) {
        if (kDebugMode) {
          print('Firestore update error: $firestoreError');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error during face detection'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        isDetecting = false;
      });
    } finally {
      await faceDetector?.close();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getImagesStream() {
    return fb
        .collection("images")
        .orderBy("uploaded_at", descending: true)
        .snapshots();
  }

  Future<void> _deleteImage(String docId, String imagePath) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await storage.ref(imagePath).delete();
      await fb.collection("images").doc(docId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Delete error: $e');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Images"),
        centerTitle: true,
        actions: [
          if (isDetecting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            if (isDetecting)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Detecting faces... You\'ll receive a notification when done!',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: StreamBuilder(
                stream: getImagesStream(),
                builder: (context,
                    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                        snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data?.docs.isEmpty ?? true) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'No images saved yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Go back and capture/upload some images!',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data?.docs.length ?? 0,
                    itemBuilder: (BuildContext context, int index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data();
                      bool hasFace = data["has_face"] ?? false;
                      int faceCount = data["face_count"] ?? 0;
                      String status =
                          data["face_detection_status"] ?? "completed";
                      String docId = doc.id;
                      String imagePath = data["path"] ?? "";

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12.0),
                          title: Text(
                            data["uploaded_by"] ?? "Unknown",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(data["description"] ?? "No description"),
                              const SizedBox(height: 4),
                              Text(
                                status == "pending"
                                    ? '⏳ Detecting faces...'
                                    : status == "error"
                                        ? '⚠️ Detection failed'
                                        : hasFace
                                            ? '✅ $faceCount face(s) detected'
                                            : '❌ No faces detected',
                                style: TextStyle(
                                  color: status == "pending"
                                      ? Colors.orange
                                      : status == "error"
                                          ? Colors.red
                                          : hasFace
                                              ? Colors.green
                                              : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data["url"],
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.error),
                                );
                              },
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () => _deleteImage(docId, imagePath),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}