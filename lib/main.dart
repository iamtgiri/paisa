import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/account.dart';
import 'models/app_prefs.dart';
import 'models/isar_service.dart';
import 'providers/providers.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/lock/pin_lock_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: PaisaApp()));
}

class PaisaApp extends ConsumerWidget {
  const PaisaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Paisa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: AppTheme.themeMode(themeMode),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell();

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  int _currentIndex = 0;
  bool _dbReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initApp());
  }

  Future<void> _initApp() async {
    try {
      await AppPrefs.instance.init();
      await IsarService.instance.init();

      if (!mounted) return;

      // ── Restore persisted state into providers ─────────────────
      final prefs = AppPrefs.instance;

      ref.read(spendingLimitProvider.notifier).state = prefs.spendingLimit;
      ref.read(themeModeProvider.notifier).state = prefs.themeMode;
      AppUtils.configureCurrency(
        symbol: prefs.currencySymbol,
        prefix: prefs.currencyPrefix,
        decimals: prefs.currencyDecimals,
      );
      ref.read(notificationsEnabledProvider.notifier).state =
          prefs.notificationsEnabled;

      if (prefs.hasPin) {
        ref.read(pinStateProvider.notifier).state = prefs.pin;
        ref.read(appUnlockedProvider.notifier).state = false;
      }

      // ── Load accounts ──────────────────────────────────────────
      final accounts = accountsFromJson(prefs.accountsJson);
      ref.read(accountsProvider.notifier).load(accounts);

      final transfers = transfersFromJson(prefs.transfersJson);
      ref.read(transfersProvider.notifier).load(transfers);

      // ── Notifications ──────────────────────────────────────────
      if (prefs.notificationsEnabled) {
        await NotificationService.instance.init();
        await NotificationService.instance.checkAndNotify();
      }

      setState(() => _dbReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  static const _pages = [
    DashboardScreen(),
    TransactionsScreen(),
    AnalyticsScreen(),
    CategoriesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.expense),
                const SizedBox(height: 16),
                const Text('Failed to initialize',
                    style: TextStyle(fontSize: 18, color: AppTheme.onSurface)),
                const SizedBox(height: 8),
                Text(_error!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.onSurfaceMuted),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    if (!_dbReady) return const _SplashScreen();

    final unlocked = ref.watch(appUnlockedProvider);
    final pin = ref.watch(pinStateProvider);
    if (pin != null && !unlocked) {
      return PinLockScreen(
        onUnlocked: () => ref.read(appUnlockedProvider.notifier).state = true,
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = i);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart_rounded),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              activeIcon: Icon(Icons.category_rounded),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              activeIcon: Icon(Icons.more_horiz_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text('Paisa',
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                    letterSpacing: -1)),
            const SizedBox(height: 6),
            const Text('Your personal finance tracker',
                style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceMuted)),
            const SizedBox(height: 40),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
