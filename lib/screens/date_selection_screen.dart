import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class DateSelectionScreen extends StatefulWidget {
  const DateSelectionScreen({super.key});

  @override
  State<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends State<DateSelectionScreen> {
  final Set<DateTime> _selectedDates = {};
  bool _isSubmitting = false;
  final DateTime _startDate = DateTime(2025, 4, 22);
  final DateTime _endDate = DateTime(2025, 4, 30);
  Map<DateTime, int> _dateVoteCounts = {};
  Map<DateTime, List<String>> _dateVoters = {};
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadSelectedDates();
    _loadDateVoteCounts();
    _loadDateVoters();
  }

  Future<void> _loadSelectedDates() async {
    final firestoreService = context.read<FirestoreService>();
    final dates = await firestoreService.getSelectedDates();
    if (mounted) {
      setState(() {
        _selectedDates.addAll(dates);
      });
    }
  }

  void _loadDateVoteCounts() {
    final firestoreService = context.read<FirestoreService>();
    firestoreService.getDateVoteCounts().listen((voteCounts) {
      if (mounted) {
        setState(() {
          _dateVoteCounts = Map<DateTime, int>.from(voteCounts);
        });
      }
    });
  }

  Future<void> _loadDateVoters() async {
    final firestoreService = context.read<FirestoreService>();
    final dateVoters = await firestoreService.getDateVoters();
    if (mounted) {
      setState(() {
        _dateVoters = dateVoters;
      });
      // 모든 사용자 이름 미리 로드
      for (final voters in dateVoters.values) {
        for (final userId in voters) {
          _loadUserName(userId);
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

  void _showVotersDialog(DateTime date) {
    final voters = _dateVoters[date] ?? [];
    if (voters.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${date.month}월 ${date.day}일 투표자'),
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

  Future<void> _submitDates() async {
    if (_selectedDates.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final firestoreService = context.read<FirestoreService>();
      await firestoreService.setSelectedDates(_selectedDates.toList());

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
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _endDate.difference(_startDate).inDays + 1,
              itemBuilder: (context, index) {
                final date = _startDate.add(Duration(days: index));
                final isSelected = _selectedDates.contains(date);
                final voteCount = _dateVoteCounts[date] ?? 0;

                return RepaintBoundary(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDates.remove(date);
                        } else {
                          _selectedDates.add(date);
                        }
                      });
                    },
                    onLongPress: () => _showVotersDialog(date),
                    child: Tooltip(
                      message: '길게 누르면 투표자 목록 보기',
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.1 + (voteCount * 0.1))
                              : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.month}월 ${date.day}일',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${voteCount}명',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    '선택된 날짜: ${_selectedDates.length}개',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting || _selectedDates.isEmpty
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