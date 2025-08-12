import 'package:flutter/material.dart';
import 'dart:async';

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    
    // 2025년 8월 14일 23:59:59를 마감 시간으로 설정
    final deadline = DateTime(2025, 8, 14, 17, 59, 59);
    
    if (now.isAfter(deadline)) {
      setState(() {
        _timeString = '마감됨';
      });
      _timer?.cancel();
      return;
    }

    final difference = deadline.difference(now);
    final totalHours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    setState(() {
      _timeString = '$totalHours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              const Text(
                '투표 마감',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _timeString,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
