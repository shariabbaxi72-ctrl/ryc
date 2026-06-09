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

## 🏗️ System Architecture & Data Flow

```text
       [ Flutter Mobile App Frontend ]
                     │
                     ▼  (Secure HTTP Requests / JSON)
        [  Development Tunnel ]
                     │
                     ▼
         [ C# ASP.NET Core Web API ]
         (RyC.Controllers Namespace)
                     │
                     ▼  (ADO.NET / Entity Framework Joins)
         [ MS SQL Server Database ]