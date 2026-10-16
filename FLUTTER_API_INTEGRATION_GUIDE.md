# Plannora Backend API & Flutter Mobile Integration Master Guide

> **Base Production URL:** `https://plannoraapp-1.onrender.com`  
> **Local Development URL:** `http://localhost:3001` (iOS Simulator) / `http://10.0.2.2:3001` (Android Emulator)  
> **Auth Header Format:** `Authorization: Bearer <accessToken>`  
> **Content-Type:** `application/json` (or `multipart/form-data` for image uploads)

---

## 1. Architecture & Directory Layout

The workspace root is organized with the backend and frontend side-by-side:

```
New folder/
├── backend/                  <-- Express.js + MongoDB API
└── frontend/                 <-- Direct Flutter Project (NO nested folders inside)
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── constants/api_constants.dart
        │   ├── services/api_client.dart
        │   ├── services/storage_service.dart
        │   └── theme/app_theme.dart
        ├── models/
        │   ├── user_model.dart
        │   ├── freelancer_model.dart
        │   ├── customer_model.dart
        │   ├── event_request_model.dart
        │   └── notification_model.dart
        ├── providers/
        │   ├── auth_provider.dart
        │   ├── freelancer_provider.dart
        │   ├── customer_provider.dart
        │   ├── request_provider.dart
        │   └── notification_provider.dart
        └── views/
            ├── auth/
            ├── freelancer/
            ├── customer/
            └── common/
```

---

## 2. Authentication & Authorization

All authenticated endpoints accept the JWT access token in either:
1. **HTTP Authorization Header** (*Recommended for Flutter*): `Authorization: Bearer <token>`
2. **Cookie**: `accesstoken=<token>`

When calling `/api/auth/login` or `/api/auth/verifyotp`, the server returns:
```json
{
  "message": "Logged in",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "660c1...",
    "username": "johndoe",
    "email": "john@example.com",
    "emailVerified": true
  }
}
```
Store this `token` in Flutter's `FlutterSecureStorage` and attach it to all subsequent requests.

---

## 3. Complete API Routes Reference

### 3.1 Authentication Routes (`/api/auth`)

#### 1. Register User (Sends OTP)
- **Method:** `POST`
- **URL:** `/api/auth/register`
- **Body:**
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "Password123!"
}
```
- **Responses:**
  - `200 OK`: `{"message": "OTP sent to your email"}`
  - `400 Bad Request`: `{"message": "Invalid input..."}`
  - `409 Conflict`: `{"message": "Username or email already exists"}`

#### 2. Verify OTP & Create Account
- **Method:** `POST`
- **URL:** `/api/auth/verifyotp`
- **Body:**
```json
{
  "email": "john@example.com",
  "otp": "1234"
}
```
- **Responses:**
  - `200 OK`: Returns `{ "message": "...", "token": "...", "user": { ... } }`
  - `400 Bad Request`: `{"message": "Invalid OTP"}`
  - `429 Too Many Requests`: `{"message": "Too many invalid attempts"}`

#### 3. Login
- **Method:** `POST`
- **URL:** `/api/auth/login`
- **Body:**
```json
{
  "email": "john@example.com",
  "password": "Password123!"
}
```
- **Responses:**
  - `200 OK`:
  ```json
  {
    "message": "Logged in",
    "token": "<JWT_TOKEN>",
    "user": {
      "id": "66...",
      "username": "johndoe",
      "email": "john@example.com",
      "emailVerified": true
    }
  }
  ```
  - `401 Unauthorized`: `{"message": "Invalid credentials"}`

#### 4. Forgot Password (Send OTP)
- **Method:** `POST`
- **URL:** `/api/auth/forgotpassword`
- **Body:** `{ "email": "john@example.com" }`
- **Response `200`:** `{"message": "OTP sent to your email"}`

#### 5. Verify Forgot Password OTP
- **Method:** `POST`
- **URL:** `/api/auth/verifyforgototp`
- **Body:** `{ "email": "john@example.com", "otp": "1234" }`
- **Response `200`:** `{"message": "OTP verified successfully"}`

#### 6. Reset Password
- **Method:** `POST`
- **URL:** `/api/auth/resetpassword`
- **Body:**
```json
{
  "email": "john@example.com",
  "newPassword": "NewPassword123!"
}
```
- **Response `200`:** `{"message": "Password reset successfully"}`

#### 7. Get Current User Profile
- **Method:** `GET`
- **URL:** `/api/auth/profile`
- **Headers:** `Authorization: Bearer <token>`
- **Response `200`:**
```json
{
  "user": {
    "id": "66...",
    "username": "johndoe",
    "email": "john@example.com",
    "profilePicture": { "url": "https://...", "publicId": "..." },
    "emailVerified": true
  }
}
```

#### 8. Logout
- **Method:** `POST`
- **URL:** `/api/auth/logout`
- **Response `200`:** `{"message": "Logged out successfully"}`

---

### 3.2 Freelancer Routes (`/api/freelancer`)

#### 1. Create Freelancer Account
- **Method:** `POST`
- **URL:** `/api/freelancer/create`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "phone": "+919876543210",
  "linkedin": "https://linkedin.com/in/...",
  "category": "Professional",
  "state": "Maharashtra",
  "city": "Mumbai",
  "pincode": "400001"
}
```
*(Categories allowed: `"Professional"`, `"Cultural"`, `"Private"`)*
- **Response `201`:** `{"message": "Freelancer account created successfully", "freelancer": {...}}`

