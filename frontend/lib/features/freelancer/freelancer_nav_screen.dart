import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../notifications/notifications_screen.dart';
import 'freelancer_home_screen.dart';
import 'freelancer_profile_screen.dart';
import 'freelancer_requests_screen.dart';

class FreelancerNavScreen extends StatefulWidget {
  const FreelancerNavScreen({super.key});

  @override
  State<FreelancerNavScreen> createState() => _FreelancerNavScreenState();
}

class _FreelancerNavScreenState extends State<FreelancerNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FreelancerHomeScreen(),
    FreelancerRequestsScreen(),
    NotificationsScreen(),
    FreelancerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.secondary,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Jobs & Shifts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
