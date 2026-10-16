class ApiConfig {
  ApiConfig._();

  /// Primary deployed backend URL on Render (no trailing slash)
  static const String baseUrl = 'https://plannoraapp-1.onrender.com';

  /// Request timeout
  static const Duration timeout = Duration(seconds: 30);

  // Health
  static const String health = '/';

  // Auth Endpoints
  static const String register = '/api/auth/register';
  static const String verifyOtp = '/api/auth/verifyotp';
  static const String login = '/api/auth/login';
  static const String forgotPassword = '/api/auth/forgotpassword';
  static const String verifyOtpForgot = '/api/auth/verifyforgototp';
  static const String resetPassword = '/api/auth/resetpassword';
  static const String profile = '/api/auth/profile';
  static const String logout = '/api/auth/logout';

  // Customer Endpoints
  static const String customerCreate = '/api/customer/create';
  static const String customerProfile = '/api/customer';
  static const String customerUpdate = '/api/customer/update';

  // Freelancer Endpoints
  static const String freelancerCreate = '/api/freelancer/create';
  static const String freelancerProfile = '/api/freelancer';
  static const String freelancerUpdate = '/api/freelancer/update';

  // Event Requests
  static const String requestCreate = '/api/request/create';
  static const String requestList = '/api/request';
  static String requestDetail(String id) => '/api/request/$id';

  // Freelancer Event Actions
  static String freelancerAcceptRequest(String requestId) =>
      '/api/freelancer-request/$requestId/accept';
  static String freelancerRejectRequest(String requestId) =>
      '/api/freelancer-request/$requestId/reject';
  static String freelancerAttendance(String requestId) =>
      '/api/freelancer-request/$requestId/attendance';
  static String freelancerRedFlag(String requestId) =>
      '/api/freelancer-request/$requestId/redflag';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String registerDevice = '/api/notifications/register-device';
  static const String readAllNotifications = '/api/notifications/read-all';
}
