import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final _nameController = TextEditingController();
  final _linkController = TextEditingController();
  final Set<String> _selectedRestaurants = {};
  bool _isSubmitting = false;
  bool _isAddingRecommendation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _addRecommendation() async {
    final restaurantName = _nameController.text.trim();
    final restaurantLink = _linkController.text.trim();
    if (restaurantName.isEmpty || restaurantLink.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final firestoreService = context.read<FirestoreService>();
      await firestoreService.addRecommendation(restaurantName, restaurantLink);
      _nameController.clear();
      _linkController.clear();
      setState(() {
        _isAddingRecommendation = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _submitVotes() async {
    if (_selectedRestaurants.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final firestoreService = context.read<FirestoreService>();
      await firestoreService.setVotes(_selectedRestaurants.toList());

      if (mounted) {
        context.go('/result');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<String> _shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return Future.value(uri.host);
    } catch (e) {
      return Future.value(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식당 추천 및 투표'),
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
          if (_isAddingRecommendation)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.restaurant, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        '새로운 식당 추천하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _isAddingRecommendation = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '식당 이름',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      labelText: '식당 링크 (네이버/카카오맵 등)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _addRecommendation,
                      icon: const Icon(Icons.add),
                      label: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('추천하기'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isAddingRecommendation = true;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('새로운 식당 추천하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.how_to_vote, size: 24),
                SizedBox(width: 8),
                Text(
                  '투표하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '원하는 식당을 모두 선택한 후 투표 완료 버튼을 눌러주세요.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  context.read<FirestoreService>().getRecommendationsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('에러가 발생했습니다: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final recommendations = snapshot.data?.docs ?? [];
                final restaurantNames = recommendations
                    .map((doc) => doc['name'] as String)
                    .toSet()
                    .toList()
                  ..sort();

                if (restaurantNames.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '아직 추천된 식당이 없습니다.\n새로운 식당을 추천해보세요!',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: restaurantNames.length,
                  itemBuilder: (context, index) {
                    final restaurantName = restaurantNames[index];
                    final recommendation = recommendations.firstWhere(
                      (doc) => doc['name'] == restaurantName,
                    );
                    final restaurantLink =
                        recommendation['link'] as String? ?? '링크 없음';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: restaurantLink != '링크 없음'
                            ? () => _launchUrl(restaurantLink)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurantName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (restaurantLink != '링크 없음') ...[
                                      const SizedBox(height: 4),
                                      FutureBuilder<String>(
                                        future: _shortenUrl(restaurantLink),
                                        builder: (context, snapshot) {
                                          return Text(
                                            snapshot.data ?? restaurantLink,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontSize: 14,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: _selectedRestaurants
                                        .contains(restaurantName)
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      if (_selectedRestaurants
                                          .contains(restaurantName)) {
                                        _selectedRestaurants
                                            .remove(restaurantName);
                                      } else {
                                        _selectedRestaurants
                                            .add(restaurantName);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).primaryColor,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _selectedRestaurants
                                                  .contains(restaurantName)
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: _selectedRestaurants
                                                  .contains(restaurantName)
                                              ? Colors.white
                                              : Theme.of(context).primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedRestaurants
                                                  .contains(restaurantName)
                                              ? '선택됨'
                                              : '선택하기',
                                          style: TextStyle(
                                            color: _selectedRestaurants
                                                    .contains(restaurantName)
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .primaryColor,
                                            fontWeight: FontWeight.bold,
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
                      ),
                    );
                  },
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
                    '선택된 식당: ${_selectedRestaurants.length}개',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting || _selectedRestaurants.isEmpty
                          ? null
                          : _submitVotes,
                      icon: const Icon(Icons.check),
                      label: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('투표 완료'),
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
