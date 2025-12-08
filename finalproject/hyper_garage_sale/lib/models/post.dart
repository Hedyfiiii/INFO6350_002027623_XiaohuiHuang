class Post {
  final String id;
  final String userId;
  final String title;
  final double price;
  final String description;
  final DateTime createdAt;
  final List<String> imageUrls;
  final List<String> categories; // New field for ML classifications

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.price,
    required this.description,
    required this.createdAt,
    this.imageUrls = const [],
    this.categories = const [], // Default empty list
  });

  // Convert Post to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'price': price,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'imageUrls': imageUrls,
      'categories': categories, // Include in Firestore
    };
  }

  // Create Post from Firestore Map
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      categories: List<String>.from(map['categories'] ?? []), // Parse categories
    );
  }

  // Copy with method for updating
  Post copyWith({
    String? id,
    String? userId,
    String? title,
    double? price,
    String? description,
    DateTime? createdAt,
    List<String>? imageUrls,
    List<String>? categories,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      imageUrls: imageUrls ?? this.imageUrls,
      categories: categories ?? this.categories,
    );
  }
}