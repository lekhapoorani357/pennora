import 'dart:convert';
import '../../../core/api/api_client.dart';

/// Service for logging non-sensitive engagement and monetization events to the backend.
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();

  AnalyticsService._();

  Future<void> logEvent(String eventName, {Map<String, dynamic>? properties, bool isDemo = false}) async {
    if (ApiClient.instance.authToken == null) return;
    try {
      await ApiClient.instance.post(
        '/api/analytics/events',
        body: {
          'eventName': eventName,
          'properties': properties != null ? json.encode(properties) : null,
          'isDemo': isDemo,
        },
        requiresAuth: true,
      );
    } catch (_) {
      // Analytics fire-and-forget
    }
  }
}
