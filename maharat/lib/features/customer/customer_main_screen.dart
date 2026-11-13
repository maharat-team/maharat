import 'package:flutter/material.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import 'home/customer_home_tab.dart';
import 'find/find_workers_tab.dart';
import 'job_requests/my_requests_tab.dart';
import 'profile/customer_profile_tab.dart';

class CustomerMainScreen extends StatefulWidget {
  final int initialTabIndex;

  const CustomerMainScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      CustomerHomeTab(
        onNavigateToFind: () => _onTabTapped(1),
        onNavigateToRequests: () => _onTabTapped(2),
      ),
      const FindWorkersTab(),
      const MyRequestsTab(),
      const CustomerProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: context.tr('Home', 'ہوم'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_outlined),
              activeIcon: const Icon(Icons.search_rounded),
              label: context.tr('Find', 'تلاش'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_outlined),
              activeIcon: const Icon(Icons.assignment_rounded),
              label: context.tr('Requests', 'درخواستیں'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: context.tr('Profile', 'پروفائل'),
            ),
          ],
        ),
      ),
    );
  }
}
