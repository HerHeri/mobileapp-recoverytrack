import 'package:flutter/material.dart';

class TypingHint extends StatelessWidget {
  final bool compact;

  const TypingHint({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: compact ? 2 : 5),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 32,
          vertical: compact ? 14 : 35,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 48 : 72,
              height: compact ? 48 : 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_alt_outlined,
                size: compact ? 26 : 36,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: compact ? 8 : 16),
            Text(
              "Mulai Mengetik",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: compact ? 15 : 18,
              ),
            ),
            SizedBox(height: compact ? 3 : 7),
            Text(
              "Ketik minimal 2 karakter untuk pencarian prefix",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: compact ? 1.2 : 1.45,
                fontSize: compact ? 12 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
