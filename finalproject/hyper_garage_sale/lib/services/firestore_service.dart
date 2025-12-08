import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new post
  Future<void> createPost(Post post) async {
    try {
      await _db.collection('posts').doc(post.id).set(post.toMap());
    } catch (e) {
      throw 'Failed to create post: $e';
    }
  }

  // Get all posts as a stream
  Stream<List<Post>> getAllPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Post.fromMap(doc.data());
      }).toList();
    });
  }

  // Get posts by user ID
  Stream<List<Post>> getUserPosts(String userId) {
    return _db
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Post.fromMap(doc.data());
      }).toList();
    });
  }

  // Get a single post
  Future<Post?> getPost(String postId) async {
    try {
      final doc = await _db.collection('posts').doc(postId).get();
      if (doc.exists) {
        return Post.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Failed to get post: $e';
    }
  }

  // Update a post
  Future<void> updatePost(Post post) async {
    try {
      await _db.collection('posts').doc(post.id).update(post.toMap());
    } catch (e) {
      throw 'Failed to update post: $e';
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _db.collection('posts').doc(postId).delete();
    } catch (e) {
      throw 'Failed to delete post: $e';
    }
  }

  // Search posts by title
  Stream<List<Post>> searchPosts(String query) {
    return _db
        .collection('posts')
        .orderBy('title')
        .startAt([query])
        .endAt(['$query'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Post.fromMap(doc.data());
      }).toList();
    });
  }
}