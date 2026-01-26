import 'package:flutter/services.dart';

/// Platform service for Android permissions and native interactions
class PlatformService {
  static const MethodChannel _channel = MethodChannel(
    'com.doombreaker/permissions',
  );

  // Check all permissions status at once
  Future<Map<String, bool>> checkAllPermissions() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'checkAllPermissions',
      );
      return {
        'usageStats': result['usageStats'] as bool? ?? false,
        'overlay': result['overlay'] as bool? ?? false,
        'accessibility': result['accessibility'] as bool? ?? false,
        'batteryOptimization': result['batteryOptimization'] as bool? ?? false,
        'autoStart': result['autoStart'] as bool? ?? false,
      };
    } catch (e) {
      // Return false for all if method not implemented yet
      return {
        'usageStats': false,
        'overlay': false,
        'accessibility': false,
        'batteryOptimization': false,
        'autoStart': false,
      };
    }
  }

  // Request usage stats permission
  Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      // Silently handle - permission not available
    }
  }

  // Check usage stats permission
  Future<bool> checkUsageStatsPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'checkUsageStatsPermission',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Request overlay permission
  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      // Silently handle - permission not available
    }
  }

  // Check overlay permission
  Future<bool> checkOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'checkOverlayPermission',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Request accessibility permission
  Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      // Silently handle - permission not available
    }
  }

  // Check accessibility permission
  Future<bool> checkAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'checkAccessibilityPermission',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Request battery optimization to be disabled
  Future<void> requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
    } catch (e) {
      // Silently handle - permission not available
    }
  }

  // Check if battery optimization is disabled
  Future<bool> checkBatteryOptimization() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'checkBatteryOptimization',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Request autostart permission (manufacturer-specific)
  Future<void> requestAutoStartPermission() async {
    try {
      await _channel.invokeMethod('requestAutoStartPermission');
    } catch (e) {
      // Silently handle - permission not available
    }
  }
}
