import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthSyncService {
  final Health _health = Health();
  bool _configured = false;

  Future<void> deleteSleep({required String clientRecordId}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      if (!_configured) {
        await _health.configure();
        _configured = true;
      }

      const type = HealthDataType.SLEEP_ASLEEP;
      final permissions = [HealthDataAccess.READ_WRITE];
      final authorized = await _health.requestAuthorization(
        [type],
        permissions: permissions,
      );
      if (!authorized) return;

      await _health.deleteByClientRecordId(
        dataTypeKey: type,
        clientRecordId: clientRecordId,
      );
    } catch (e) {
      debugPrint('Health delete failed: $e');
    }
  }

  Future<void> syncSleep({
    required DateTime start,
    required DateTime end,
    required String clientRecordId,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!end.isAfter(start)) return;

    final minutes = end.difference(start).inMinutes;
    if (minutes <= 0) return;

    try {
      if (!_configured) {
        await _health.configure();
        _configured = true;
      }

      const type = HealthDataType.SLEEP_ASLEEP;
      final permissions = [HealthDataAccess.READ_WRITE];
      final authorized = await _health.requestAuthorization(
        [type],
        permissions: permissions,
      );
      if (!authorized) return;

      // Prevent duplicates for edited/re-synced segments created by this app.
      await _health.deleteByClientRecordId(
        dataTypeKey: type,
        clientRecordId: clientRecordId,
      );

      await _health.writeHealthData(
        value: minutes.toDouble(),
        type: type,
        startTime: start,
        endTime: end,
        recordingMethod: RecordingMethod.automatic,
        clientRecordId: clientRecordId,
      );
    } catch (e) {
      debugPrint('Health sync failed: $e');
    }
  }
}
