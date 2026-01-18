import 'package:tempo/src/data/database/drift_database.dart';
import 'package:tempo/src/domain/entities/repeat_rule.dart';

extension TaskRepeatRule on Task {
  RepeatRule? get repeatRule {
    if (repeatType == RepeatType.none) return null;
    if (repeatParams == null) return null;
    try {
      return RepeatRule.fromJson(repeatParams!, repeatType.index);
    } catch (e) {
      // ignore
      return null;
    }
  }
}
