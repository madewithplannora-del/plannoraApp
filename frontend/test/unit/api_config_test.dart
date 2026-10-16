import 'package:flutter_test/flutter_test.dart';
import 'package:planera/core/config/api_config.dart';

void main() {
  group('ApiConfig Contract Verification', () {
    test('Base URL is exact deployed Render domain without trailing slash', () {
      expect(ApiConfig.baseUrl, 'https://plannoraapp-1.onrender.com');
      expect(ApiConfig.baseUrl.endsWith('/'), isFalse);
    });

    test('Auth routes match backend contract', () {
      expect(ApiConfig.register, '/api/auth/register');
      expect(ApiConfig.login, '/api/auth/login');
      expect(ApiConfig.verifyOtp, '/api/auth/verifyotp');
      expect(ApiConfig.forgotPassword, '/api/auth/forgotpassword');
      expect(ApiConfig.verifyOtpForgot, '/api/auth/verifyotpforgot');
      expect(ApiConfig.profile, '/api/auth/profile');
      expect(ApiConfig.logout, '/api/auth/logout');
    });

    test('Customer routes match backend contract', () {
      expect(ApiConfig.customerCreate, '/api/customer/create');
      expect(ApiConfig.customerProfile, '/api/customer');
      expect(ApiConfig.customerUpdate, '/api/customer/update');
    });

    test('Freelancer routes match backend contract', () {
      expect(ApiConfig.freelancerCreate, '/api/freelancer/create');
      expect(ApiConfig.freelancerProfile, '/api/freelancer');
      expect(ApiConfig.freelancerUpdate, '/api/freelancer/update');
    });

    test('Event Request routes match backend contract', () {
      expect(ApiConfig.requestCreate, '/api/request/create');
      expect(ApiConfig.requestList, '/api/request');
      expect(ApiConfig.requestDetail('req_123'), '/api/request/req_123');
    });

    test('Freelancer Request Action routes match backend contract', () {
      expect(
        ApiConfig.freelancerAcceptRequest('req_456'),
        '/api/freelancer-request/req_456/accept',
      );
      expect(
        ApiConfig.freelancerRejectRequest('req_456'),
        '/api/freelancer-request/req_456/reject',
      );
      expect(
        ApiConfig.freelancerAttendance('req_456'),
        '/api/freelancer-request/req_456/attendance',
      );
      expect(
        ApiConfig.freelancerRedFlag('req_456'),
        '/api/freelancer-request/req_456/redflag',
      );
    });

    test('Notification routes match backend contract', () {
      expect(ApiConfig.notifications, '/api/notifications');
      expect(ApiConfig.registerDevice, '/api/notifications/register-device');
      expect(ApiConfig.readAllNotifications, '/api/notifications/read-all');
    });
  });
}
