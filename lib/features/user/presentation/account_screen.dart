import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:what_can_i_make/core/error/error_handler.dart';
import 'package:what_can_i_make/features/auth/domain/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:what_can_i_make/features/user/domain/request_limit_service.dart';

class AccountScreen extends StatefulWidget {
  static const routeName = '/account';

  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AuthService _authService;
  late final ErrorHandler _errorHandler;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = context.read<AuthService>();
    _errorHandler = context.read<ErrorHandler>();
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    final authResult = await _authService.signOut();

    final auth = _errorHandler.handleFatalEither(authResult);

    if (auth != null) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacementNamed('/');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = _authService.currentUser;

    // Listen to token usage changes
    final requestsUsed = context.watch<RequestLimitService>().requestsUsed;
    final requestsLimit = context.watch<RequestLimitService>().requestsLimit;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile picture and name
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            user?.displayName?.isNotEmpty == true
                                ? user!.displayName![0].toUpperCase()
                                : user?.email[0].toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'User',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Token usage section
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Usage',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: requestsUsed / requestsLimit,
                      backgroundColor: colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$requestsUsed requests used',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '$requestsLimit requests limit',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/payment');
                      },
                      icon: const FaIcon(FontAwesomeIcons.crown, size: 16),
                      label: const Text('Upgrade Plan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Account actions section
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.edit, color: colorScheme.primary),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to edit profile screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit profile feature coming soon!'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.settings, color: colorScheme.primary),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to settings screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings feature coming soon!'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.help_outline,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to help screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Help & Support feature coming soon!'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: colorScheme.error),
                    title: Text(
                      'Log Out',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    onTap: _isLoading ? null : _signOut,
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Version info
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
