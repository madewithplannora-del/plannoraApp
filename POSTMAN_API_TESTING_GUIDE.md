# 🚀 Plannora Backend API Documentation & Postman Testing Guide

> **Base URL:** `http://localhost:3001`  
> **Android Emulator Base URL:** `http://10.0.2.2:3001`  
> **Default Port:** `3001`  
> **Content-Type:** `application/json` (unless file upload via `multipart/form-data`)

---

## 🔑 Authentication Overview for Postman

- All protected routes require a JWT token.
- You can provide the token in **Postman** in two ways:
  1. **Bearer Token (Recommended for Postman):**
     - Go to the **Headers** tab:  
       `Authorization`: `Bearer <YOUR_JWT_TOKEN>`  
       *(or configure in Postman's **Auth** tab with Type: **Bearer Token**)*
  2. **Cookies:**  
     - Postman automatically stores and passes cookies (like `accesstoken` and `resettoken`) after you execute `/api/auth/login` or `/api/auth/verifyotp`.

---

## 📑 Complete API Routes Index

| # | Group | Method | Endpoint / Complete URL | Auth Required | Description |
|---|---|:---:|---|:---:|---|
| 1 | Health | `GET` | `http://localhost:3001/` | No | Server status check |
| 2 | Auth | `POST` | `http://localhost:3001/api/auth/register` | No | Register new user & sends OTP |
| 3 | Auth | `POST` | `http://localhost:3001/api/auth/verifyotp` | No | Verify registration OTP & creates account |
| 4 | Auth | `POST` | `http://localhost:3001/api/auth/login` | No | Login with username/email & password |
| 5 | Auth | `POST` | `http://localhost:3001/api/auth/forgotpassword` | No | Send OTP for password reset |
| 6 | Auth | `POST` | `http://localhost:3001/api/auth/verifyforgototp` | No | Verify forgot password OTP & issues reset token |
| 7 | Auth | `POST` | `http://localhost:3001/api/auth/resetpassword` | Reset Cookie | Set new password |
| 8 | Auth | `POST` | `http://localhost:3001/api/auth/logout` | No | Clears auth & reset cookies |
| 9 | Auth | `GET` | `http://localhost:3001/api/auth/profile` | **Yes** | Get current logged-in user profile |
| 10 | Customer | `POST` | `http://localhost:3001/api/customer/create` | **Yes** | Create customer profile (with optional `image` file) |
| 11 | Customer | `GET` | `http://localhost:3001/api/customer` | **Yes** | Get customer profile |
| 12 | Customer | `PUT` | `http://localhost:3001/api/customer/update` | **Yes** | Update customer profile (with optional `image` file) |
| 13 | Customer | `DELETE` | `http://localhost:3001/api/customer/delete` | **Yes** | Delete customer profile |
| 14 | Customer | `GET` | `http://localhost:3001/api/customer/profile-picture` | **Yes** | Get own customer profile picture |
| 15 | Customer | `GET` | `http://localhost:3001/api/customer/profile-picture/:id` | No | Get customer profile picture by ID |
| 16 | Freelancer | `POST` | `http://localhost:3001/api/freelancer/create` | **Yes** | Create freelancer profile (with optional `image` file) |
| 17 | Freelancer | `GET` | `http://localhost:3001/api/freelancer` | **Yes** | Get freelancer profile, details & progress |
| 18 | Freelancer | `PUT` | `http://localhost:3001/api/freelancer/update` | **Yes** | Update freelancer profile (with optional `image` file) |
| 19 | Freelancer | `DELETE` | `http://localhost:3001/api/freelancer/delete` | **Yes** | Delete freelancer account |
| 20 | Freelancer | `GET` | `http://localhost:3001/api/freelancer/profile-picture` | **Yes** | Get own freelancer profile picture |
| 21 | Freelancer | `GET` | `http://localhost:3001/api/freelancer/profile-picture/:id` | No | Get freelancer profile picture by ID |
| 22 | Request | `POST` | `http://localhost:3001/api/request/create` | **Yes (Customer)** | Create new event request |
| 23 | Request | `GET` | `http://localhost:3001/api/request` | **Yes (Customer)** | Get all requests by logged-in customer |
| 24 | Request | `GET` | `http://localhost:3001/api/request/:id` | **Yes (Customer)** | Get request details by ID |
| 25 | Request | `PUT` | `http://localhost:3001/api/request/:id` | **Yes (Customer)** | Update request details |
| 26 | Request | `DELETE` | `http://localhost:3001/api/request/:id` | **Yes (Customer)** | Delete request by ID |
| 27 | Request | `DELETE` | `http://localhost:3001/api/request/:requestId/freelancer/:freelancerId` | **Yes (Customer)** | Remove accepted freelancer |
| 28 | Request | `POST` | `http://localhost:3001/api/request/:requestId/remind-attendance` | **Yes** | Send attendance reminder emails & pushes |
| 29 | Freelancer Action | `POST` | `http://localhost:3001/api/freelancer-request/:requestId/accept` | **Yes (Freelancer)** | Accept request opportunity |
| 30 | Freelancer Action | `POST` | `http://localhost:3001/api/freelancer-request/:requestId/reject` | **Yes (Freelancer)** | Reject request opportunity |
| 31 | Freelancer Action | `POST` | `http://localhost:3001/api/freelancer-request/:requestId/attendance` | **Yes (Freelancer)** | Submit attendance code at event |
| 32 | Freelancer Action | `POST` | `http://localhost:3001/api/freelancer-request/:requestId/redflag` | **Yes (Freelancer)** | Submit redflag code |
| 33 | Notifications | `GET` | `http://localhost:3001/api/notifications` | **Yes** | Get all notifications for user |
| 34 | Notifications | `POST` | `http://localhost:3001/api/notifications/register-device` | **Yes** | Register device push token |
| 35 | Notifications | `PATCH` | `http://localhost:3001/api/notifications/read-all` | **Yes** | Mark all notifications as read |
| 36 | Notifications | `PATCH` | `http://localhost:3001/api/notifications/:id/read` | **Yes** | Mark single notification as read |

---

# 📦 Detailed Postman Route Specifications

---

## 1. System Health Check

### `GET http://localhost:3001/`
- **Method:** `GET`
- **Headers:** None
- **Body:** None
- **Success Response (200 OK):**
```json
{
  "message": "running"
}
```

---

## 2. Authentication Routes (`/api/auth`)

### 2.1 Register User
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/auth/register`
- **Headers:**  
  `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "username": "alex_johnson",
  "email": "alex.johnson@example.com",
  "password": "StrongPassword123"
}
```
- **Validation Rules:**
  - `username`: 3 to 30 characters
  - `password`: minimum 8 characters
- **Success Response (200 OK):**
```json
{
  "message": "Verification OTP sent to your email"
}
```

---

### 2.2 Verify Registration OTP
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/auth/verifyotp`
- **Headers:**  
  `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "email": "alex.johnson@example.com",
  "otp": "123456"
}
```
*(Check your terminal / email console logs for the generated OTP)*
- **Success Response (200 OK):**
```json
{
  "message": "Account created and email verified successfully",
  "token": "eyJhbGciOiJIUzI1NiIsIn...",
  "user": {
    "id": "67104d416b2512140f7b9821",
    "username": "alex_johnson",
    "email": "alex.johnson@example.com",
    "emailVerified": true
  }
}
```
> **Note:** Copy the `token` from this response and use it as `Bearer <token>` in subsequent requests!

