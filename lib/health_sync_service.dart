import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

enum HealthAuthorizationStatus {
  authorized,
  denied,
  unsupportedPlatform,
  error,
}

class HealthAuthorizationResult {
  final HealthAuthorizationStatus status;
  final String message;

  const HealthAuthorizationResult({
    required this.status,
    required this.message,
  });
}

class HealthSyncService {
  final Health _health = Health();
  bool _configured = false;

  Future<HealthAuthorizationResult> authorizeSleepWriteAccess() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return const HealthAuthorizationResult(
        status: HealthAuthorizationStatus.unsupportedPlatform,
        message: 'Apple Health доступен только на iOS.',
      );
    }

    try {
      await _ensureConfigured();

      const type = HealthDataType.SLEEP_ASLEEP;
      final permissions = [HealthDataAccess.WRITE];

      final authorized = await _health.requestAuthorization(
        [type],
        permissions: permissions,
      );
      if (!authorized) {
        return const HealthAuthorizationResult(
          status: HealthAuthorizationStatus.denied,
          message: 'Доступ к записи сна не выдан.',
        );
      }

      final hasWritePermission = await _health.hasPermissions(
        [type],
        permissions: permissions,
      );
      if (hasWritePermission != true) {
        return const HealthAuthorizationResult(
          status: HealthAuthorizationStatus.denied,
          message: 'Нет WRITE-доступа к Sleep в Apple Health.',
        );
      }

      return const HealthAuthorizationResult(
        status: HealthAuthorizationStatus.authorized,
        message: 'Доступ к Apple Health выдан.',
      );
    } catch (e) {
      debugPrint('Health authorization failed: $e');
      return HealthAuthorizationResult(
        status: HealthAuthorizationStatus.error,
        message: 'Ошибка авторизации: $e',
      );
    }
  }

  Future<bool> deleteSleepInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
    if (!end.isAfter(start)) return false;

    try {
      await _ensureConfigured();

      const type = HealthDataType.SLEEP_ASLEEP;
      final permissions = [HealthDataAccess.WRITE];
      final authorized = await _health.requestAuthorization(
        [type],
        permissions: permissions,
      );
      if (!authorized) return false;
      final hasWritePermission = await _health.hasPermissions(
        [type],
        permissions: permissions,
      );
      if (hasWritePermission != true) return false;

      final deleted = await _health.delete(
        type: type,
        startTime: start,
        endTime: end,
      );
      if (!deleted) {
        debugPrint(
          'Health delete returned false for interval $start - $end',
        );
      }
      return deleted;
    } catch (e) {
      debugPrint('Health delete failed: $e');
      return false;
    }
  }

  Future<bool> syncSleep({
    required DateTime start,
    required DateTime end,
    required String clientRecordId,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
    if (!end.isAfter(start)) return false;

    try {
      await _ensureConfigured();

      const type = HealthDataType.SLEEP_ASLEEP;
      final permissions = [HealthDataAccess.WRITE];
      final authorized = await _health.requestAuthorization(
        [type],
        permissions: permissions,
      );
      if (!authorized) return false;
      final hasWritePermission = await _health.hasPermissions(
        [type],
        permissions: permissions,
      );
      if (hasWritePermission != true) return false;

      final success = await _health.writeHealthData(
        // For sleep categories value is aligned by plugin; any valid number works.
        value: 1,
        type: type,
        startTime: start,
        endTime: end,
        recordingMethod: RecordingMethod.automatic,
        clientRecordId: clientRecordId,
      );
      if (!success) {
        debugPrint('Health write returned false for $clientRecordId');
      }
      return success;
    } catch (e) {
      debugPrint('Health sync failed: $e');
      return false;
    }
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }
}
