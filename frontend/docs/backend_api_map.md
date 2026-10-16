# Backend API Map — PlanEra Mobile App Integration

> **Production Base URL:** `https://plannoraapp-1.onrender.com`  
> **Local Base URL (Android Emulator):** `http://10.0.2.2:3001`  
> **Source Authority:** Backend code in `backend/src/` (`routes/`, `controllers/`, `models/`, `middlewares/`).

---

## 1. Authentication & Security Architecture

### Authentication Mechanism
- **JWT (Bearer Token):** The backend issues an `accesstoken` on successful login and email OTP verification.
- **Header format:** `Authorization: Bearer <token>`
- **Cookie fallback:** The backend also sets `res.cookie("accesstoken", token, ...)` with HTTP-only cookies.
- **Mobile Strategy:** Flutter stores the JWT in secure storage (`flutter_secure_storage`) and sends `Authorization: Bearer <token>` on all authenticated requests. In addition, an HTTP client cookie jar can preserve cookies if needed.

---

## 2. Comprehensive Endpoint Matrix

### 2.1 System & Health

#### `GET /`
- **Method:** `GET`
- **Path:** `/`
- **Auth:** None
- **Response (200 OK):**
  ```json
  { "message": "running" }
  ```

---

### 2.2 Authentication Routes (`/api/auth`)

#### `POST /api/auth/register`
- **Method:** `POST`
- **Path:** `/api/auth/register`
- **Auth:** None (Rate limited: OTP limiter)
- **Request Body (JSON):**
  ```json
  {
    "username": "string (3-30 chars)",
    "email": "string (valid email)",
    "password": "string (min 8 chars)"
  }
  ```
- **Success (200 OK):**
  ```json
  { "message": "Verification OTP sent to your email" }
  ```
- **Errors:** 
  - `400`: Invalid length or missing fields
  - `409`: User already exists
  - `429`: Too many requests

#### `POST /api/auth/verifyotp`
- **Method:** `POST`
- **Path:** `/api/auth/verifyotp`
- **Auth:** None
- **Request Body (JSON):**
  ```json
  {
    "email": "string",
    "otp": "string | number (6 digits)"
  }
  ```
- **Success (200 OK):**
  ```json
  {
    "message": "Account created and email verified successfully",
    "token": "JWT_STRING",
    "user": {
      "id": "USER_ID",
      "username": "string",
      "email": "string",
      "emailVerified": true
    }
  }
  ```
- **Errors:**
  - `400`: OTP expired or invalid
  - `404`: OTP not found
  - `409`: User already exists
  - `429`: Too many invalid attempts (limit 5)

#### `POST /api/auth/login`
- **Method:** `POST`
- **Path:** `/api/auth/login`
- **Auth:** None (Rate limited: Login limiter)
- **Request Body (JSON):**
  ```json
  {
    "email": "string (optional if username provided)",
    "username": "string (optional if email provided)",
    "password": "string"
  }
  ```
- **Success (200 OK):**
  ```json
  {
    "message": "Logged in",
    "token": "JWT_STRING",
    "user": {
      "id": "USER_ID",
      "username": "string",
      "email": "string",
      "emailVerified": true
    }
  }
  ```
- **Errors:**
  - `400`: Missing credentials
  - `401`: Invalid credentials
  - `403`: Email not verified

#### `POST /api/auth/forgotpassword`
- **Method:** `POST`
- **Path:** `/api/auth/forgotpassword`
- **Auth:** None
- **Request Body (JSON):**
  ```json
  { "email": "string" }
  ```
- **Success (200 OK):**
  ```json
  { "message": "Password reset OTP sent to email" }
  ```

#### `POST /api/auth/verifyforgototp`
- **Method:** `POST`
- **Path:** `/api/auth/verifyforgototp`
- **Auth:** None
- **Request Body (JSON):**
  ```json
  {
    "email": "string",
    "otp": "string | number"
  }
  ```
- **Success (200 OK):**
  ```json
  { "message": "OTP verified successfully" }
  ```
  *(Sets `resettoken` cookie valid for 2 minutes)*

