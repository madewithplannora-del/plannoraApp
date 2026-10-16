import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.read).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConfig.notifications);
      if (res is Map && res['notifications'] is List) {
        final list = res['notifications'] as List;
        _notifications = list
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _notifications = [];
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to load notifications';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllRead() async {
    try {
      await _api.patch(ApiConfig.readAllNotifications);
      _notifications = _notifications
          .map(
            (n) => NotificationModel(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              requestId: n.requestId,
              read: true,
              createdAt: n.createdAt,
            ),
          )
          .toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> registerDeviceToken(String fcmToken) async {
    try {
      await _api.post(
        ApiConfig.registerDevice,
        // Backend reads req.body.pushToken (notification.controller.js)
        body: {'pushToken': fcmToken},
      );
    } catch (_) {}
  }
}