---

### 2.3 Login User
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/auth/login`
- **Headers:**  
  `Content-Type: application/json`
- **Body Option A (using email):**
```json
{
  "email": "alex.johnson@example.com",
  "password": "StrongPassword123"
}
```
- **Body Option B (using username):**
```json
{
  "username": "alex_johnson",
  "password": "StrongPassword123"
}
```
- **Success Response (200 OK):**
```json
{
  "message": "Logged in",
  "token": "eyJhbGciOiJIUzI1NiIsIn...",
  "user": {
    "id": "67104d416b2512140f7b9821",
    "username": "alex_johnson",
    "email": "alex.johnson@example.com",
    "emailVerified": true
  }
}
```

---

### 2.4 Forgot Password (Send OTP)
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/auth/forgotpassword`
- **Headers:**  
  `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "email": "alex.johnson@example.com"
}
```
- **Success Response (200 OK):**
```json
{
  "message": "Password reset OTP sent to email"
}
```

---

### 2.5 Verify Forgot Password OTP
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/auth/verifyforgototp`
- **Headers:**  
  `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "email": "alex.johnson@example.com",
  "otp": "123456"
}
```
- **Success Response (200 OK):** Sets the `resettoken` cookie (expires in 2 minutes).
```json
{
  "message": "OTP verified successfully"
}
```

---

### 2.6 Reset Password
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/auth/resetpassword`
- **Headers:**  
  `Content-Type: application/json`
