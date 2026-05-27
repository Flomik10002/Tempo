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

  Future<void> deleteSleepInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!end.isAfter(start)) return;

    try {
      await _ensureConfigured();

      const type = HealthDataType.SLEEP_ASLEEP;
      final permissions = [HealthDataAccess.WRITE];
      final authorized = await _health.requestAuthorization(
        [type],
        permissions: permissions,
      );
      if (!authorized) return;
      final hasWritePermission = await _health.hasPermissions(
        [type],
        permissions: permissions,
      );
      if (hasWritePermission != true) return;

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
      await _ensureConfigured();

      const type = HealthDataType.SLEEP_ASLEEP;
      final permissions = [HealthDataAccess.WRITE];
      final authorized = await _health.requestAuthorization(
        [type],
        permissions: permissions,
      );
      if (!authorized) return;
      final hasWritePermission = await _health.hasPermissions(
        [type],
        permissions: permissions,
      );
      if (hasWritePermission != true) return;

      final success = await _health.writeHealthData(
        value: minutes.toDouble(),
        type: type,
        startTime: start,
        endTime: end,
        recordingMethod: RecordingMethod.automatic,
        clientRecordId: clientRecordId,
      );
      if (!success) {
        debugPrint('Health write returned false for $clientRecordId');
      }
    } catch (e) {
      debugPrint('Health sync failed: $e');
    }
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }
}