#### 2. Get Freelancer Profile
- **Method:** `GET`
- **URL:** `/api/freelancer/`
- **Headers:** `Authorization: Bearer <token>`
- **Response `200`:**
```json
{
  "freelancer": {
    "_id": "...",
    "userId": "...",
    "phone": "...",
    "category": "Professional",
    "state": "...",
    "city": "...",
    "pincode": "...",
    "profilePicture": { "url": "...", "fileId": "..." }
  },
  "details": { ... },
  "progress": {
    "received": ["<requestId>"],
    "accepted": ["<requestId>"],
    "attended": ["<requestId>"],
    "rejected": ["<requestId>"],
    "redflag": ["<requestId>"]
  }
}
```

#### 3. Update Freelancer Profile
- **Method:** `PUT`
- **URL:** `/api/freelancer/update`
- **Headers:** `Authorization: Bearer <token>`
- **Body:** Any of `{ "phone", "linkedin", "category", "state", "city", "pincode" }`
- **Response `200`:** `{"message": "Freelancer account updated successfully", "freelancer": {...}}`

#### 4. Upload Profile Picture (ImageKit)
- **Method:** `POST`
- **URL:** `/api/freelancer/upload-profile-picture` *(or `/api/freelancer/profile-picture`)*
- **Headers:**
  - `Authorization: Bearer <token>`
  - `Content-Type: multipart/form-data`
- **Form Data Field:** `profilePicture` (file binary, max 5MB, JPG/PNG/WebP/GIF)
- **Response `200`:**
```json
{
  "message": "Profile picture uploaded successfully",
  "profilePicture": "https://ik.imagekit.io/plannora/plannora/freelancers/profile-pictures/...",
  "fileId": "..."
}
```

#### 5. Fetch Only Profile Picture
- **Method:** `GET`
- **URL:** `/api/freelancer/profile-picture` *(or `/api/freelancer/profile-picture/:id`)*
- **Response `200`:**
```json
{
  "profilePicture": "https://ik.imagekit.io/plannora/plannora/freelancers/profile-pictures/..."
}
```

---

### 3.3 Customer Routes (`/api/customer`)

