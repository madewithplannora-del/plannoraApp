# 📱 PLANNORA — Complete System Architecture & UI/UX Lovable Specification Prompt

> **Project Name:** Plannora (PlanEra)  
> **Platform Type:** Cross-Platform Responsive Web Application (Optimized for Mobile & Desktop)  
> **Target Audience:** Event Organizers (Customers) & Gig Event Talent (Freelancers)  
> **Target UI Builder:** Lovable.dev (React, TypeScript, Tailwind CSS, Lucide Icons, Shadcn UI)  

---

## 1. Executive Summary & Product Vision

**Plannora** is an end-to-end on-demand event staffing and talent matchmaking platform. It bridges the gap between **Event Organizers ("Customers")** who need reliable temporary event crews (ushers, coordinators, hospitality staff, performers, security, technical assistants) and **Verified Gigs/Talent ("Freelancers")** looking for local shifts.

### Core Value Propositions:
1. **Targeted Location & Category Matching:** Event postings are dynamically matched and sent to freelancers by category (`Professional`, `Cultural`, `Private`) and geography (City, State, Pincode).
2. **Deterministic Capacity & Waitlists:** Each event specifies a required number of candidates (`no_of_candidates`). When spots fill up, additional candidates enter a live waitlist. If an accepted candidate is removed, waitlisted talent are immediately notified.
3. **Automated Business Rules & Cutoffs:**
   - **Acceptance Cutoff:** Freelancers cannot accept within 48 hours (2 days) of event start time.
   - **Customer List Lock:** Organizers cannot remove freelancers from the accepted crew after 48 hours (2 days) from request creation.
   - **Auto-Rejection Worker:** Unfilled/unaccepted requests are automatically rejected at deadlines.
4. **On-Site Cryptographic Check-In & Red-Flag Protection:**
   - Host receives a unique **6-digit attendance completion code** upon creating the event.
   - Freelancers check in on-site starting 15 minutes before event start by entering this 6-digit code.
   - Freelancers can also submit a **Red Flag** with the code if the venue or host fails safety/legitimacy checks.

---

## 2. Visual Identity & Design System

### 2.1 Theme & Color Palette
- **Primary (Brand Indigo):** `#4F46E5` (Tailwind `indigo-600`) — Primary CTAs, active highlights
- **Primary Dark:** `#3730A3` (Tailwind `indigo-800`)
- **Primary Light / Container:** `#EEF2FF` (Tailwind `indigo-50`)
- **Secondary / Accent (Teal):** `#0D9488` (Tailwind `teal-600`) — Freelancer portal accent & verified badges
- **Secondary Container:** `#CCFBF1` (Tailwind `teal-50`)
- **Backgrounds:**
  - App Canvas: `#F8FAFC` (Tailwind `slate-50`)
  - Surface / Card: `#FFFFFF` (Pure white) with 1px border `#E2E8F0` (`slate-200`)
  - Dark Surface / Hero Gradient: `from-[#0F172A] to-[#1E293B]` (`slate-900` to `slate-800`)
- **Typography:** Inter or Outfit (Clean modern sans-serif)
  - Headings: Bold / ExtraBold, Slate 900 (`#0F172A`)
  - Subtitles / Secondary text: Slate 500 (`#64748B`)
  - Muted / Placeholders: Slate 400 (`#94A3B8`)
- **Status Semantic Colors:**
  - **Success / Attended / Verified:** `#10B981` (Emerald 500) | Container: `#D1FAE5`
  - **Warning / Pending / Waitlist:** `#F59E0B` (Amber 500) | Container: `#FEF3C7`
  - **Error / Rejected / Red Flag:** `#EF4444` (Red 500) | Container: `#FEE2E2`
- **Category Badges:**
  - `Professional`: Blue (`#3B82F6` / `#DBEAFE`)
  - `Cultural`: Purple (`#8B5CF6` / `#EDE9FE`)
  - `Private`: Pink/Rose (`#EC4899` / `#FCE7F3`)

