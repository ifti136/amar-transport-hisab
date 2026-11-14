import 'package:flutter/material.dart';

/// Icon-only add FAB used on every list screen once the list has content.
///
/// Empty lists use a centred labelled action instead (see [EmptyStateView]).
class AddIconFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const AddIconFab({super.key, required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: const Icon(Icons.add),
    );
  }
}

/// Primary add action shown in the centre of an empty state.
///
/// Uses a 56dp tall button so it stays a comfortable touch target.
class AddActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const AddActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