#### 1. Create Customer Account
- **Method:** `POST`
- **URL:** `/api/customer/create`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "phoneno": "+919876543210",
  "state": "Maharashtra",
  "city": "Mumbai",
  "pincode": "400001"
}
```
- **Response `201`:** `{"message": "Customer account created successfully", "customer": {...}}`

#### 2. Get Customer Profile
- **Method:** `GET`
- **URL:** `/api/customer/`
- **Headers:** `Authorization: Bearer <token>`
- **Response `200`:**
```json
{
  "customer": {
    "_id": "...",
    "account": "...",
    "phoneno": "...",
    "state": "...",
    "city": "...",
    "pincode": "...",
    "sent_request": ["<requestId>"],
    "profilePicture": { "url": "...", "fileId": "..." }
  }
}
```

#### 3. Update Customer Profile
- **Method:** `PUT`
- **URL:** `/api/customer/update`
- **Headers:** `Authorization: Bearer <token>`
- **Body:** Any of `{ "phoneno", "state", "city", "pincode" }`

#### 4. Upload Profile Picture
- **Method:** `POST`
- **URL:** `/api/customer/upload-profile-picture` *(or `/api/customer/profile-picture`)*
- **Headers:** `Authorization: Bearer <token>`, `Content-Type: multipart/form-data`
- **Form Data Field:** `profilePicture` (file binary)
- **Response `200`:**
```json
{
  "message": "Profile picture uploaded successfully",
  "profilePicture": "https://ik.imagekit.io/plannora/plannora/customers/profile-pictures/...",
  "fileId": "..."
}
```

#### 5. Fetch Only Profile Picture
- **Method:** `GET`
- **URL:** `/api/customer/profile-picture` *(or `/api/customer/profile-picture/:id`)*
- **Response `200`:**
```json
{
  "profilePicture": "https://ik.imagekit.io/plannora/plannora/customers/profile-pictures/..."
}
```

---

### 3.4 Event Request Management (`/api/request`) - Customer / Host

#### 1. Create Event Request
- **Method:** `POST`
- **URL:** `/api/request/create`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "event_details": "Corporate Gala & Product Launch",
  "pay": 5000,
  "state": "Maharashtra",
  "city": "Mumbai",
  "pincode": "400001",
  "location": "Grand Ballroom, Hotel Taj",
  "category": "Professional",
  "date": "2026-11-20",
  "time": "18:00",
  "end_time": "22:00",
  "no_of_candidates": 5
}
```
- **Response `201`:**
```json
{
  "message": "Request created successfully",
  "request": {
    "_id": "...",
    "attendance_code": "482910",
    "customer": "...",
    "event_details": "...",
    "pay": 5000,
    "no_of_candidates": 5,
    "status": "pending"
  }
}
```
*(Note: A secret 6-digit `attendance_code` is automatically generated for the customer to share at the venue).*

#### 2. Get All Requests Created by Customer
- **Method:** `GET`
- **URL:** `/api/request/`
- **Headers:** `Authorization: Bearer <token>`
- **Response `200`:**
```json
{
  "requests": [
    {
      "request": { "_id": "...", "event_details": "...", "attendance_code": "482910" },
      "progress": {
        "sent": ["<freelancerId>"],
        "accepted": ["<freelancerId>"],
        "rejected": []
      }
    }
  ]
}
```

#### 3. Get Single Request by ID
- **Method:** `GET`
- **URL:** `/api/request/:id`
- **Headers:** `Authorization: Bearer <token>`

#### 4. Update Event Request
- **Method:** `PUT`
- **URL:** `/api/request/:id`
- **Headers:** `Authorization: Bearer <token>`
- **Body:** Updatable fields: `event_details`, `pay`, `state`, `city`, `pincode`, `location`, `time`, `end_time`, `date`, `no_of_candidates`.

#### 5. Remove Freelancer From Accepted List
- **Method:** `DELETE`
- **URL:** `/api/request/:requestId/freelancer/:freelancerId`
- **Headers:** `Authorization: Bearer <token>`
- **Response `200`:** Automatically frees a slot and triggers `notifyWaitlistedFreelancers` (which sends an in-app phone notification to the next waitlisted freelancer!).

#### 6. Remind Accepted Freelancers to Enter Attendance Code
- **Method:** `POST`
- **URL:** `/api/request/:requestId/remind-attendance`
- **Headers:** `Authorization: Bearer <token>`
- **Behavior:** Checks all freelancers who accepted the event but haven't entered the attendance code yet, and sends **both an In-App Phone Notification and an Email**!
- **Response `200`:** `{"message": "Attendance reminder sent to 3 pending freelancer(s)", "notifiedCount": 3}`

---

### 3.5 Freelancer Event Actions (`/api/freelancer-request`)