### 2.2 Design Aesthetics & Component Guidelines
- **Elevations & Corners:** Generous rounded cards (`rounded-2xl` / 16px to 24px), soft ambient box shadows (`shadow-sm` and `shadow-md`), crisp 1px borders.
- **Glassmorphism:** Modals and sticky headers with `backdrop-blur-md bg-white/80 border-b border-slate-100`.
- **Navigation:**
  - Mobile: Bottom navigation bar with active icon indicator and micro-animations.
  - Desktop / Tablet: Persistent sidebar or top navigation with role-switcher dropdown and notification bell.
- **Interactive Micro-States:** Skeleton loaders for async data, animated counters for statistics, copy-to-clipboard feedback tooltips, and confirmation drawers/modals.

---

## 3. User Roles, Personas & Workflows

### 3.1 Role 1: Customer (Event Host / Organizer)
- **Goals:** Post event requirements quickly, monitor applicant counts in real-time, view verified attendee check-ins, manage accepted crew lists, send attendance reminders.
- **Key Actions:**
  1. Register & verify email with 6-digit OTP.
  2. Complete Customer profile (Phone, City, State, Pincode, Profile Avatar).
  3. Create an Event Request:
     - Title/Event Details, Category (`Professional`, `Cultural`, `Private`), Total Pay ($/₹), Required Candidates (`no_of_candidates`), Event Date, Start Time & End Time, Physical Location Address, City, State, Pincode, Additional Instructions.
  4. Receive and store the **6-digit Event Completion Code** displayed in a prominent card modal upon creation.
  5. Monitor the Event Dashboard:
     - View filled spots vs. capacity (e.g. `2 / 5 candidates accepted`).
     - View list of accepted freelancers with contact details, status pills, and action to remove (before 48-hr lock).
     - Track list lock deadline countdown timer (`List locks in X days/hours`).
     - Trigger "Send Attendance Reminder" notification to all accepted candidates.
     - View real-time attendee status (`Attended` vs. `Pending` vs. `Red Flagged`).
  6. Edit / Delete event request (with cascade handling).

### 3.2 Role 2: Freelancer (Event Talent / Crew)
- **Goals:** Discover matching gig shifts based on category and city, accept opportunities before deadlines, check-in on-site to verify attendance, build a flawless attendance track record.
- **Key Actions:**
  1. Register & verify email with 6-digit OTP.
  2. Complete Freelancer profile: Category specialization (`Professional`, `Cultural`, `Private`), Phone, LinkedIn URL, City, State, Pincode, Profile Picture.
  3. Freelancer Dashboard & Stats Overview:
     - Metric Tiles: **Invites Received**, **Accepted Shifts**, **Attended / Completed**, **Declined**, **Red Flags**.
  4. Jobs & Shifts Management (Tabbed Interface):
     - **"New Opportunities" Tab:** Real-time event invites matching category & location. Shows Pay, Timings, Location, and an **Acceptance Countdown Deadline** (`Accept within X hours`). Single-click `Accept` or `Decline`. If capacity is reached, displays `Waitlist Status`.
     - **"Confirmed Shifts" Tab:** Upcoming accepted gigs with venue address, start time, client name, and a primary **"Venue Check-In"** button.
     - **"Past Shifts" Tab:** Historical records showing attendance verification badge or red flag status.
  5. Check-In / Red Flag Modal:
     - 6-digit PIN input for attendance verification code provided by host at venue.
     - Checkbox toggle: *"Flag this event (Red Flag report)"* to report unsafe or illegitimate conditions.

### 3.3 Dual-Role Switcher System
- A single user account can hold both Customer and Freelancer profiles.
- Top-level Role Selection / Switcher screen allows switching between **Customer View** and **Freelancer View** at any time.

---

## 4. Complete Screen-by-Screen UI Architecture

### 4.1 Authentication & Onboarding Flow
1. **Splash / Welcome Screen:**
   - Brand logo (`Plannora`), tagline *"Seamless Event Staffing on Demand"*, CTAs for "Get Started" and "Log In".
2. **Sign In Screen (`/login`):**
   - Inputs: Email or Username, Password (with show/hide eye toggle).
   - "Forgot Password?" link, "Remember Me" checkbox, "Sign In" button, "Create an account" link.
