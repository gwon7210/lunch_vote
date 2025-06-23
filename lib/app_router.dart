import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/participation_screen.dart';
import 'screens/vote_screen.dart';
import 'screens/result_screen.dart';
import 'screens/not_participating_screen.dart';
import 'screens/date_selection_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/non_participation_reason_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginRoute) {
      return '/login';
    }

    if (isLoggedIn && isLoginRoute) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const ParticipationScreen(),
    ),
    GoRoute(
      path: '/date-selection',
      builder: (context, state) => const DateSelectionScreen(),
    ),
    GoRoute(
      path: '/vote',
      builder: (context, state) => const VoteScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const ResultScreen(),
    ),
    GoRoute(
      path: '/not-participating',
      builder: (context, state) => const NotParticipatingScreen(),
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/non-participation-reason',
      builder: (context, state) => const NonParticipationReasonScreen(),
    ),
  ],
);
