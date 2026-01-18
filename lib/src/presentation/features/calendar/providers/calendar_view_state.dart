import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider для хранения выбранной даты в календаре
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
