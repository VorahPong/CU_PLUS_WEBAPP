import 'package:flutter/foundation.dart';

/// A global notifier used to signal that the user profile has been updated.
///
/// When the value changes, listeners (like DashboardShell) can refetch
/// the latest user data (e.g., profile image, name, etc.).
final ValueNotifier<int> profileRefreshNotifier = ValueNotifier<int>(0);
