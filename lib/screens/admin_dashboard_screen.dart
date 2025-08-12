import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../widgets/countdown_timer.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // TODO: 추후 이 목록을 Firestore나 다른 중앙 관리 지점에서 가져오도록 개선해야 합니다.
  final List<String> _masterTeamEmails = const [
    'kseun@youngjin.com',
    'jisooda@youngjin.com',
    'parkjonghyun@youngjin.com',
    'leechan@youngjin.com',
    'parkjiwon@youngjin.com',
    'ksj@youngjin.com',
  ];

  final Map<String, String> _reasonKeyToDisplay = const {
    'not_feeling_well': '요즘 컨디션이 좀 안 좋아서요 😷',
    'on_a_diet': '식단 조절 중이라서요 🍽️',
    'has_other_plans': '이미 다른 일정이 있어요 📆',
    'needs_rest': '잠깐 쉬는 시간이 필요해서요 💤',
    'personal_reasons': '개인 사정이 있어서요 🙇‍♀️🙇‍♂️',
    'direct_input': '기타 (직접 입력)',
  };

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('참여 현황 대시보드'),
        actions: [
          const CountdownTimer(),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getAllUsersStream(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (usersSnapshot.hasError) {
            return Center(
                child: Text('사용자 정보를 불러오는데 실패했습니다: ${usersSnapshot.error}'));
          }

          final allUsersDocs = usersSnapshot.data?.docs ?? [];
          final Map<String, String> emailToUserId = {
            for (var doc in allUsersDocs)
              (doc.data() as Map<String, dynamic>)['email']: doc.id
          };
          final Map<String, String> userIdToName = {
            for (var doc in allUsersDocs)
              doc.id: (doc.data() as Map<String, dynamic>)['name'] ?? '이름없음'
          };

          return StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getParticipationStream(),
            builder: (context, participationSnapshot) {
              if (participationSnapshot.hasError) {
                return Center(
                    child: Text(
                        '참여 정보를 불러오는데 실패했습니다: ${participationSnapshot.error}'));
              }

              final participants = participationSnapshot.data?.docs ?? [];
              final Map<String, Map<String, dynamic>> participationData = {
                for (var doc in participants)
                  doc.id: doc.data() as Map<String, dynamic>
              };

              final List<Widget> participatingUsers = [];
              final List<Widget> notParticipatingUsers = [];
              final List<Widget> noResponseUsers = [];

              for (var email in _masterTeamEmails) {
                final userId = emailToUserId[email];
                final userName =
                    userId != null ? userIdToName[userId] : email.split('@')[0];
                final data = userId != null ? participationData[userId] : null;
                final status = data?['participating'] as bool?;

                if (status == true) {
                  participatingUsers.add(ListTile(
                    title: Text(userName ?? email.split('@')[0]),
                    leading: const Icon(Icons.person_outline),
                  ));
                } else if (status == false) {
                  final reasonKey = data?['nonParticipationReason'] as String?;
                  String? reasonText =
                      reasonKey != null ? _reasonKeyToDisplay[reasonKey] : null;
                  if (reasonKey == 'direct_input') {
                    reasonText =
                        data?['nonParticipationReasonCustom'] as String?;
                  }

                  notParticipatingUsers.add(ListTile(
                    title: Text(userName ?? email.split('@')[0]),
                    subtitle: reasonText != null
                        ? Text(
                            reasonText,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          )
                        : null,
                    leading: const Icon(Icons.person_outline),
                  ));
                } else {
                  noResponseUsers.add(ListTile(
                    title: Text(userName ?? email.split('@')[0]),
                    leading: const Icon(Icons.person_outline),
                  ));
                }
              }

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildStatusSection(context, '참여', participatingUsers),
                  _buildStatusSection(context, '불참', notParticipatingUsers),
                  _buildStatusSection(context, '미응답', noResponseUsers),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(
      BuildContext context, String title, List<Widget> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title (${users.length}명)',
            style: Theme.of(context).textTheme.headlineSmall),
        const Divider(),
        if (users.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('...'),
          )
        else
          ...users,
        const SizedBox(height: 24),
      ],
    );
  }
}