- **Cookies:** Must include `resettoken` cookie (sent automatically by Postman if calling after step 2.5)
- **Body (raw JSON):**
```json
{
  "resetpassword": "NewStrongPassword456"
}
```
- **Success Response (200 OK):**
```json
{
  "message": "Password reset successfully"
}
```

---

### 2.7 Get Current User Profile
- **Method:** `GET`
- **URL:** `http://localhost:3001/api/auth/profile`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Body:** None
- **Success Response (200 OK):**
```json
{
  "user": {
    "id": "67104d416b2512140f7b9821",
    "username": "alex_johnson",
    "email": "alex.johnson@example.com",
    "emailVerified": true
  }
}
```

---

### 2.8 Logout User
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/auth/logout`
- **Headers:** None
- **Body:** None
- **Success Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

---

## 3. Customer Profile Routes (`/api/customer`)

### 3.1 Create Customer Profile
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/customer/create`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`  
  `Content-Type: application/json`
- **Body Option A (raw JSON):**
```json
{
  "phoneno": "9876543210",
  "state": "Maharashtra",
  "city": "Mumbai",
  "pincode": "400001"
}
```
- **Body Option B (form-data in Postman):**
  - Select **Body** -> **form-data**
  - Add the following keys (Keep Type as **Text**):

| Key | Type | Value (Example) | Required / Note |
|---|:---:|---|---|
| `phoneno` | Text | `9876543210` | Required |
| `state` | Text | `Maharashtra` | Required |
| `city` | Text | `Mumbai` | Required |
| `pincode` | Text | `400001` | Required |
| `image` | **File** | *(Choose file)* | **Optional** profile image (`.png`, `.jpg`, `.jpeg`, `.webp`) |

- **Success Response (201 Created):**
```json
{
  "message": "Customer account created successfully",
  "customer": {
    "_id": "67104f216b2512140f7b9835",
    "account": "67104d416b2512140f7b9821",
    "phoneno": "9876543210",
    "state": "Maharashtra",
    "city": "Mumbai",
    "pincode": "400001",
    "sent_request": [],
    "profilePicture": {
      "url": "https://ik.imagekit.io/plannora/customers/...",
      "fileId": "671050..."
    }
  }
}
```

---

### 3.2 Get Customer Profile
- **Method:** `GET`
- **URL:** `http://localhost:3001/api/customer`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Body:** None
- **Success Response (200 OK):**
```json
{
  "customer": {
    "_id": "67104f216b2512140f7b9835",
    "account": "67104d416b2512140f7b9821",
    "phoneno": "9876543210",
    "state": "Maharashtra",
    "city": "Mumbai",
    "pincode": "400001",
    "sent_request": []
  }
}
```

---

### 3.3 Update Customer Profile
- **Method:** `PUT`
- **URL:** `http://localhost:3001/api/customer/update`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Body Option A (raw JSON):** *(Provide one or more fields)*
```json
{
  "phoneno": "9876543299",
  "city": "Pune",
  "state": "Maharashtra",
  "pincode": "411001"
}
```
- **Body Option B (form-data in Postman):**
  - Select **Body** -> **form-data**
  - Add any fields you want to update:

| Key | Type | Value (Example) | Note |
|---|:---:|---|---|
| `phoneno` | Text | `9876543299` | Optional |
| `city` | Text | `Pune` | Optional |
| `state` | Text | `Maharashtra` | Optional |
| `pincode` | Text | `411001` | Optional |
| `image` | **File** | *(Choose file)* | **Optional** new profile image |

