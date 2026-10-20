import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/network/session_expired_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/antrian/presentation/screens/antrian_screen.dart';
import '../../features/eform_laka/presentation/screens/eform_laka_screen.dart';
import '../../features/barang_bukti/presentation/screens/barang_bukti_screen.dart';
import '../../features/konseling/presentation/screens/konseling_screen.dart';
import '../../features/konseling/presentation/screens/konseling_chat_screen.dart';
import '../../features/rehab/presentation/screens/rehab_screen.dart';
import '../../features/registration/presentation/screens/registration_screen.dart';
import '../../features/sertifikasi/presentation/screens/sertifikasi_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/notifikasi/presentation/screens/notifikasi_screen.dart';
import '../../features/patroli/presentation/screens/patroli_home_screen.dart';
import '../../features/patroli/presentation/screens/patroli_active_screen.dart';
import '../../features/patroli/presentation/screens/patroli_settings_screen.dart';
import '../../features/patroli/presentation/screens/patroli_detail_screen.dart';
import '../../features/splash/splash_screen.dart';

final _splashTimerProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(milliseconds: 3000));
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier();
  ref.onDispose(notifier.dispose);

  ref.listen(authNotifierProvider, (_, _) => notifier.signal());
  ref.listen(_splashTimerProvider, (_, _) => notifier.signal());

  // Auto-logout saat Odoo session expired (server restart, timeout, dll.).
  // Flag sengaja dibiarkan menyala sampai login berikutnya berhasil: saat
  // session mati, semua request yang sedang terbang ikut balas expired, dan
  // me-reset lebih awal membuat tiap respons sisa memicu logout lagi.
  ref.listen<SessionExpiredNotifier>(sessionExpiredProvider, (_, expired) {
    if (!expired.hasExpired) return;
    ref.read(authNotifierProvider.notifier).logout();
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);
      final splashDone = ref.read(_splashTimerProvider).hasValue;
      final loc = state.matchedLocation;

      if (authAsync.isLoading || !splashDone) {
        if (loc == '/splash') return null;
        return '/splash';
      }

      final user = authAsync.valueOrNull;
      final isLoggedIn = user != null;

      if (!isLoggedIn && loc != '/login' && loc != '/register') return '/login';

      // Fitur patroli dinonaktifkan di iOS dan web
      final isPatroli = !kIsWeb && !Platform.isIOS && (user?.isPatroli ?? false);

      if (isLoggedIn && (loc == '/login' || loc == '/splash' || loc == '/register')) {
        return isPatroli ? '/patroli' : '/dashboard';
      }

      // Patroli user tidak boleh akses route umum
      if (isLoggedIn && isPatroli && !loc.startsWith('/patroli')) return '/patroli';
      // User biasa tidak boleh akses route patroli
      if (isLoggedIn && !isPatroli && loc.startsWith('/patroli')) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/splash',       name: 'splash',       builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/profile',      name: 'profile',      builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/notifikasi',   name: 'notifikasi',   builder: (_, _) => const NotifikasiScreen()),
      GoRoute(path: '/login',        name: 'login',        builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register',     name: 'register',     builder: (_, _) => const RegistrationScreen()),
      GoRoute(path: '/sertifikasi',  name: 'sertifikasi',  builder: (_, _) => const SertifikasiScreen()),
      GoRoute(path: '/dashboard',    name: 'dashboard',    builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/antrian',      name: 'antrian',      builder: (_, _) => const AntrianScreen()),
      GoRoute(path: '/eform-laka',   name: 'eformLaka',    builder: (_, _) => const EformLakaScreen()),
      GoRoute(path: '/rehab',        name: 'rehab',        builder: (_, _) => const RehabScreen()),
      GoRoute(path: '/barang-bukti', name: 'barangBukti',  builder: (_, _) => const BarangBuktiScreen()),
      GoRoute(path: '/konseling',    name: 'konseling',    builder: (_, _) => const KonselingScreen()),
      GoRoute(
        path: '/konseling/chat',
        name: 'konselingChat',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return KonselingChatScreen(
            channelId: extra['channelId'] as int,
            title: extra['title'] as String,
          );
        },
      ),
      // ── Patroli routes ─────────────────────────────────────────────────────
      GoRoute(path: '/patroli',          name: 'patroli',         builder: (_, _) => const PatroliHomeScreen()),
      GoRoute(path: '/patroli/active',   name: 'patroliActive',   builder: (_, _) => const PatroliActiveScreen()),
      GoRoute(path: '/patroli/settings', name: 'patroliSettings', builder: (_, _) => const PatroliSettingsScreen()),
      GoRoute(
        path: '/patroli/detail/:id',
        name: 'patroliDetail',
        builder: (_, state) => PatroliDetailScreen(
          patroliId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
});

/// ChangeNotifier tipis: dipakai sebagai [GoRouter.refreshListenable].
/// GoRouter akan re-evaluasi [redirect] setiap kali [signal] dipanggil.
class _AuthRouterNotifier extends ChangeNotifier {
  void signal() => notifyListeners();
}
