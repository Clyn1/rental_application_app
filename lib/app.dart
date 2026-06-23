import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/properties/presentation/screens/home_screen.dart';

// This widget decides what to show based on whether someone is logged in.
// It watches currentUserProvider — when that changes (login/logout),
// this widget automatically rebuilds and shows the right screen.
// No manual navigation code needed for login/logout transitions.
class PropertyRentalApp extends ConsumerWidget {
  const PropertyRentalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return MaterialApp(
      title: 'Property Rental App',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const PlaceholderScreen(title: 'Forgot Password Screen'),
        '/notifications': (context) => const PlaceholderScreen(title: 'Notifications Screen'),
        '/property-details': (context) => const PlaceholderScreen(title: 'Property Details Screen'),
      },
      home: userAsync.when(
        data: (user) {
          if (user == null) return const LoginScreen();

          if (user.isSuspended) {
            return const SuspendedAccountScreen();
          }

          switch (user.accountType.name) {
            case 'landlord':
              return const PlaceholderScreen(title: 'Landlord Dashboard');
            case 'admin':
              return const PlaceholderScreen(title: 'Admin Dashboard');
            default:
              return const HomeScreen();
          }
        },
        loading: () => const SplashScreen(),
        error: (error, _) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Something went wrong:\n$error', textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D5B),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D5B),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_rounded, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class SuspendedAccountScreen extends ConsumerWidget {
  const SuspendedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Your account has been suspended.\nContact support for assistance.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(authActionsProvider.notifier).logout(),
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title - build this next, following the same pattern!')),
    );
  }
}
