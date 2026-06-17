import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

/// ============================================================
/// THE LOGIN SCREEN
/// ============================================================
///
/// WHY `ConsumerStatefulWidget` (not just `StatefulWidget` or
/// `ConsumerWidget`)?
///   - `Consumer___` widgets give us `ref`, which lets us read/watch
///     Riverpod providers.
///   - We need `State` (the "Stateful" part) because TextEditingControllers
///     and the Form's GlobalKey need to live for the screen's whole
///     lifetime, not be recreated on every rebuild.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // A "form key" lets us trigger validation on ALL fields in this Form at
  // once (via `_formKey.currentState!.validate()`), and lets each
  // CustomTextField's `validator` function run.
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    // WHY DISPOSE CONTROLLERS: TextEditingControllers hold onto resources
    // (like listeners). If we don't dispose them when the screen is
    // removed, they leak memory. This is boilerplate but important Flutter
    // hygiene.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Step 1: run client-side validation (e.g. "is this a valid email
    // format?", defined in the CustomTextField's `validator`). If it
    // fails, stop here - don't even attempt a network call.
    if (!_formKey.currentState!.validate()) return;

    // Step 2: call the AuthActionsNotifier's `login` method. This is the
    // ONLY line in this whole screen that "does" anything with Firebase -
    // and even this screen doesn't know it's Firebase. It's just calling a
    // method on a provider.
    await ref.read(authActionsProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    // Step 3: after the attempt, check if it resulted in an error and show
    // it. We don't need to handle SUCCESS here - see the `ref.listen`
    // explanation below for why.
    if (!mounted) return; // safety check: don't use context if screen was disposed
    final state = ref.read(authActionsProvider);
    state.whenOrNull(
      error: (error, _) {
        final message = error is Failure ? error.message : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // WHY `ref.watch` HERE: this makes the screen rebuild whenever
    // `authActionsProvider`'s state changes - specifically so the button
    // can show a loading spinner while `state.isLoading` is true.
    final authState = ref.watch(authActionsProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      // Allows the screen to scroll up when the keyboard appears, so fields
      // don't get hidden behind it.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // --- App branding ---
                Icon(Icons.home_work_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to continue finding your next home.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // --- Email field ---
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Please enter your email';
                    if (!value.contains('@')) return 'Please enter a valid email';
                    return null; // null = "this field is valid"
                  },
                ),
                const SizedBox(height: 16),

                // --- Password field ---
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    return null;
                  },
                ),

                // --- Forgot password link ---
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // We'll wire this to the router later. For now this
                      // is where you'd navigate to ForgotPasswordScreen.
                      Navigator.of(context).pushNamed('/forgot-password');
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 8),

                // --- Login button ---
                PrimaryButton(
                  label: 'Log In',
                  isLoading: isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 24),

                // --- Link to register ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed('/register'),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