#### 1. Accept Request (With Auto-Waitlist Overflow)
- **Method:** `POST`
- **URL:** `/api/freelancer-request/:requestId/accept`
- **Headers:** `Authorization: Bearer <token>`
- **Responses:**
  - `200 OK`: `{"success": true, "message": "Request accepted successfully"}`
  - `409 Conflict (Slots Full -> Auto Added to Waitlist)`:
    ```json
    {
      "success": false,
      "message": "All 5 slots filled. You've been added to the waitlist. We'll notify you if a slot becomes available."
    }
    ```

#### 2. Reject Request
- **Method:** `POST`
- **URL:** `/api/freelancer-request/:requestId/reject`
- **Headers:** `Authorization: Bearer <token>`
- **Response `200`:** `{"success": true, "message": "Request rejected"}`

#### 3. Submit Attendance Code (At the Event)
- **Method:** `POST`
- **URL:** `/api/freelancer-request/:requestId/attendance`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "code": "482910"
}
```
- **Responses:**
  - `200 OK`: `{"success": true, "message": "Attendance recorded successfully"}`
  - `400 Bad Request`: `{"success": false, "message": "Invalid attendance code"}`
  - `403 Forbidden`: `{"success": false, "message": "Attendance is not open yet"}` or `"Attendance window is closed"`

#### 4. Submit Redflag (Incident Report)
- **Method:** `POST`
- **URL:** `/api/freelancer-request/:requestId/redflag`
- **Headers:** `Authorization: Bearer <token>`
- **Body:** `{ "reason": "Host did not show up" }`
- **Response `200`:** `{"success": true, "message": "Redflag recorded"}`

---

### 3.6 Phone & In-App Notifications (`/api/notifications`)

#### 1. Register Device Push Token
- **Method:** `POST`
- **URL:** `/api/notifications/register-device`
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
```json
{
  "pushToken": "ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]"
}
```
*(Call this when the Flutter app launches to register the phone for lock-screen push notifications).*

#### 2. Get Notifications
- **Method:** `GET`
- **URL:** `/api/notifications` *(or `/api/notifications?unreadOnly=true&limit=20`)*
- **Headers:** `Authorization: Bearer <token>`
- **Response `200`:**
```json
{
  "unreadCount": 2,
  "notifications": [
    {
      "_id": "660c...",
      "title": "Spot Available!",
      "message": "A slot just opened up for \"Corporate Gala\". You can now accept this request before slots fill up!",
      "type": "WAITLIST_SLOT_AVAILABLE",
      "requestId": {
        "_id": "660b...",
        "event_details": "Corporate Gala",
        "category": "Professional",
        "pay": 5000,
        "date": "2026-11-20"
      },
      "read": false,
      "createdAt": "2026-10-16T12:00:00.000Z"
    },
    {
      "_id": "660d...",
      "title": "Action Required: Enter Attendance Code",
      "message": "You have not yet entered the attendance code for \"Music Festival\". Please ask the host for the code and submit it in the app.",
      "type": "ATTENDANCE_CODE_REMINDER",
      "read": false,
      "createdAt": "2026-10-16T11:30:00.000Z"
    }
  ]
}
```

#### 3. Mark Single Notification Read
- **Method:** `PATCH`
- **URL:** `/api/notifications/:id/read`
- **Headers:** `Authorization: Bearer <token>`
- **Response `200`:** `{"message": "Notification marked as read"}`

#### 4. Mark All Notifications Read
- **Method:** `PATCH`
- **URL:** `/api/notifications/read-all`
- **Headers:** `Authorization: Bearer <token>`
- **Response `200`:** `{"message": "All notifications marked as read"}`

---

## 4. Flutter Setup Reference (`pubspec.yaml`)

Place these dependencies into `frontend/pubspec.yaml`:

```yaml
name: plannora_frontend
description: "Plannora Student Event & Hospitality Platform"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  dio: ^5.4.1
  flutter_secure_storage: ^9.0.0
  provider: ^6.1.2
  image_picker: ^1.0.7
  intl: ^0.19.0
  cached_network_image: ^3.3.1
  google_fonts: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

---

## 5. Ready-to-Use Flutter Core Services

