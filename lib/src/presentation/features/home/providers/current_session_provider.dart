import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/src/core/di/parts/repository_providers.dart';
import 'package:tempo/src/data/database/drift_database.dart';

/// Provider для активной сессии (Stream)
final currentSessionProvider = StreamProvider<Session?>((ref) {
  final repository = ref.watch(sessionRepositoryProvider);
  return repository.watchActiveSession();
});

/// Тикер, обновляющийся каждую секунду
final tickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (x) => x);
});

/// Provider для elapsed time активной сессии
final sessionElapsedTimeProvider = Provider<Duration?>((ref) {
  final sessionAsync = ref.watch(currentSessionProvider);
  // Подписываемся на тикер для обновления каждую секунду
  ref.watch(tickerProvider);
  
  return sessionAsync.when(
    data: (session) {
      if (session == null) return null;
      return DateTime.now().difference(session.startAt);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

