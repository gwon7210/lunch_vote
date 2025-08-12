import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../widgets/countdown_timer.dart';

class DateSelectionScreen extends StatefulWidget {
  const DateSelectionScreen({super.key});

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  final Map<DateTime, Set<String>> _selectedDateMeals = {};
  bool _isSubmitting = false;

  final List<DateTime> _selectableDates = [
    DateTime(DateTime.now().year, 8, 18),
    DateTime(DateTime.now().year, 8, 19),
    DateTime(DateTime.now().year, 8, 20),
    DateTime(DateTime.now().year, 8, 21),
    DateTime(DateTime.now().year, 8, 22),
    DateTime(DateTime.now().year, 8, 25),
    DateTime(DateTime.now().year, 8, 26),
    DateTime(DateTime.now().year, 8, 27),
    DateTime(DateTime.now().year, 8, 28),
    DateTime(DateTime.now().year, 8, 29),
  ];

  Map<DateTime, Map<String, int>> _dateMealVoteCounts = {};
  Map<DateTime, Map<String, List<String>>> _dateMealVoters = {};
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadSelectedDates();
    _loadDateMealVoteCounts();
    _loadDateMealVoters();
  }

  Future<void> _loadSelectedDates() async {
    final firestoreService = context.read<FirestoreService>();
    final dateMeals = await firestoreService.getSelectedDates();
    if (mounted) {
      setState(() {
        _selectedDateMeals.addAll(dateMeals);
      });
    }
  }

  void _loadDateMealVoteCounts() {
    final firestoreService = context.read<FirestoreService>();
    firestoreService.getDateMealVoteCounts().listen((voteCounts) {
      if (mounted) {
        setState(() {
          _dateMealVoteCounts = Map<DateTime, Map<String, int>>.from(voteCounts);
        });
      }
    });
  }

  Future<void> _loadDateMealVoters() async {
    final firestoreService = context.read<FirestoreService>();
    final dateMealVoters = await firestoreService.getDateMealVoters();
    if (mounted) {
      setState(() {
        _dateMealVoters = dateMealVoters;
      });
      // 모든 사용자 이름 미리 로드
      for (final mealVoters in dateMealVoters.values) {
        for (final voters in mealVoters.values) {
          for (final userId in voters) {
            _loadUserName(userId);
          }
        }
      }
    }
  }

  Future<void> _loadUserName(String userId) async {
    if (_userNames.containsKey(userId)) return;

    final firestoreService = context.read<FirestoreService>();
    final userName = await firestoreService.getUserName(userId);
    if (mounted) {
      setState(() {
        _userNames[userId] = userName;
      });
    }
  }

  void _showVotersDialog(DateTime date, String meal) {
    final mealVoters = _dateMealVoters[date];
    if (mealVoters == null) return;
    
    final voters = mealVoters[meal] ?? [];
    if (voters.isEmpty) return;

    final mealText = meal == 'lunch' ? '점심' : '저녁';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${date.month}월 ${date.day}일 ${mealText} 투표자'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: voters.map((userId) {
            return Text(_userNames[userId] ?? '알 수 없음');
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _toggleMeal(DateTime date, String meal) {
    setState(() {
      if (!_selectedDateMeals.containsKey(date)) {
        _selectedDateMeals[date] = <String>{};
      }
      
      if (_selectedDateMeals[date]!.contains(meal)) {
        _selectedDateMeals[date]!.remove(meal);
        if (_selectedDateMeals[date]!.isEmpty) {
          _selectedDateMeals.remove(date);
        }
      } else {
        _selectedDateMeals[date]!.add(meal);
      }
    });
  }

  Future<void> _submitDates() async {
    if (_selectedDateMeals.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final firestoreService = context.read<FirestoreService>();
      await firestoreService.setSelectedDates(_selectedDateMeals);

      if (mounted) {
        context.go('/vote');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('날짜 선택'),
        actions: [
          const CountdownTimer(),
          const SizedBox(width: 8),
          // 관리자 대시보드 아이콘
          if (context.read<FirestoreService>().isAdmin())
            IconButton(
              icon: const Icon(Icons.dashboard_customize_outlined),
              tooltip: '관리자 대시보드',
              onPressed: () => context.go('/admin-dashboard'),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 안내 메시지 추가
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '최대한 가능한 날짜를 여러개 선택해주세요!',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 지원 금액 정보 툴팁
                Tooltip(
                  message: '점심 15,000원,\n저녁 50,000원 지원!',
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _selectableDates.length,
              itemBuilder: (context, index) {
                final date = _selectableDates[index];
                final selectedMeals = _selectedDateMeals[date] ?? <String>{};
                final isLunchSelected = selectedMeals.contains('lunch');
                final isDinnerSelected = selectedMeals.contains('dinner');
                final voteCounts = _dateMealVoteCounts[date] ?? {'lunch': 0, 'dinner': 0};

                return RepaintBoundary(
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isLunchSelected || isDinnerSelected)
                          ? Theme.of(context)
                              .primaryColor
                              .withOpacity(0.1 + ((voteCounts['lunch']! + voteCounts['dinner']!) * 0.05))
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: (isLunchSelected || isDinnerSelected)
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // 날짜 표시
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                          child: Text(
                            '${date.month}월 ${date.day}일',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // 점심 선택 영역
                        Expanded(
                          child: InkWell(
                            onTap: () => _toggleMeal(date, 'lunch'),
                            onLongPress: () => _showVotersDialog(date, 'lunch'),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isLunchSelected
                                    ? Theme.of(context).primaryColor.withOpacity(0.3)
                                    : Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isLunchSelected ? Icons.check_circle : Icons.circle_outlined,
                                    color: isLunchSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '점심',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${voteCounts['lunch']}명',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // 저녁 선택 영역
                        Expanded(
                          child: InkWell(
                            onTap: () => _toggleMeal(date, 'dinner'),
                            onLongPress: () => _showVotersDialog(date, 'dinner'),
                            child: Container(
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isDinnerSelected ? Icons.check_circle : Icons.circle_outlined,
                                    color: isDinnerSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '저녁',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${voteCounts['dinner']}명',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '선택된 날짜: ${_selectedDateMeals.length}개',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting || _selectedDateMeals.isEmpty
                          ? null
                          : _submitDates,
                      icon: const Icon(Icons.check),
                      label: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('선택 완료'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