### 5.1 `lib/core/constants/api_constants.dart`
```dart
class ApiConstants {
  // Production URL on Render
  static const String baseUrl = 'https://plannoraapp-1.onrender.com';

  // Auth Endpoints
  static const String register = '/api/auth/register';
  static const String verifyOtp = '/api/auth/verifyotp';
  static const String login = '/api/auth/login';
  static const String forgotPassword = '/api/auth/forgotpassword';
  static const String verifyForgotOtp = '/api/auth/verifyforgototp';
  static const String resetPassword = '/api/auth/resetpassword';
  static const String profile = '/api/auth/profile';
  static const String logout = '/api/auth/logout';

  // Freelancer Endpoints
  static const String freelancerCreate = '/api/freelancer/create';
  static const String freelancerProfile = '/api/freelancer';
  static const String freelancerUpdate = '/api/freelancer/update';
  static const String freelancerUploadPic = '/api/freelancer/upload-profile-picture';
  static const String freelancerGetPic = '/api/freelancer/profile-picture';

  // Customer Endpoints
  static const String customerCreate = '/api/customer/create';
  static const String customerProfile = '/api/customer';
  static const String customerUpdate = '/api/customer/update';
  static const String customerUploadPic = '/api/customer/upload-profile-picture';
  static const String customerGetPic = '/api/customer/profile-picture';

  // Request Endpoints
  static const String requestCreate = '/api/request/create';
  static const String requestList = '/api/request';
  static String requestDetails(String id) => '/api/request/$id';
  static String removeFreelancer(String reqId, String freeId) =>
      '/api/request/$reqId/freelancer/$freeId';
  static String remindAttendance(String reqId) =>
      '/api/request/$reqId/remind-attendance';

  // Freelancer Event Actions
  static String acceptRequest(String id) => '/api/freelancer-request/$id/accept';
  static String rejectRequest(String id) => '/api/freelancer-request/$id/reject';
  static String submitAttendance(String id) =>
      '/api/freelancer-request/$id/attendance';
  static String submitRedflag(String id) =>
      '/api/freelancer-request/$id/redflag';

  // Notification Endpoints
  static const String notifications = '/api/notifications';
  static const String registerDevice = '/api/notifications/register-device';
  static const String markAllRead = '/api/notifications/read-all';
  static String markRead(String id) => '/api/notifications/$id/read';
}
```

### 5.2 `lib/core/services/api_client.dart`
```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auto-inject Bearer Token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  // Token Helpers
  Future<void> saveToken(String token) async =>
      await _storage.write(key: 'jwt_token', value: token);

  Future<String?> getToken() async =>
      await _storage.read(key: 'jwt_token');

  Future<void> deleteToken() async =>
      await _storage.delete(key: 'jwt_token');
}
```

---

## 6. Prompt to Give Claude to Generate the Entire Flutter App

Copy and paste the prompt below into Claude:

```markdown
I have a complete Node.js/Express backend running at "https://plannoraapp-1.onrender.com".
Please generate the complete, production-grade Flutter application code inside the direct "frontend/" folder (no nested folders inside frontend).

Refer to the complete API specifications, route schemas, and response models documented in `FLUTTER_API_INTEGRATION_GUIDE.md`:
1. Use Dio with the ApiClient that attaches "Authorization: Bearer <token>" from FlutterSecureStorage.
2. Implement User Authentication: Register with OTP, Login, Forgot Password OTP, and Profile fetching.
3. Support Role Switch / Multi-profile: Freelancer Profile and Customer Profile with Profile Picture uploads using ImagePicker + multipart POST to ImageKit endpoints.
4. Freelancer Event Flow: View assigned requests, Accept (handle 409 waitlist overflow gracefully), Reject, and Enter 6-digit Attendance Code popup.
5. Customer Event Flow: Create Event Request (auto-generates 6-digit attendance code), View Created Events with Accepted/Sent freelancer lists, Remove Freelancer, and trigger "Remind Attendance" button.
6. Notification Center: Display in-app phone notifications (Waitlist Slot Available, Attendance Code Reminder), mark as read, and register device push token on launch.
7. Use modern, beautiful UI with Provider state management. Provide complete, working Dart code for all files.
```
