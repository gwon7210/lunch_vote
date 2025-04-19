import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirestoreService() {
    // 오프라인 지속성 활성화
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // 현재 월의 이벤트 문서 ID를 반환
  String get _currentMonthEventId {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // 참여 여부 저장
  Future<void> setParticipation(bool isParticipating) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final eventRef = _firestore.collection('events').doc(_currentMonthEventId);
    final participantsRef = eventRef.collection('participants').doc(userId);

    await participantsRef.set({
      'participating': isParticipating,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!isParticipating) {
      // 참여하지 않는 경우 투표 내역 삭제
      await eventRef.collection('votes').doc(userId).delete();
    }
  }

  // 참여 여부 조회
  Future<bool?> getParticipation() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final doc = await _firestore
        .collection('events')
        .doc(_currentMonthEventId)
        .collection('participants')
        .doc(userId)
        .get();

    return doc.data()?['participating'] as bool?;
  }

  // 식당 추천 추가
  Future<void> addRecommendation(
      String restaurantName, String restaurantLink) async {
    final eventRef = _firestore.collection('events').doc(_currentMonthEventId);
    await eventRef.collection('recommendations').add({
      'name': restaurantName,
      'link': restaurantLink,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 추천 리스트 스트림
  Stream<QuerySnapshot> getRecommendationsStream() {
    return _firestore
        .collection('events')
        .doc(_currentMonthEventId)
        .collection('recommendations')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 투표 저장
  Future<void> setVotes(List<String> restaurantIds) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final eventRef = _firestore.collection('events').doc(_currentMonthEventId);
    await eventRef.collection('votes').doc(userId).set({
      'restaurantIds': restaurantIds,
      'votedAt': FieldValue.serverTimestamp(),
    });
  }

  // 투표 결과 스트림
  Stream<QuerySnapshot> getVotesStream() {
    return _firestore
        .collection('events')
        .doc(_currentMonthEventId)
        .collection('votes')
        .snapshots();
  }
}
