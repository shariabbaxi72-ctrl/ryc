# Repair Your Car (RYC) - Frontend Mobile Application 🚗💡

Welcome to the official frontend repository of **Repair Your Car (RYC)**, developed as our Final Year Project (FYP) for the completion of our Bachelor of Science in Computer Science (BSCS) degree.

This cross-platform mobile application bridges the gap between vehicle owners and automotive experts, offering instant access to technical problem-solving and smart, expert-guided solutions.

---

## 🚀 Project Overview

RYC provides a seamless, role-based ecosystem connecting three distinct user tiers:
1. **Users (Vehicle Owners):** Browse diagnostics, search for vehicle problems, and view trusted solutions.
2. **Experts (Mechanical/Electrical):** Log into a dedicated panel to manage, add, and update specialized technical solutions based on their domain.
3. **Admins:** Oversee the entire system, manage users, and review solutions to maintain data quality.

---

## 🛠️ Tech Stack & Architecture

### Frontend (This Repository)
* **Framework:** Flutter (Dart) 💙
* **State Management & Local Storage:** `SharedPreferences` (used for user session persistence, role caching, and maintaining authentications).
* **Network & API Client:** `http` package with customized headers configured to bypass external proxies and development tunnels (e.g., Ngrok).

### Backend & Infrastructure (Connected API)
* **Core Framework:** C# (ASP.NET Web API) inside the `RyC.Controllers` namespace.
* **Database Engine:** MS SQL Server (Relational Schema).
* **Data Layer Logic:** Implements strict data integrity constraints. For example, safe deletion processes verify that a `VehicleProblemSolution` cannot be deleted if associated ratings exist in the `UserRatings` table to protect data relational integrity.

---

## ✨ Key Features Implemented

* **Dynamic Role-Based Dashboards:** Completely adaptive UI that switches layouts depending on whether the logged-in user is an Admin, a generic User, or a certified Expert.
* **Expert Solution Manager:** Experts see their dedicated profile stating their category (Mechanical/Electrical) along with a real-time list of solutions fetched dynamically via API.
* **Robust Request Processing:** Fully asynchronous API handling with persistent global base URLs, optimized JSON data mapping, and localized error boundary checks.
* **Data Deletion Safeguards:** Features a protective layer on deletion triggers ensuring safe workflows without corrupting relational database joins.

---

## 🗺️ App Folder Structure

```text
lib/
│
├── main.dart               # Application entry point & initialization
├── routes/
│   └── routes.dart          # Application routing and named screen definitions
├── services/
│   └── auth_service.dart    # Asynchronous Authentication (Login/Signup endpoints)
│   └── api_service.dart     # Solution fetching and operational HTTP requests
├── utils/
│   └── constants.dart       # Network URLs (Ngrok/Localhost configuration constants)
└── views/
    ├── login/
    │   └── login_screen.dart# Secured validation login view
    └── expert/
        └── expert_dashboard_view.dart # Solution management console for Experts