#### `POST /api/auth/resetpassword`
- **Method:** `POST`
- **Path:** `/api/auth/resetpassword`
- **Auth:** `resettoken` cookie
- **Request Body (JSON):**
  ```json
  { "resetpassword": "string (min 8 chars)" }
  ```
- **Success (200 OK):**
  ```json
  { "message": "Password reset successfully" }
  ```

#### `GET /api/auth/profile`
- **Method:** `GET`
- **Path:** `/api/auth/profile`
- **Auth:** Bearer Token
- **Success (200 OK):**
  ```json
  {
    "user": {
      "id": "USER_ID",
      "username": "string",
      "email": "string",
      "emailVerified": true
    }
  }
  ```

#### `POST /api/auth/logout`
- **Method:** `POST`
- **Path:** `/api/auth/logout`
- **Auth:** None required (clears cookies)
- **Success (200 OK):**
  ```json
  { "message": "Logged out successfully" }
  ```

---

### 2.3 Customer Management (`/api/customer`)

#### `POST /api/customer/create`
- **Method:** `POST`
- **Path:** `/api/customer/create`
- **Auth:** Bearer Token
- **Format:** `multipart/form-data` or `application/json`
- **Fields:**
  - `phoneno`: string (Required)
  - `state`: string (Required)
  - `city`: string (Required)
  - `pincode`: string (Required)
  - `image`: File (Optional image: `.jpg`, `.jpeg`, `.png`, `.webp`, max 5MB)
- **Success (201 Created):**
  ```json
  {
    "message": "Customer account created successfully",
    "customer": {
      "_id": "CUSTOMER_ID",
      "account": "USER_ID",
      "phoneno": "string",
      "state": "string",
      "city": "string",
      "pincode": "string",
      "sent_request": [],
      "profilePicture": { "url": "string | null", "fileId": "string | null" }
    }
  }
  ```
- **Errors:**
  - `401`: Token missing or invalid
  - `404`: User not found
  - `409`: Customer account already exists

#### `GET /api/customer`
- **Method:** `GET`
- **Path:** `/api/customer`
- **Auth:** Bearer Token
- **Success (200 OK):**
  ```json
  {
    "customer": {
      "_id": "CUSTOMER_ID",
      "account": "USER_ID",
      "phoneno": "string",
      "state": "string",
      "city": "string",
      "pincode": "string",
      "sent_request": ["REQUEST_IDS"],
      "profilePicture": { "url": "string | null", "fileId": "string | null" }
    }
  }
  ```
- **Errors:** `404`: Customer account not found

#### `PUT /api/customer/update`
- **Method:** `PUT`
- **Path:** `/api/customer/update`
- **Auth:** Bearer Token
- **Format:** `multipart/form-data` or `application/json`
- **Fields (all optional):** `phoneno`, `state`, `city`, `pincode`, `image` (file)
- **Success (200 OK):** Returns updated customer record.

#### `DELETE /api/customer/delete`
- **Method:** `DELETE`
- **Path:** `/api/customer/delete`
- **Auth:** Bearer Token
- **Success (200 OK):**
  ```json
  { "message": "Customer account deleted successfully" }
  ```

#### `GET /api/customer/profile-picture`
- **Method:** `GET`
- **Path:** `/api/customer/profile-picture` (or with `:id`)
- **Auth:** Bearer Token (or ID param)
- **Success (200 OK):**
  ```json
  { "profilePicture": "IMAGE_URL | null" }
  ```

---

### 2.4 Freelancer Management (`/api/freelancer`)

#### `POST /api/freelancer/create`
- **Method:** `POST`
- **Path:** `/api/freelancer/create`
- **Auth:** Bearer Token
- **Format:** `multipart/form-data` or `application/json`
- **Fields:**
  - `phone`: string (Required)
  - `category`: string (Required, enum: `"Professional" | "Cultural" | "Private"`)
  - `state`: string (Required)
  - `city`: string (Required)
  - `pincode`: string (Required)
  - `linkedin`: string (Optional)
  - `image`: File (Optional image, max 5MB)
