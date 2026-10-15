import 'package:expo_spot/features/shell/main_shell.dart';
import 'package:flutter/material.dart';

/// Legacy entry — use [MainShell] directly.
@Deprecated('Use MainShell')
class GroupHubScreen extends StatelessWidget {
  const GroupHubScreen({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return MainShell(userName: userName);
  }
}