- **Success Response (200 OK):**
```json
{
  "message": "Customer account updated successfully",
  "customer": { ... }
}
```

---

### 3.4 Get Customer Profile Picture
- **Method:** `GET`
- **URL (Self):** `http://localhost:3001/api/customer/profile-picture`  
  - Headers: `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **URL (By ID):** `http://localhost:3001/api/customer/profile-picture/67104f216b2512140f7b9835`
- **Success Response (200 OK):**
```json
{
  "profilePicture": "https://ik.imagekit.io/plannora/customers/..."
}
```

---

### 3.5 Delete Customer Profile
- **Method:** `DELETE`
- **URL:** `http://localhost:3001/api/customer/delete`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Success Response (200 OK):**
```json
{
  "message": "Customer account deleted successfully"
}
```

---

## 4. Freelancer Profile Routes (`/api/freelancer`)

### 4.1 Create Freelancer Profile
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/freelancer/create`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`  
  `Content-Type: application/json`
- **Body Option A (raw JSON):**
```json
{
  "phone": "9123456789",
  "linkedin": "https://linkedin.com/in/freelancer-pro",
  "category": "Professional",
  "state": "Maharashtra",
  "city": "Mumbai",
  "pincode": "400001"
}
```
- **Body Option B (form-data in Postman):**
  - Select **Body** -> **form-data**
  - Add the following keys (Keep Type as **Text**):

| Key | Type | Value (Example) | Allowed / Constraints |
|---|:---:|---|---|
| `phone` | Text | `9123456789` | Required |
| `linkedin` | Text | `https://linkedin.com/in/freelancer-pro` | Optional |
| `category` | Text | `Professional` | Must be: `Professional`, `Cultural`, or `Private` |
| `state` | Text | `Maharashtra` | Required |
| `city` | Text | `Mumbai` | Required |
| `pincode` | Text | `400001` | Required |
| `image` | **File** | *(Choose file)* | **Optional** profile image (`.png`, `.jpg`, `.jpeg`, `.webp`) |

- **Success Response (201 Created):**
```json
{
  "message": "Freelancer account created successfully",
  "freelancer": {
    "_id": "671051216b2512140f7b9845",
    "userId": "67104d416b2512140f7b9821",
    "phone": "9123456789",
    "linkedin": "https://linkedin.com/in/freelancer-pro",
    "category": "Professional",
    "state": "Maharashtra",
    "city": "Mumbai",
    "pincode": "400001",
    "profilePicture": {
      "url": "https://ik.imagekit.io/plannora/freelancers/...",
      "fileId": "671052..."
    }
  }
}
```

---

### 4.2 Get Freelancer Profile (with Details & Progress)
- **Method:** `GET`
- **URL:** `http://localhost:3001/api/freelancer`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Success Response (200 OK):**
```json
{
  "freelancer": {
    "_id": "671051216b2512140f7b9845",
    "userId": "67104d416b2512140f7b9821",
    "phone": "9123456789",
    "category": "Professional"
  },
  "details": {
    "category": "Professional",
    "state": "Maharashtra",
    "city": "Mumbai",
    "pincode": "400001"
  },
  "progress": {
    "received": [],
    "accepted": [],
    "attended": [],
    "rejected": [],
    "redflag": []
  }
}
```

---

### 4.3 Update Freelancer Profile
- **Method:** `PUT`
- **URL:** `http://localhost:3001/api/freelancer/update`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Body Option A (raw JSON):**
```json
{
  "phone": "9123456799",
  "linkedin": "https://linkedin.com/in/freelancer-updated",
  "category": "Cultural",
  "city": "Pune",
  "state": "Maharashtra",
  "pincode": "411001"
}
```
- **Body Option B (form-data in Postman):**
  - Select **Body** -> **form-data**
  - Add any fields you want to update:

| Key | Type | Value (Example) | Allowed / Constraints |
|---|:---:|---|---|
| `phone` | Text | `9123456799` | Optional |
| `category` | Text | `Cultural` | Optional (`Professional`, `Cultural`, or `Private`) |
| `city` | Text | `Pune` | Optional |
| `state` | Text | `Maharashtra` | Optional |
| `pincode` | Text | `411001` | Optional |
| `linkedin` | Text | `https://linkedin.com/in/updated-profile` | Optional |
| `image` | **File** | *(Choose file)* | **Optional** new profile image |