- **Success (201 Created):**
  ```json
  {
    "message": "Freelancer account created successfully",
    "freelancer": {
      "_id": "FREELANCER_ID",
      "userId": "USER_ID",
      "phone": "string",
      "linkedin": "string",
      "state": "string",
      "city": "string",
      "pincode": "string",
      "category": "Professional",
      "profilePicture": { "url": "string | null", "fileId": "string | null" }
    }
  }
  ```
- **Errors:**
  - `400`: Category not in enum, or missing fields
  - `409`: Freelancer account already exists

#### `GET /api/freelancer`
- **Method:** `GET`
- **Path:** `/api/freelancer`
- **Auth:** Bearer Token
- **Success (200 OK):**
  ```json
  {
    "freelancer": { ... },
    "details": {
      "category": "string",
      "state": "string",
      "city": "string",
      "pincode": "string",
      "profilePicture": { ... }
    },
    "progress": {
      "received": ["REQUEST_IDS"],
      "accepted": ["REQUEST_IDS"],
      "attended": ["REQUEST_IDS"],
      "rejected": ["REQUEST_IDS"],
      "redflag": ["REQUEST_IDS"]
    }
  }
  ```

#### `PUT /api/freelancer/update`
- **Method:** `PUT`
- **Path:** `/api/freelancer/update`
- **Auth:** Bearer Token
- **Format:** `multipart/form-data` or `application/json`
- **Fields:** `phone`, `linkedin`, `category`, `state`, `city`, `pincode`, `image` (file)
- **Success (200 OK):** Returns updated freelancer record.

#### `DELETE /api/freelancer/delete`
- **Method:** `DELETE`
- **Path:** `/api/freelancer/delete`
- **Auth:** Bearer Token
- **Success (200 OK):**
  ```json
  { "message": "Freelancer account deleted successfully" }
  ```

#### `GET /api/freelancer/profile-picture`
- **Method:** `GET`
- **Path:** `/api/freelancer/profile-picture` (or with `:id`)
- **Auth:** Bearer Token (or ID param)
- **Success (200 OK):**
  ```json
  { "profilePicture": "IMAGE_URL | null" }
  ```

---

### 2.5 Event Requests (Customer Workflow) (`/api/request`)

#### `POST /api/request/create`
- **Method:** `POST`
- **Path:** `/api/request/create`
- **Auth:** Bearer Token (User must have a Customer profile)
- **Format:** `application/json`
- **Request Body:**
  ```json
  {
    "event_details": "string (Required)",
    "pay": "number (Required non-negative)",
    "city": "string (Required)",
    "pincode": "string (Required)",
    "state": "string (Required)",
    "location": "string (Required)",
    "category": "Professional | Cultural | Private (Required)",
    "time": "string (e.g. 10:00 AM - 05:00 PM)",
    "start_time": "ISO Date String (Required)",
    "end_time": "ISO Date String (Required > start_time)",
    "no_of_candidates": "integer >= 1 (Required)",
    "date": "ISO Date String (Required)",
    "additional_description": "string (Optional)"
  }
  ```
- **Success (201 Created):**
  ```json
  {
    "message": "Request created successfully",
    "request": {
      "_id": "REQUEST_ID",
      "customer": "CUSTOMER_ID",
      "event_details": "string",
      "pay": 3500,
      "city": "string",
      "state": "string",
      "pincode": "string",
      "location": "string",
      "category": "Professional",
      "time": "string",
      "start_time": "ISO Date",
      "end_time": "ISO Date",
      "no_of_candidates": 2,
      "date": "ISO Date",
      "additional_description": "string"
    },
    "completion_code": "6-digit string"
  }
  ```

#### `GET /api/request`
- **Method:** `GET`
- **Path:** `/api/request`
- **Auth:** Bearer Token
- **Success (200 OK):**
  ```json
  {
    "message": "Requests fetched successfully",
    "count": 1,
    "requests": [ ... ]
  }
  ```

#### `GET /api/request/:id`
- **Method:** `GET`
- **Path:** `/api/request/:id`
- **Auth:** Bearer Token
- **Success (200 OK):** Returns single request object.

