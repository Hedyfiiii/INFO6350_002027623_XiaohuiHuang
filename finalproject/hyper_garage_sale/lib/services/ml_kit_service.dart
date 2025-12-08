import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MLKitService {
  static final MLKitService _instance = MLKitService._internal();
  factory MLKitService() => _instance;
  MLKitService._internal();

  ImageLabeler? _imageLabeler;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('ML Kit already initialized');
      return;
    }

    try {
      print('Initializing ML Kit Image Labeler...');
      
      // Initialize with default base model (on-device)
      final options = ImageLabelerOptions(
        confidenceThreshold: 0.5, // Only return labels with 50%+ confidence
      );
      
      _imageLabeler = ImageLabeler(options: options);
      _isInitialized = true;
      print('✅ ML Kit Image Labeler initialized successfully');
    } catch (e) {
      print('❌ Error initializing ML Kit: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<List<String>> classifyImage(File imageFile) async {
    print('🔍 Starting image classification...');
    print('Image path: ${imageFile.path}');
    print('File exists: ${imageFile.existsSync()}');
    
    if (!_isInitialized) {
      print('ML Kit not initialized, initializing now...');
      await initialize();
    }

    if (_imageLabeler == null) {
      print('❌ Image labeler is null after initialization');
      return [];
    }

    try {
      print('Creating InputImage from file...');
      final inputImage = InputImage.fromFile(imageFile);
      print('InputImage created successfully');
      
      print('Processing image with ML Kit...');
      final labels = await _imageLabeler!.processImage(inputImage);
      print('✅ ML Kit processing complete, found ${labels.length} labels');

      // Extract label texts and filter by confidence
      final categories = labels
          .where((label) => label.confidence >= 0.5) // 50% confidence minimum
          .map((label) {
            final confidence = (label.confidence * 100).toStringAsFixed(1);
            print('  📌 Detected: ${label.label} ($confidence% confidence)');
            return label.label;
          })
          .take(5) // Take top 5 labels
          .toList();

      print('Final categories: $categories');
      return categories;
    } catch (e) {
      print('❌ Error classifying image: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  Future<List<String>> classifyMultipleImages(List<File> images) async {
    if (images.isEmpty) return [];

    print('Classifying ${images.length} images...');
    Set<String> allCategories = {};

    for (var image in images) {
      final categories = await classifyImage(image);
      allCategories.addAll(categories);
    }

    print('Total unique categories: ${allCategories.length}');
    // Return unique categories, limited to top 10
    return allCategories.take(10).toList();
  }

  void dispose() {
    if (_isInitialized && _imageLabeler != null) {
      print('Disposing ML Kit Image Labeler...');
      _imageLabeler!.close();
      _isInitialized = false;
      print('✅ ML Kit disposed');
    }
  }
}