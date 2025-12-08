import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a single image
  Future<String> uploadImage(File file, String postId, int index) async {
    try {
      final fileName = '${postId}_$index.jpg';
      final ref = _storage.ref().child('posts/$postId/$fileName');
      
      // Upload with metadata
      await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(List<File> files, String postId) async {
    List<String> urls = [];
    
    for (int i = 0; i < files.length; i++) {
      final url = await uploadImage(files[i], postId, i);
      urls.add(url);
    }
    
    return urls;
  }

  // Delete all images for a post
  Future<void> deletePostImages(String postId) async {
    try {
      final ref = _storage.ref().child('posts/$postId');
      final listResult = await ref.listAll();
      
      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      throw 'Failed to delete images: $e';
    }
  }

  // Delete a single image
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw 'Failed to delete image: $e';
    }
  }
}