- **Success Response (200 OK):**
```json
{
  "message": "Freelancer account updated successfully",
  "freelancer": { ... }
}
```

---

### 4.4 Get Freelancer Profile Picture
- **Method:** `GET`
- **URL (Self):** `http://localhost:3001/api/freelancer/profile-picture`  
  - Headers: `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **URL (By ID):** `http://localhost:3001/api/freelancer/profile-picture/671051216b2512140f7b9845`
- **Success Response (200 OK):**
```json
{
  "profilePicture": "https://ik.imagekit.io/plannora/freelancers/..."
}
```

---

### 4.5 Delete Freelancer Profile
- **Method:** `DELETE`
- **URL:** `http://localhost:3001/api/freelancer/delete`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Success Response (200 OK):**
```json
{
  "message": "Freelancer account deleted successfully"
}
```

---

## 5. Event Requests Routes (`/api/request`)

> **Note:** The logged-in user MUST have a Customer profile created before calling these endpoints.

### 5.1 Create Event Request
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/request/create`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`  
  `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "event_details": "Corporate Tech Expo 2026",
  "pay": 3500,
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001",
  "location": "Jio World Convention Centre, BKC",
  "category": "Professional",
  "time": "09:00 AM - 05:00 PM",
  "start_time": "2026-11-25T09:00:00.000Z",
  "end_time": "2026-11-25T17:00:00.000Z",
  "date": "2026-11-25T00:00:00.000Z",
  "no_of_candidates": 2,
  "additional_description": "Formal attire required. Badge distribution & attendee assistance."
}
```
- **Success Response (201 Created):**
```json
{
  "message": "Request created successfully",
  "request": {
    "_id": "671053006b2512140f7b9860",
    "customer": "67104f216b2512140f7b9835",
    "event_details": "Corporate Tech Expo 2026",
    "pay": 3500,
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001",
    "location": "Jio World Convention Centre, BKC",
    "category": "Professional",
    "time": "09:00 AM - 05:00 PM",
    "start_time": "2026-11-25T09:00:00.000Z",
    "end_time": "2026-11-25T17:00:00.000Z",
    "no_of_candidates": 2,
    "date": "2026-11-25T00:00:00.000Z",
    "additional_description": "Formal attire required. Badge distribution & attendee assistance."
  },
  "completion_code": "847291"
}
```

---

### 5.2 Get All Requests (by Customer)
- **Method:** `GET`
- **URL:** `http://localhost:3001/api/request`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Success Response (200 OK):**
```json
{
  "message": "Requests fetched successfully",
  "count": 1,
  "requests": [ ... ]
}
```

---

### 5.3 Get Single Request by ID
- **Method:** `GET`
- **URL:** `http://localhost:3001/api/request/671053006b2512140f7b9860`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Success Response (200 OK):**
```json
{
  "message": "Request fetched successfully",
  "request": { ... }
}
```

---

### 5.4 Update Request
- **Method:** `PUT`
- **URL:** `http://localhost:3001/api/request/671053006b2512140f7b9860`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`  
  `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "pay": 4000,
  "no_of_candidates": 3,
  "additional_description": "Updated pay and candidate requirements."
}
```
- **Success Response (200 OK):**
```json
{
  "message": "Request updated successfully",
  "request": { ... }
}
```

---

### 5.5 Delete Request
- **Method:** `DELETE`
- **URL:** `http://localhost:3001/api/request/671053006b2512140f7b9860`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Success Response (200 OK):**
```json
{
  "message": "Request deleted successfully"
}
```

---

### 5.6 Remove Accepted Freelancer (Customer Action)
- **Method:** `DELETE`
- **URL:** `http://localhost:3001/api/request/:requestId/freelancer/:freelancerId`
  - Example: `http://localhost:3001/api/request/671053006b2512140f7b9860/freelancer/671051216b2512140f7b9845`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Success Response (200 OK):**
```json
{
  "message": "Freelancer removed successfully. Waitlisted freelancers have been notified.",
  "slots_available": 1
}
```

