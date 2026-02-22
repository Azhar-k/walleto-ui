import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainNavigationShell extends StatefulWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/summary')) return 0;
    if (location.startsWith('/accounts')) return 1;
    if (location.startsWith('/transactions')) return 2;
    return 0; // Default
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/summary');
        break;
      case 1:
        context.go('/accounts');
        break;
      case 2:
        context.go('/transactions');
        break;
    }
  }
  
  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (context.mounted) {
       context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walleto'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF6200EE),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   Icon(Icons.account_balance_wallet, color: Colors.white, size: 48),
                   SizedBox(height: 16),
                   Text(
                    'Walleto Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ]
              )
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Recurring Payments'),
              onTap: () {
                Navigator.pop(context);
                context.push('/recurring-payments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                context.push('/categories');
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Self Transfer'),
              onTap: () {
                Navigator.pop(context);
                context.push('/self-transfer');
              },
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner),
              title: const Text('Scan SMS'),
              onTap: () {
                Navigator.pop(context);
                context.push('/scan-sms');
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Regex Patterns'),
              onTap: () {
                Navigator.pop(context);
                context.push('/regex-patterns');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (idx) => _onItemTapped(idx, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }
}
