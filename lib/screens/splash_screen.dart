import 'package:flutter/material.dart';
import '../models/meku_emotion.dart';
import '../widgets/meku_avatar.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const SplashScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MekuAvatar(size: 132, emotion: MekuEmotion.happy),
                const SizedBox(height: 16),
                Text('Ohymeku',
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    onRetry == null
                        ? 'Завантажуємо пригоду…'
                        : 'Не вдалося завантажити Ohymeku.',
                    textAlign: TextAlign.center,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Спробувати ще раз'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