3. **Register Screen (`/register`):**
   - Inputs: Username (3-30 chars), Email, Password (min 8 chars).
   - Terms & Privacy policy checkbox.
   - On submission: triggers 6-digit OTP dispatch to email.
4. **OTP Verification Screen (`/verify-otp`):**
   - 6-digit PIN input boxes with auto-focus and auto-paste.
   - Resend OTP countdown timer (60s).
   - On success: logs user in and redirects to Role Selection.
5. **Forgot Password & Reset Flow (`/forgot-password`):**
   - Step 1: Enter email -> receive reset OTP.
   - Step 2: Verify OTP -> get secure reset session.
   - Step 3: Enter and confirm new password.
6. **Role Selection & Profile Setup (`/role-select`):**
   - Interactive two-card selector:
     - **Card A: "I want to Hire Talent" (Customer)**
     - **Card B: "I want to Work Shifts" (Freelancer)**
   - If profile doesn't exist yet, opens a slide-up onboarding sheet:
     - Customer setup: Phone number, State, City, Pincode, Profile Image upload.
     - Freelancer setup: Category dropdown (`Professional`, `Cultural`, `Private`), Phone, LinkedIn URL, State, City, Pincode, Profile Image upload.

---

### 4.2 Customer Portal Screens

#### Screen C1: Customer Home & Events Dashboard (`/customer`)
- **Top Header:** Customer avatar, greeting (`Welcome, [Name]`), quick Role Switcher toggle, Notifications bell with unread badge counter.
- **Metric Highlights Row:**
  - Active Events Counter
  - Total Talent Hired
  - Total Shift Payouts
- **Primary CTA:** Sticky/floating `+ Post New Event` button.
- **Event Filter Tabs:** `All Events`, `Upcoming`, `In Progress`, `Completed`.
- **Event Card Item:**
  - Category Badge (`Professional` / `Cultural` / `Private`)
  - Event title / summary
  - Pay per talent with currency symbol (e.g., `$150 / person`)
  - Date & Time range (e.g. `Oct 24, 2026 • 09:00 AM - 05:00 PM`)
  - Location badge (City, State)
  - Capacity Progress Bar: e.g., `3/4 Candidates Filled`
  - Status Pill: `Open for Bids`, `Fully Staffed`, `In Progress`, `Completed`
  - Action: Clicking card opens Event Details.

#### Screen C2: Create Event Wizard / Screen (`/customer/create-event`)
- **Card-based clean form structure:**
  - **Section 1: Event Essentials:**
    - Event Title / Details (Textarea)
    - Category Selection (Visual 3-way toggle: `Professional`, `Cultural`, `Private`)
  - **Section 2: Timing & Schedule:**
    - Event Date Picker
    - Event Start Time Picker
    - Event End Time Picker
    - Display calculated shift duration (e.g., `8 hours shift`)
  - **Section 3: Staffing & Compensation:**
    - Number of Candidates Needed (`no_of_candidates` number stepper: 1, 2, 5, 10...)
    - Pay Per Candidate (Numeric input)
    - Total Budget summary calculation (`Candidates × Pay = Total Budget`)
  - **Section 4: Venue & Location:**
    - Auto-prefilled from Customer profile (City, State, Pincode) with edit ability.
    - Specific Venue Address / Landmarks text input.
  - **Section 5: Additional Instructions:**
    - Dress code, arrival instructions, reporting manager details.
  - **Submit Button:** "Publish Event & Find Crew"
  - **Success Modal:**
    - Celebratory illustration/animation.
    - **Crucial Component:** "Your 6-Digit Event Check-In Code" with a prominent copy button and warning: *"Provide this code to your accepted freelancers at the venue to verify attendance."*

#### Screen C3: Event Details & Management (`/customer/events/:id`)
- **Hero Header:** Event title, category pill, date/time chips, location pin.
- **Host Check-In PIN Card:**
  - Displays the 6-digit Attendance Code (masked with reveal toggle and copy button).
  - Status of attendance: `X of Y crew checked in`.
  - Button: `🔔 Send Attendance Reminder` (Sends email and push alerts to all accepted talent).
- **List Lock Notice Banner:**
  - Shows countdown: `⚠️ You can modify the crew list until [Date/Time] (48 hrs from creation). After that, the list is locked.`
