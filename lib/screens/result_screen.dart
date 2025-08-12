import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../widgets/countdown_timer.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('투표 결과'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/vote'),
        ),
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
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: context.read<FirestoreService>().getVotesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('에러가 발생했습니다: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 투표 결과 집계
          final votes = snapshot.data?.docs ?? [];
          final voteCounts = <String, int>{};
          final restaurantVoters = <String, Map<String, String>>{}; // userId와 userName을 저장

          for (final vote in votes) {
            final userId = vote.id;
            final data = vote.data() as Map<String, dynamic>;
            if (!data.containsKey('restaurantIds')) continue;
            
            final restaurantIds = data['restaurantIds'] as List<dynamic>;
            final userName = data['userName'] as String? ?? '알 수 없음';
            
            for (final restaurantId in restaurantIds) {
              voteCounts[restaurantId] = (voteCounts[restaurantId] ?? 0) + 1;
              restaurantVoters[restaurantId] = {
                ...(restaurantVoters[restaurantId] ?? {}),
                userId: userName,
              };
            }
          }

          // 득표순으로 정렬
          final sortedResults = voteCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          if (sortedResults.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.how_to_vote,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '아직 투표가 진행되지 않았습니다.\n투표 화면으로 이동하여 참여해주세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedResults.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // 헤더
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.workspace_premium,
                            size: 80,
                            color: Color(0xFFFFD700),
                          ),
                          Positioned(
                            top: 20,
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sortedResults[0].key,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${sortedResults[0].value}표',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final resultIndex = index - 1;
              final result = sortedResults[resultIndex];
              final rank = resultIndex + 1;
              final voters = restaurantVoters[result.key] ?? {};

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onLongPress: () {
                    if (voters.isEmpty) return;
                    
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('${result.key} 투표자'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: voters.entries
                              .map((entry) => Text(entry.value))
                              .toList(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('닫기'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Tooltip(
                    message: '길게 누르면 투표자 목록 보기',
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: rank == 2
                            ? const Color(0xFFC0C0C0)
                            : rank == 3
                                ? const Color(0xFFCD7F32)
                                : Colors.grey[300],
                        child: Text(
                          rank.toString(),
                          style: TextStyle(
                            color: rank <= 3
                                ? Theme.of(context).colorScheme.onPrimary
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        result.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${result.value}표',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
