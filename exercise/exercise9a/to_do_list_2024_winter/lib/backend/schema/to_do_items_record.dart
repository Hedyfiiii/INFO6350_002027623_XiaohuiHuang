import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'index.dart';

class ToDoItemsRecord extends FirestoreRecord {
  
  ToDoItemsRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "Title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "Description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "DueDate" field.
  DateTime? _dueDate;
  DateTime? get dueDate => _dueDate;
  bool hasDueDate() => _dueDate != null;

  // "ImageURL" field.
  String? _imageURL;
  String get imageURL => _imageURL ?? '';
  bool hasImageURL() => _imageURL != null;

  // "Address" field.
  String? _address;
  String get address => _address ?? '';
  bool hasAddress() => _address != null;

  // "Latitude" field.
  double? _latitude;
  double? get latitude => _latitude;
  bool hasLatitude() => _latitude != null;

  // "Longitude" field.
  double? _longitude;
  double? get longitude => _longitude;
  bool hasLongitude() => _longitude != null;

  void _initializeFields() {
    _title = snapshotData['Title'] as String?;
    _description = snapshotData['Description'] as String?;
    _dueDate = snapshotData['DueDate'] as DateTime?;
    _imageURL = snapshotData['ImageURL'] as String?;
    _address = snapshotData['Address'] as String?;

    final latValue = snapshotData['Latitude'];
  _latitude = latValue is num ? latValue.toDouble() : null;
  
  final lngValue = snapshotData['Longitude'];
  _longitude = lngValue is num ? lngValue.toDouble() : null;
  }

  static CollectionReference get collection =>
    FirebaseFirestore.instance.collection('ToDoItems');

  static Stream<ToDoItemsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ToDoItemsRecord.fromSnapshot(s));

  static Future<ToDoItemsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ToDoItemsRecord.fromSnapshot(s));

  static ToDoItemsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ToDoItemsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ToDoItemsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ToDoItemsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() => 'ToDoItemsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ToDoItemsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createToDoItemsRecordData({
  String? title,
  String? description,
  DateTime? dueDate,
  String? imageURL,
  String? address,
  double? latitude,
  double? longitude,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'Title': title,
      'Description': description,
      'DueDate': dueDate,
      'ImageURL': imageURL,
      'Address': address,
      'Latitude': latitude,
      'Longitude': longitude,
    }.withoutNulls,
  );

  return firestoreData;
}

class ToDoItemsRecordDocumentEquality implements Equality<ToDoItemsRecord> {
  const ToDoItemsRecordDocumentEquality();

  @override
  bool equals(ToDoItemsRecord? e1, ToDoItemsRecord? e2) {
    return e1?.title == e2?.title &&
        e1?.description == e2?.description &&
        e1?.dueDate == e2?.dueDate &&
        e1?.imageURL == e2?.imageURL &&
        e1?.address == e2?.address &&
        e1?.latitude == e2?.latitude &&
        e1?.longitude == e2?.longitude;
  }

  @override
  int hash(ToDoItemsRecord? e) => const ListEquality().hash([
        e?.title,
        e?.description,
        e?.dueDate,
        e?.imageURL,
        e?.address,
        e?.latitude,
        e?.longitude,
      ]);

  @override
  bool isValidKey(Object? o) => o is ToDoItemsRecord;
}