- **Accepted Freelancers List:**
  - List of accepted talent cards:
    - Avatar, Freelancer name, Phone, LinkedIn profile link.
    - Status badge: `Confirmed`, `Attended (Checked-in)`, `Red Flag Raised`.
    - Action: `Remove Freelancer` (Disabled if list lock has passed). Shows confirmation dialog warning that the spot will be offered to the waitlist.
- **Waitlist Drawer/Accordion:**
  - Shows number of freelancers in queue ready to fill spots if someone cancels.

#### Screen C4: Customer Profile (`/customer/profile`)
- Profile picture with camera edit icon.
- Contact info: Name, Email, Phone number, Default City, State, Pincode.
- Account statistics (total events hosted, completion rate).
- Role Switch button: "Switch to Freelancer Portal".
- Sign Out button.

---

### 4.3 Freelancer Portal Screens

#### Screen F1: Freelancer Dashboard (`/freelancer`)
- **Top Header:** Freelancer avatar, name, category badge (`Cultural Specialist`), notifications bell.
- **Hero Performance Banner (Dark Slate Gradient):**
  - Freelancer name, verified status badge.
  - Quick action: `📍 Venue Check-In` (Opens check-in modal directly).
- **Stat Cards Grid (4 tiles):**
  - 📩 **Invites Received** (Total requests dispatched to them)
  - 🤝 **Accepted Shifts** (Confirmed upcoming events)
  - ✅ **Events Attended** (Successfully checked-in shifts)
  - 🚩 **Red Flags** (Safety reports filed)
- **Active / Next Up Shift Card:**
  - Displays the next upcoming event within 24-48 hours.
  - Countdown to shift start.
  - Quick check-in button.

#### Screen F2: Jobs & Shifts Portal (`/freelancer/shifts`)
- **Three-Tab Segmented Control:**
  1. **"New Invites" Tab:**
     - Opportunities matched by Category + Location.
     - Card shows: Event Title, Pay Rate (highlighted), Date, Time, Venue/City, Customer Name.
     - **Acceptance Deadline Badge:** E.g., `⚡ Accept within 14 hours` (calculates 48 hrs before start).
     - Action Buttons: `Accept Shift` (Primary Indigo) & `Decline` (Subtle outline).
     - If slots are currently full: Shows `Join Waitlist` button.
  2. **"Accepted Shifts" Tab:**
     - Events the freelancer has committed to.
     - Start time, navigation directions link, organizer contact.
     - **"Check-In" Button:** Opens attendance modal with prefilled Request ID.
  3. **"History" Tab:**
     - Past events with final status badges (`Attended`, `Auto-Expired`, `Declined`, `Red Flagged`).

#### Screen F3: Venue Check-In & Red Flag Modal
- Accessible from Home or Shift card.
- **Fields:**
  - Event Request ID (prefilled or editable dropdown).
  - 6-Digit Verification Code input field.
  - Checkbox toggle: `Flag this event (Red Flag report)`.
  - Helper description explaining code is obtained from the event host on-site.
  - Action button: `Verify Attendance` (Green) OR `Submit Red Flag` (Red when checkbox active).

#### Screen F4: Freelancer Profile (`/freelancer/profile`)
- Avatar upload.
- Specialization Category badge selector.
- LinkedIn profile link input & verification.
- Phone number, City, State, Pincode.
- Track record & reputation score.
- "Switch to Customer Portal" action.

---

### 4.4 Shared / Utility Screens

#### Screen S1: Notifications Center (`/notifications`)
- Segmented filter: `All` vs. `Unread`.
- "Mark all as read" button.
- Notification Item types:
  - `WAITLIST_SLOT_AVAILABLE`: *"A slot just opened up for [Event Name]! Tap to claim your spot."*
  - `ATTENDANCE_CODE_REMINDER`: *"Host has requested check-in for [Event Name]. Please enter your 6-digit code."*
  - `GENERAL`: Profile updates, confirmations, system notices.
- Tap notification to navigate directly to the corresponding event.

---

## 5. Technical Data Models & Schema

When building mock state or connecting to the backend, use these exact entity structures:

