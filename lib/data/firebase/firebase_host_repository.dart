import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unite_india_app/core/domain/host.dart';
import 'package:unite_india_app/core/repositories/host_repository.dart';

class FirebaseHostRepository implements HostRepository {
  FirebaseHostRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('hosts');

  @override
  Future<void> saveHostProfile({
    required String displayName,
    required String areaLabel,
    required List<int> selectedSectors,
  }) async {
    await _collection.add({
      'displayName': displayName,
      'areaLabel': areaLabel,
      'sectors': selectedSectors,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<HostProfile>> listHostProfiles() async {
    final snapshot =
        await _collection.orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final timestamp = data['timestamp'];
      return HostProfile(
        id: doc.id,
        displayName: (data['displayName'] ?? '') as String,
        areaLabel: (data['areaLabel'] ?? '') as String,
        selectedSectors:
            List<int>.from((data['sectors'] as List<dynamic>? ?? <dynamic>[])
                .map((e) => e as int)),
        createdAt: timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }
}