---

### 5.7 Remind Accepted Freelancers (Attendance)
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/request/:requestId/remind-attendance`
  - Example: `http://localhost:3001/api/request/671053006b2512140f7b9860/remind-attendance`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Body:** None
- **Success Response (200 OK):**
```json
{
  "message": "Reminders sent successfully",
  "notifiedCount": 2
}
```

---

## 6. Freelancer Opportunity Actions (`/api/freelancer-request`)

> **Note:** The logged-in user MUST be registered as a Freelancer.

### 6.1 Accept Request
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/freelancer-request/:requestId/accept`
  - Example: `http://localhost:3001/api/freelancer-request/671053006b2512140f7b9860/accept`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Body:** None
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Request accepted",
  "accepted_count": 1,
  "no_of_candidates": 2,
  "slots_left": 1
}
```

---

### 6.2 Reject Request
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/freelancer-request/:requestId/reject`
  - Example: `http://localhost:3001/api/freelancer-request/671053006b2512140f7b9860/reject`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Body:** None
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Request rejected"
}
```

---

### 6.3 Submit Attendance Code at Event
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/freelancer-request/:requestId/attendance`
  - Example: `http://localhost:3001/api/freelancer-request/671053006b2512140f7b9860/attendance`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`  
  `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "code": "847291"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Attendance recorded"
}
```

---

### 6.4 Submit Redflag Code at Event
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/freelancer-request/:requestId/redflag`
  - Example: `http://localhost:3001/api/freelancer-request/671053006b2512140f7b9860/redflag`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`  
  `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "code": "847291"
}
```
- **Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Redflag recorded"
}
```

---

## 7. Notifications Routes (`/api/notifications`)

### 7.1 Get Notifications
- **Method:** `GET`
- **URL:** `http://localhost:3001/api/notifications`  
  *(Optional queries: `http://localhost:3001/api/notifications?unreadOnly=true&limit=20`)*
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Success Response (200 OK):**
```json
{
  "notifications": [
    {
      "_id": "671055006b2512140f7b9870",
      "recipientId": "671051216b2512140f7b9845",
      "title": "New Event Opportunity",
      "body": "You have a new match for Corporate Tech Expo 2026",
      "type": "NEW_REQUEST",
      "read": false,
      "createdAt": "2026-10-16T13:40:00.000Z"
    }
  ],
  "unreadCount": 1
}
```

---

### 7.2 Register Mobile Push Token
- **Method:** `POST`
- **URL:** `http://localhost:3001/api/notifications/register-device`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`  
  `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "pushToken": "ExponentPushToken[AbCdEf1234567890]"
}
```
- **Success Response (200 OK):**
```json
{
  "message": "Device push token registered successfully"
}
```

---

### 7.3 Mark Single Notification as Read
- **Method:** `PATCH`
- **URL:** `http://localhost:3001/api/notifications/:id/read`
  - Example: `http://localhost:3001/api/notifications/671055006b2512140f7b9870/read`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Body:** None
- **Success Response (200 OK):**
```json
{
  "message": "Notification marked as read",
  "notification": { ... }
}
```

---

### 7.4 Mark All Notifications as Read
- **Method:** `PATCH`
- **URL:** `http://localhost:3001/api/notifications/read-all`
- **Headers:**  
  `Authorization: Bearer <YOUR_ACCESS_TOKEN>`
- **Body:** None
- **Success Response (200 OK):**
```json
{
  "message": "All notifications marked as read"
}
```

---

## 💡 Postman Pro-Tips & Auto-Token Script

To avoid copying and pasting your `token` every time you log in, add this single line to the **Scripts -> Post-response** (or **Tests**) tab of your **Login** or **Verify OTP** request in Postman:

```javascript
if (pm.response.code === 200) {
    const jsonData = pm.response.json();
    if (jsonData.token) {
        pm.collectionVariables.set("jwt_token", jsonData.token);
        console.log("JWT Token automatically saved to collection variable!");
    }
}
```

Then in the collection's **Authorization** tab, set:
- **Type:** `Bearer Token`
- **Token:** `{{jwt_token}}`

All requests inside that collection will inherit the token automatically!
