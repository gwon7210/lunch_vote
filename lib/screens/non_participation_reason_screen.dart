import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';

class NonParticipationReasonScreen extends StatefulWidget {
  const NonParticipationReasonScreen({super.key});

  @override
  State<NonParticipationReasonScreen> createState() =>
      _NonParticipationReasonScreenState();
}

class _NonParticipationReasonScreenState
    extends State<NonParticipationReasonScreen> {
  String? _selectedReason;
  bool _isSubmitting = false;
  final _customReasonController = TextEditingController();

  final Map<String, String> _reasons = {
    '요즘 컨디션이 좀 안 좋아서요 😷': 'not_feeling_well',
    '식단 조절 중이라서요 🍽️': 'on_a_diet',
    '이미 다른 일정이 있어요 📆': 'has_other_plans',
    '잠깐 쉬는 시간이 필요해서요 💤': 'needs_rest',
    '개인 사정이 있어서요 🙇‍♀️🙇‍♂️': 'personal_reasons',
    '기타 (직접 입력)': 'direct_input',
  };

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _submitReason() async {
    if (_selectedReason == null) return;
    if (_selectedReason == '기타 (직접 입력)' &&
        _customReasonController.text.trim().isEmpty) {
      // 직접 입력 선택 시, 내용이 비어있으면 제출 비활성화
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기타 사유를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final firestoreService = context.read<FirestoreService>();
    final reasonKey = _reasons[_selectedReason!]!;
    final customReason = reasonKey == 'direct_input'
        ? _customReasonController.text.trim()
        : null;

    await firestoreService.setNonParticipationReason(reasonKey,
        customReason: customReason);

    // 로직 처리 후 최종 화면으로 이동
    if (mounted) {
      context.go('/not-participating');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('불참 사유 선택'),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '괜찮으시다면, 회식에 참여하지 못하는 이유를 알려주실 수 있을까요?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ..._reasons.keys.map((reason) {
              return Card(
                color: _selectedReason == reason
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                child: ListTile(
                  title: Text(reason),
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                    });
                  },
                  selected: _selectedReason == reason,
                ),
              );
            }).toList(),
            if (_selectedReason == '기타 (직접 입력)')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextField(
                  controller: _customReasonController,
                  decoration: const InputDecoration(
                    labelText: '기타 사유를 입력해주세요',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedReason == null || _isSubmitting
                  ? null
                  : _submitReason,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('제출하기'),
            ),
          ],
        ),
      ),
    );
  }
}
