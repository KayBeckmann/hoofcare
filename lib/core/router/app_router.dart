import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/owners/owners_screen.dart';
import '../../features/owners/owner_form_screen.dart';
import '../../features/owners/owner_detail_screen.dart';
import '../../features/horses/horse_form_screen.dart';
import '../../features/horses/horse_detail_screen.dart';
import '../../features/treatments/treatment_form_screen.dart';
import '../../features/appointments/appointments_screen.dart';
import '../../features/appointments/appointment_form_screen.dart';
import '../db/database.dart';

final _rootNavKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (c, s) => const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/owners',
            pageBuilder: (c, s) => const NoTransitionPage(child: OwnersScreen()),
          ),
          GoRoute(
            path: '/appointments',
            pageBuilder: (c, s) => const NoTransitionPage(child: AppointmentsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/owners/new',
        builder: (c, s) => const OwnerFormScreen(),
      ),
      GoRoute(
        path: '/owners/:id',
        builder: (c, s) => OwnerDetailScreen(ownerId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/owners/:id/edit',
        builder: (c, s) {
          final owner = s.extra as Owner;
          return OwnerFormScreen(owner: owner);
        },
      ),
      GoRoute(
        path: '/owners/:ownerId/horses/new',
        builder: (c, s) =>
            HorseFormScreen(ownerId: int.parse(s.pathParameters['ownerId']!)),
      ),
      GoRoute(
        path: '/horses/:id',
        builder: (c, s) =>
            HorseDetailScreen(horseId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/horses/:id/edit',
        builder: (c, s) {
          final horse = s.extra as Horse;
          return HorseFormScreen(ownerId: horse.ownerId, horse: horse);
        },
      ),
      GoRoute(
        path: '/horses/:horseId/treatments/new',
        builder: (c, s) =>
            TreatmentFormScreen(horseId: int.parse(s.pathParameters['horseId']!)),
      ),
      GoRoute(
        path: '/treatments/:id/edit',
        builder: (c, s) {
          final treatment = s.extra as Treatment;
          return TreatmentFormScreen(horseId: treatment.horseId, treatment: treatment);
        },
      ),
      GoRoute(
        path: '/appointments/new',
        builder: (c, s) {
          final extra = s.extra as Map<String, dynamic>?;
          return AppointmentFormScreen(
            preselectedHorseId: extra?['horseId'] as int?,
            preselectedDate: extra?['date'] as DateTime?,
          );
        },
      ),
      GoRoute(
        path: '/appointments/:id/edit',
        builder: (c, s) {
          final appt = s.extra as Appointment;
          return AppointmentFormScreen(appointment: appt);
        },
      ),
    ],
  );
});

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static int _locationToIndex(String location) {
    if (location.startsWith('/owners')) return 1;
    if (location.startsWith('/appointments')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
            case 1:
              context.go('/owners');
            case 2:
              context.go('/appointments');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: 'Kunden'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Termine'),
        ],
      ),
    );
  }
}