### 5.1 User Entity
```typescript
interface User {
  id: string;
  username: string;
  email: string;
  emailVerified: boolean;
  createdAt: string;
}
```

### 5.2 Customer Entity
```typescript
interface Customer {
  id: string;
  account: string; // User ID
  phoneno: string;
  state: string;
  city: string;
  pincode: string;
  sent_request: string[]; // Request IDs
  profilePicture?: {
    url: string | null;
    fileId: string | null;
  };
}
```

### 5.3 Freelancer Entity
```typescript
interface Freelancer {
  id: string;
  userId: string;
  phone: string;
  category: "Professional" | "Cultural" | "Private";
  state: string;
  city: string;
  pincode: string;
  linkedin: string;
  profilePicture?: {
    url: string | null;
    fileId: string | null;
  };
  pushToken?: string | null;
}
```

### 5.4 Event Request Entity
```typescript
interface EventRequest {
  id: string;
  customer: string; // Customer ID
  event_details: string;
  pay: number;
  city: string;
  pincode: string;
  state: string;
  location: string;
  category: "Professional" | "Cultural" | "Private";
  time: string; // Formatted time string e.g. "09:00 AM - 05:00 PM"
  start_time: string; // ISO 8601 string
  end_time: string; // ISO 8601 string
  no_of_candidates: number;
  date: string; // ISO 8601 string
  additional_description?: string;
  completion_code?: string; // Revealed only to host upon creation
  completion_code_hash?: string;
  auto_rejected: string[];
  manually_rejected: string[];
  acceptedFreelancers?: Array<{
    id: string;
    name: string;
    phone: string;
    linkedin: string;
    avatarUrl?: string;
    hasAttended?: boolean;
  }>;
  createdAt: string;
  updatedAt: string;
}
```

### 5.5 Progress & Tracking Records
```typescript
interface RequestProgress {
  requestId: string;
  sent: string[]; // Freelancer IDs
  accepted: string[]; // Freelancer IDs
  rejected: string[]; // Freelancer IDs
}

interface FreelancerProgress {
  freelancerId: string;
  received: string[]; // Request IDs
  accepted: string[]; // Request IDs
  attended: string[]; // Request IDs
  rejected: string[]; // Request IDs
  redflag: string[]; // Request IDs
}
```

---

## 6. Business Logic, Rules & Formulas

Lovable should enforce or visually represent the following core rules:

1. **Freelancer Acceptance Cutoff:**
   - `ACCEPT_CUTOFF_DAYS = 2` (48 hours).
   - `canFreelancerAccept = now <= (start_time - 48 hours)`.
   - If current time is within 48 hours of `start_time`, the "Accept" button is disabled with message: *"Acceptance deadline has passed"*.
2. **Customer List Lock:**
   - `LIST_LOCK_DAYS = 2` (48 hours from request creation).
   - `canCustomerModifyList = now <= (createdAt + 48 hours)`.
   - After this cutoff, the Customer cannot remove accepted freelancers. Display badge: *"Crew list is permanently locked"*.
3. **Attendance Window:**
   - Attendance verification opens **15 minutes before** `start_time` and remains valid until `end_time`.
   - Freelancer inputs the 6-digit code. The system matches it against the stored SHA-256 hash.
4. **Capacity & Waitlisting:**
   - When `accepted.length >= no_of_candidates`, the event is full.
   - Any further freelancer attempting to accept is added to the `waitlist` model.
   - If the host removes an accepted freelancer, a `WAITLIST_SLOT_AVAILABLE` notification is sent to waitlisted freelancers.

---

