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

  // 관리자 권한 확인
  bool isAdmin() {
    final user = _auth.currentUser;
    if (user?.email == null) return false;
    
    final adminEmails = [
      'kseun@youngjin.com',
      'jisooda@youngjin.com',
      'parkjonghyun@youngjin.com',
      'leechan@youngjin.com',
      'parkjiwon@youngjin.com',
      'ksj@youngjin.com',
      'daeho0914@youngjin.com'
    ];
    
    return adminEmails.contains(user!.email);
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

  // 선택한 날짜 저장 (점심/저녁 구분)
  Future<void> setSelectedDates(Map<DateTime, Set<String>> dateMeals) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final eventRef = _firestore.collection('events').doc(_currentMonthEventId);
    final datesRef = eventRef.collection('dates').doc(userId);

    // 날짜별로 점심/저녁 정보를 저장
    final datesData = <String, List<String>>{};
    for (final entry in dateMeals.entries) {
      final dateKey = '${entry.key.year}-${entry.key.month.toString().padLeft(2, '0')}-${entry.key.day.toString().padLeft(2, '0')}';
      datesData[dateKey] = entry.value.toList();
    }

    await datesRef.set({
      'dateMeals': datesData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 선택한 날짜 조회 (점심/저녁 구분)
  Future<Map<DateTime, Set<String>>> getSelectedDates() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    final doc = await _firestore
        .collection('events')
        .doc(_currentMonthEventId)
        .collection('dates')
        .doc(userId)
        .get();

    final dateMealsData = doc.data()?['dateMeals'] as Map<String, dynamic>? ?? {};
    final result = <DateTime, Set<String>>{};

    for (final entry in dateMealsData.entries) {
      final dateParts = entry.key.split('-');
      final date = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );
      final meals = (entry.value as List<dynamic>).cast<String>().toSet();
      result[date] = meals;
    }

    return result;
  }

  // 날짜별 점심/저녁 투표 수 조회
  Stream<Map<DateTime, Map<String, int>>> getDateMealVoteCounts() {
    return _firestore
        .collection('events')
        .doc(_currentMonthEventId)
        .collection('dates')
        .snapshots()
        .map((snapshot) {
      final voteCounts = <DateTime, Map<String, int>>{};

      for (final doc in snapshot.docs) {
        final dateMealsData = doc.data()['dateMeals'] as Map<String, dynamic>? ?? {};
        
        for (final entry in dateMealsData.entries) {
          final dateParts = entry.key.split('-');
          final date = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
          
          final meals = (entry.value as List<dynamic>).cast<String>();
          
          if (!voteCounts.containsKey(date)) {
            voteCounts[date] = {'lunch': 0, 'dinner': 0};
          }
          
          for (final meal in meals) {
            if (voteCounts[date]!.containsKey(meal)) {
              voteCounts[date]![meal] = (voteCounts[date]![meal] ?? 0) + 1;
            }
          }
        }
      }

      return voteCounts;
    });
  }

  // 날짜별 점심/저녁 투표한 사람들 조회
  Future<Map<DateTime, Map<String, List<String>>>> getDateMealVoters() async {
    final snapshot = await _firestore
        .collection('events')
        .doc(_currentMonthEventId)
        .collection('dates')
        .get();

    final dateMealVoters = <DateTime, Map<String, List<String>>>{};

    for (final doc in snapshot.docs) {
      final userId = doc.id;
      final dateMealsData = doc.data()['dateMeals'] as Map<String, dynamic>? ?? {};
      
      for (final entry in dateMealsData.entries) {
        final dateParts = entry.key.split('-');
        final date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
        
        final meals = (entry.value as List<dynamic>).cast<String>();
        
        if (!dateMealVoters.containsKey(date)) {
          dateMealVoters[date] = {'lunch': [], 'dinner': []};
        }
        
        for (final meal in meals) {
          if (dateMealVoters[date]!.containsKey(meal)) {
            dateMealVoters[date]![meal] = [...dateMealVoters[date]![meal]!, userId];
          }
        }
      }
    }

    return dateMealVoters;
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

  // 날짜별 투표 수 조회 (기존 호환성)
  Stream<Map<DateTime, int>> getDateVoteCounts() {
    return getDateMealVoteCounts().map((dateMealCounts) {
      final voteCounts = <DateTime, int>{};
      for (final entry in dateMealCounts.entries) {
        voteCounts[entry.key] = (entry.value['lunch'] ?? 0) + (entry.value['dinner'] ?? 0);
      }
      return voteCounts;
    });
  }

  // 날짜별 투표한 사람들 조회 (기존 호환성)
  Future<Map<DateTime, List<String>>> getDateVoters() async {
    final dateMealVoters = await getDateMealVoters();
    final dateVoters = <DateTime, List<String>>{};
    
    for (final entry in dateMealVoters.entries) {
      final allVoters = <String>{};
      for (final mealVoters in entry.value.values) {
        allVoters.addAll(mealVoters);
      }
      dateVoters[entry.key] = allVoters.toList();
    }
    
    return dateVoters;
  }
}
