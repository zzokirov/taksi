import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'barber_overview_screen.dart';
import 'barber_appointments_screen.dart';
import 'barber_schedule_screen.dart';
import 'barber_services_screen.dart';
import 'barber_revenue_screen.dart';

class BarberMainNav extends StatefulWidget {
  final int initialIndex;

  const BarberMainNav({super.key, this.initialIndex = 0});

  @override
  State<BarberMainNav> createState() => _BarberMainNavState();
}

class _BarberMainNavState extends State<BarberMainNav> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    BarberOverviewScreen(),
    BarberAppointmentsScreen(),
    BarberScheduleScreen(),
    BarberServicesScreen(),
    BarberRevenueScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: AppStrings.navOverview,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: AppStrings.navAppointments,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time_outlined),
              activeIcon: Icon(Icons.access_time_filled),
              label: AppStrings.navSchedule,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.content_cut_outlined),
              activeIcon: Icon(Icons.content_cut),
              label: AppStrings.navServices,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: AppStrings.navRevenue,
            ),
          ],
        ),
      ),
    );
  }
}