#### `PUT /api/request/:id`
- **Method:** `PUT`
- **Path:** `/api/request/:id`
- **Auth:** Bearer Token
- **Request Body:** Any subset of mutable request fields.
- **Success (200 OK):** Returns updated request object.

#### `DELETE /api/request/:id`
- **Method:** `DELETE`
- **Path:** `/api/request/:id`
- **Auth:** Bearer Token
- **Success (200 OK):** `{ "message": "Request deleted successfully" }`

#### `DELETE /api/request/:requestId/freelancer/:freelancerId`
- **Method:** `DELETE`
- **Path:** `/api/request/:requestId/freelancer/:freelancerId`
- **Auth:** Bearer Token (Customer owner)
- **Rules:** Cannot modify if request created > 2 days ago or event has ended. Automatically notifies waitlisted candidates.
- **Success (200 OK):**
  ```json
  {
    "message": "Freelancer removed successfully. Waitlisted freelancers have been notified.",
    "slots_available": 1
  }
  ```

#### `POST /api/request/:requestId/remind-attendance`
- **Method:** `POST`
- **Path:** `/api/request/:requestId/remind-attendance`
- **Auth:** Bearer Token
- **Success (200 OK):**
  ```json
  {
    "message": "Reminders sent successfully",
    "notifiedCount": 2
  }
  ```

---

### 2.6 Freelancer Event Actions (`/api/freelancer-request`)

#### `POST /api/freelancer-request/:requestId/accept`
- **Method:** `POST`
- **Path:** `/api/freelancer-request/:requestId/accept`
- **Auth:** Bearer Token (Freelancer role)
- **Rules:** 
  - Must have been sent to freelancer.
  - Event must not be within cutoff (1-2 days before start) and not ended.
  - If slots full, freelancer is automatically placed on waitlist.
- **Success (200 OK):**
  ```json
  {
    "success": true,
    "message": "Request accepted",
    "accepted_count": 1,
    "no_of_candidates": 2,
    "slots_left": 1
  }
  ```

#### `POST /api/freelancer-request/:requestId/reject`
- **Method:** `POST`
- **Path:** `/api/freelancer-request/:requestId/reject`
- **Auth:** Bearer Token (Freelancer role)
- **Success (200 OK):**
  ```json
  { "success": true, "message": "Request rejected" }
  ```

#### `POST /api/freelancer-request/:requestId/attendance`
- **Method:** `POST`
- **Path:** `/api/freelancer-request/:requestId/attendance`
- **Auth:** Bearer Token (Freelancer role)
- **Body:** `{ "code": "6-digit-code" }`
- **Success (200 OK):**
  ```json
  { "success": true, "message": "Attendance recorded" }
  ```

#### `POST /api/freelancer-request/:requestId/redflag`
- **Method:** `POST`
- **Path:** `/api/freelancer-request/:requestId/redflag`
- **Auth:** Bearer Token (Freelancer role)
- **Body:** `{ "code": "6-digit-code" }`
- **Success (200 OK):**
  ```json
  { "success": true, "message": "Redflag recorded" }
  ```

---

### 2.7 Notifications (`/api/notifications`)

#### `GET /api/notifications`
- **Method:** `GET`
- **Path:** `/api/notifications?unreadOnly=false&limit=30`
- **Auth:** Bearer Token
- **Success (200 OK):**
  ```json
  {
    "notifications": [ ... ],
    "unreadCount": 0
  }
  ```

#### `POST /api/notifications/register-device`
- **Method:** `POST`
- **Path:** `/api/notifications/register-device`
- **Auth:** Bearer Token
- **Body:** `{ "pushToken": "string" }`
- **Success (200 OK):**
  ```json
  { "message": "Device push token registered successfully" }
  ```

#### `PATCH /api/notifications/:id/read`
- **Method:** `PATCH`
- **Path:** `/api/notifications/:id/read`
- **Auth:** Bearer Token
- **Success (200 OK):** `{ "message": "Notification marked as read", "notification": { ... } }`

#### `PATCH /api/notifications/read-all`
- **Method:** `PATCH`
- **Path:** `/api/notifications/read-all`
- **Auth:** Bearer Token
- **Success (200 OK):** `{ "message": "All notifications marked as read" }`
