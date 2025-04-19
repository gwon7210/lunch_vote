import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class ParticipationScreen extends StatefulWidget {
  const ParticipationScreen({super.key});

  @override
  State<ParticipationScreen> createState() => _ParticipationScreenState();
}

class _ParticipationScreenState extends State<ParticipationScreen> {
  bool? _isParticipating;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipation();
  }

  Future<void> _loadParticipation() async {
    final firestoreService = context.read<FirestoreService>();
    final isParticipating = await firestoreService.getParticipation();

    if (mounted) {
      setState(() {
        _isParticipating = isParticipating;
        _isLoading = false;
      });
    }
  }

  Future<void> _setParticipation(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService = context.read<FirestoreService>();
      await firestoreService.setParticipation(value);

      if (mounted) {
        setState(() {
          _isParticipating = value;
        });

        if (value) {
          context.go('/vote');
        } else {
          context.go('/not-participating');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회식 참여 여부'),
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
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '이번 달 회식에 참여하시겠습니까?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _setParticipation(true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('예'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _setParticipation(false),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('아니오'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
