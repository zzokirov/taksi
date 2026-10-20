import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_customer_screen.dart';
import '../../screens/auth/register_barber_screen.dart';
import '../../screens/customer/customer_main_nav.dart';
import '../../screens/customer/barber_search_screen.dart';
import '../../screens/customer/barber_details_screen.dart';
import '../../screens/customer/appointment_booking_screen.dart';
import '../../screens/barber/barber_main_nav.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isGoingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register-customer' ||
          state.matchedLocation == '/register-barber';

      if (!isAuth && !isGoingToAuth) {
        return '/login';
      }

      if (isAuth && isGoingToAuth) {
        if (authState.user?.isBarber == true) {
          return '/barber';
        } else {
          return '/customer';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register-customer',
        builder: (context, state) => const RegisterCustomerScreen(),
      ),
      GoRoute(
        path: '/register-barber',
        builder: (context, state) => const RegisterBarberScreen(),
      ),
      GoRoute(
        path: '/customer',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          int idx = 0;
          if (tab == 'favorites') idx = 1;
          if (tab == 'appointments') idx = 2;
          if (tab == 'profile') idx = 3;
          return CustomerMainNav(initialIndex: idx);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const BarberSearchScreen(),
      ),
      GoRoute(
        path: '/barber/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return BarberDetailsScreen(barberId: id);
        },
      ),
      GoRoute(
        path: '/book/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final serviceIdStr = state.uri.queryParameters['service_id'];
          final serviceId = (serviceIdStr != null && serviceIdStr.isNotEmpty) ? int.tryParse(serviceIdStr) : null;
          return AppointmentBookingScreen(barberId: id, preselectedServiceId: serviceId);
        },
      ),
      GoRoute(
        path: '/barber',
        builder: (context, state) => const BarberMainNav(),
      ),
    ],
  );
});
