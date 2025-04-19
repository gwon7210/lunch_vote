import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

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

          for (final vote in votes) {
            final restaurantIds = vote['restaurantIds'] as List<dynamic>;
            for (final restaurantId in restaurantIds) {
              voteCounts[restaurantId] = (voteCounts[restaurantId] ?? 0) + 1;
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
                    '아직 투표 결과가 없습니다.\n투표에 참여해주세요!',
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
            itemCount: sortedResults.length + 1, // 헤더를 위해 +1
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
                            color: Color(0xFFFFD700), // 금색
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
                          color: Color(0xFFFFD700), // 금색
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

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: rank == 2
                        ? const Color(0xFFC0C0C0) // 은색
                        : rank == 3
                            ? const Color(0xFFCD7F32) // 동색
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
              );
            },
          );
        },
      ),
    );
  }
}
