import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/countdown_timer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // 허용된 이메일 목록
  final List<String> _allowedEmails = [
    'kseun@youngjin.com',
    'jisooda@youngjin.com',
    'parkjonghyun@youngjin.com',
    'leechan@youngjin.com',
    'parkjiwon@youngjin.com',
    'ksj@youngjin.com',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 사용자 정보 Firestore에 저장
      final userName = email.split('@')[0]; // 이메일에서 @ 앞부분을 사용자 이름으로 사용
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': userName,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        context.go('/');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? '로그인에 실패했습니다';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
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
      body: Stack(
        children: [
          Center(
            child: Card(
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.asset(
                          'assets/images/lunch_illustration.png',
                          width: 250,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(
                              width: 250,
                              height: 150,
                              child: Center(
                                child: Text(
                                    '이미지를 불러올 수 없습니다.\nassets/images/lunch_illustration.png 경로를 확인해주세요.'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '회식 투표 앱',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: '이메일을 입력해주세요',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이메일을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: '비밀번호를 입력해주세요',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호를 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('시작하기'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 타이머를 화면 상단에 배치
          Positioned(
            top: 50,
            right: 20,
            child: const CountdownTimer(),
          ),
        ],
      ),
    );
  }
}
