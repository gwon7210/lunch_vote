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

    // 사용자 이름 가져오기
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] as String? ?? '알 수 없음';

    final eventRef = _firestore.collection('events').doc(_currentMonthEventId);
    await eventRef.collection('votes').doc(userId).set({
      'restaurantIds': restaurantIds,
      'userName': userName, // 사용자 이름 저장
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

  // 선택한 날짜 저장
  Future<void> setSelectedDates(List<DateTime> dates) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final eventRef = _firestore.collection('events').doc(_currentMonthEventId);
    final datesRef = eventRef.collection('dates').doc(userId);

    await datesRef.set({
      'dates': dates.map((date) => Timestamp.fromDate(date)).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 선택한 날짜 조회
  Future<List<DateTime>> getSelectedDates() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final doc = await _firestore
        .collection('events')
        .doc(_currentMonthEventId)
        .collection('dates')
        .doc(userId)
        .get();

    final timestamps = doc.data()?['dates'] as List<dynamic>? ?? [];
    return timestamps
        .map((timestamp) => (timestamp as Timestamp).toDate())
        .toList();
  }

  // 날짜별 투표 수 조회
  Stream<Map<DateTime, int>> getDateVoteCounts() {
    return _firestore
        .collection('events')
        .doc(_currentMonthEventId)
        .collection('dates')
        .snapshots()
        .map((snapshot) {
      final voteCounts = <DateTime, int>{};

      for (final doc in snapshot.docs) {
        final dates = doc.data()['dates'] as List<dynamic>;
        for (final timestamp in dates) {
          final date = (timestamp as Timestamp).toDate();
          voteCounts[date] = (voteCounts[date] ?? 0) + 1;
        }
      }

      return voteCounts;
    });
  }

  // 날짜별 투표한 사람들 조회
  Future<Map<DateTime, List<String>>> getDateVoters() async {
    final snapshot = await _firestore
        .collection('events')
        .doc(_currentMonthEventId)
        .collection('dates')
        .get();

    final dateVoters = <DateTime, List<String>>{};

    for (final doc in snapshot.docs) {
      final userId = doc.id;
      final dates = doc.data()['dates'] as List<dynamic>;
      for (final timestamp in dates) {
        final date = (timestamp as Timestamp).toDate();
        dateVoters[date] = [...(dateVoters[date] ?? []), userId];
      }
    }

    return dateVoters;
  }

  // 식당별 투표한 사람들 조회
  Future<Map<String, List<String>>> getRestaurantVoters() async {
    final snapshot = await _firestore
        .collection('events')
        .doc(_currentMonthEventId)
        .collection('votes')
        .get();

    final restaurantVoters = <String, List<String>>{};

    for (final doc in snapshot.docs) {
      final userId = doc.id;
      final restaurantIds = doc.data()['restaurantIds'] as List<dynamic>;
      for (final restaurantId in restaurantIds) {
        restaurantVoters[restaurantId] = [
          ...(restaurantVoters[restaurantId] ?? []),
          userId
        ];
      }
    }

    return restaurantVoters;
  }

  // 사용자 이름 조회
  Future<String> getUserName(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['name'] as String? ?? '알 수 없음';
  }

  // 모든 사용자 정보 스트림
  Stream<QuerySnapshot> getAllUsersStream() {
    return _firestore.collection('users').snapshots();
  }

  // 현재 월의 참여 정보 스트림
  Stream<QuerySnapshot> getParticipationStream() {
    return _firestore
        .collection('events')
        .doc(_currentMonthEventId)
        .collection('participants')
        .snapshots();
  }

  // 불참 사유 저장
  Future<void> setNonParticipationReason(String reason,
      {String? customReason}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final eventRef = _firestore.collection('events').doc(_currentMonthEventId);
    final participantsRef = eventRef.collection('participants').doc(userId);

    final dataToUpdate = <String, dynamic>{
      'nonParticipationReason': reason,
    };

    if (customReason != null) {
      dataToUpdate['nonParticipationReasonCustom'] = customReason;
    }

    await participantsRef.update(dataToUpdate);
  }
}