## 7. Complete API Reference for Full Integration

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/register` | Register username, email, password |
| `POST` | `/api/auth/verifyotp` | Verify 6-digit registration OTP |
| `POST` | `/api/auth/login` | Login with email & password |
| `POST` | `/api/auth/forgotpassword` | Send password reset OTP |
| `POST` | `/api/auth/verifyforgototp` | Verify reset OTP |
| `POST` | `/api/auth/resetpassword` | Set new password |
| `GET` | `/api/auth/profile` | Get logged-in user session |
| `POST` | `/api/customer/create` | Create customer profile |
| `GET` | `/api/customer` | Get customer profile & details |
| `PUT` | `/api/customer/update` | Update customer details & avatar |
| `POST` | `/api/freelancer/create` | Create freelancer profile |
| `GET` | `/api/freelancer` | Get freelancer profile, stats & progress |
| `PUT` | `/api/freelancer/update` | Update freelancer details & avatar |
| `POST` | `/api/request/create` | Create event request (returns 6-digit completion code) |
| `GET` | `/api/request` | Get customer's created events |
| `GET` | `/api/request/:id` | Get single event details with accepted crew |
| `PUT` | `/api/request/:id` | Edit event details |
| `DELETE` | `/api/request/:id` | Delete event |
| `DELETE` | `/api/request/:id/freelancer/:freelancerId` | Remove freelancer from accepted crew |
| `POST` | `/api/request/:id/remind-attendance` | Host triggers email & push reminders |
| `POST` | `/api/freelancer-request/:id/accept` | Freelancer accepts shift |
| `POST` | `/api/freelancer-request/:id/reject` | Freelancer declines shift |
| `POST` | `/api/freelancer-request/:id/attendance` | Freelancer submits 6-digit code at venue |
| `POST` | `/api/freelancer-request/:id/redflag` | Freelancer flags problematic event |
| `GET` | `/api/notifications` | Get user notifications list |
| `PATCH` | `/api/notifications/read-all` | Mark all notifications read |
| `PATCH` | `/api/notifications/:id/read` | Mark single notification read |

---

## 8. Master Lovable Prompt (Ready to Copy-Paste)

> **Copy and paste the prompt below directly into Lovable to generate the entire UI:**

```text
Create a modern, full-featured web app called "Plannora" — an on-demand event staffing and gig talent marketplace.

The app supports two primary roles with a switchable toggle:
1. Customer (Event Organizer): Posts events, sets pay/dates/location/candidate count, receives a 6-digit attendance PIN, manages accepted freelancers, monitors waitlists, sends attendance reminders, and views check-in statuses.
2. Freelancer (Event Talent): Receives matched gigs by category (Professional, Cultural, Private) and location, accepts/declines shifts before a 48h cutoff, views confirmed upcoming jobs, performs venue check-in using the host's 6-digit PIN, or reports safety red-flags.

Design Requirements:
- Visual Theme: Crisp, high-end SaaS aesthetic. Primary Brand Indigo (#4F46E5), Secondary Teal (#0D9488), Slate neutrals (#0F172A, #F8FAFC), with semantic badges (Emerald for Attended, Amber for Waitlist, Red for Flags/Deadlines).
- Responsive: Seamless on mobile with a sleek bottom navigation bar, and desktop with a modern sidebar layout.
- Glassmorphic card design, rounded-2xl containers, micro-interactions, copy-to-clipboard for the 6-digit host PIN, and deadline countdown badges.

Core Pages to Build:
1. Auth & Onboarding: Login, Registration with 6-digit OTP modal, and Role Selector ("I want to Hire Talent" vs "I want to Work Shifts") with customer/freelancer profile setup sheets.
2. Customer Portal:
   - Dashboard: Overview of posted events, applicant metrics, and quick "+ New Event" CTA.
   - Create Event Wizard: Title, Category picker (Professional/Cultural/Private), Date, Start/End times, Headcount, Pay rate, Venue address, and completion modal revealing the 6-digit attendance code.
   - Event Details: Capacity progress (e.g. 3/5 filled), masked 6-digit code card, "Send Attendance Reminder" button, 48-hour list-lock warning countdown, and accepted freelancer table with "Remove" action.
3. Freelancer Portal:
   - Dashboard: Performance banner with live stats (Invites Received, Accepted, Attended, Red Flags) and quick "Check-In" action.
   - Shifts & Opportunities (Tabbed: "New Invites" with accept deadline countdown, "Confirmed Shifts" with venue directions, and "History").
   - Venue Check-In Modal: 6-digit code verification input with a toggle to report a "Red Flag".
4. Shared: Notification center with read/unread filters, and profile management with avatar uploads.

Use realistic mock data, smooth transitions, toast feedback, and empty/loading states throughout.
```
