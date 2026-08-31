# Fintech Product Analytics Case Study

### Investment Journey · Event Instrumentation · Product Thinking · SQL Analysis

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat-square&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![SQL](https://img.shields.io/badge/SQL-Analytics-00599C?style=flat-square&logo=sqlite&logoColor=white)](https://en.wikipedia.org/wiki/SQL)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/kalisettikiran920-afk)
[![Portfolio](https://img.shields.io/badge/Portfolio-Case%20Study-1D4ED8?style=flat-square)](https://github.com/kalisettikiran920-afk)

---

## 📌 Project Overview

This project is a comprehensive **Product Analytics Portfolio Case Study** evaluating the investment onboarding journey of a digital wealth management platform. The platform enables retail users to build long-term wealth through recurring **Systematic Investment Plans (SIPs)** across diversified asset classes (equities, gold, and fixed deposits), with flexible access to liquidity against accumulated savings without breaking investment schedules.

The analysis addresses a fundamental product question:
> **"How can product analytics be used to understand where users drop off, why they drop off, and whether users successfully reach the milestone of receiving their first investment units?"**

The case study spans the entire analytics lifecycle—from defining a structured **12-event instrumentation schema** and distinguishing in-app user actions from asynchronous partner confirmations, to formulating a **testable drop-off hypothesis**, defining **North Star and counter-metrics**, and executing **PostgreSQL queries** to evaluate funnel conversion, completion time, and drop-off leakage.

---

## 🎯 Objectives

1. **Design Analytics Instrumentation:** Architect a tracking specification for the onboarding journey from initial app open to first unit credit.
2. **Classify Event Types:** Rigorously distinguish between **User-Initiated** actions and **System-Confirmed / Asynchronous** outcomes (KYC API, bank verification, payment gateway, RTA).
3. **Prioritize Under Constraints:** Select and specify exactly **12 high-leverage events** under a hard maximum-event constraint, documenting explicit reasons for exclusions.
4. **Formulate a Testable Hypothesis:** Identify the stage believed to have the highest drop-off, articulate product reasoning, and define clear falsification criteria.
5. **Establish Balanced Metrics:** Define a value-aligned **North Star Metric** and a protective **Counter-Metric** guarding customer experience.
6. **Perform SQL Funnel Analysis:** Derive step-by-step user counts and step-over-step conversion rates using PostgreSQL.
7. **Measure Journey Duration:** Calculate the median completion time between app launch and first unit allocation for completed journeys.
8. **Pinpoint Bottlenecks:** Identify and isolate the single largest drop-off transition between consecutive onboarding stages.
9. **Document Assumptions:** Explicitly state data-modeling assumptions regarding event deduplication, sequence ordering, and user progression.

---

## 📁 Project Structure

```
fintech-product-analytics/
│
├── README.md                                             # Project documentation & case study summary
│
├── case-study/
│   └── Fintech_Product_Analytics_Case_Study_Brief.pdf    # Anonymized case-study brief & specifications
│
├── analysis/
│   └── Fintech_Product_Analytics_Case_Study_Kiran_Kalisetti.pdf  # Complete 19-page portfolio case study
│
└── sql/
    └── fintech_product_analytics.sql                     # PostgreSQL scripts (Funnel, Median Time, Drop-off)
```

---

## 🔄 Investment Onboarding Journey

The user experience comprises a 15-stage structured onboarding funnel:

```mermaid
flowchart LR
    A[1. Splash] --> B[2. Welcome]
    B --> C[3. Mobile + OTP]
    C --> D[4. Email + OTP]
    D --> E[5. PAN Verification *]
    E --> F[6. Home]
    F --> G[7. SIP Setup]
    G --> H[8. Link Bank Account]
    H --> I[9. Confirm Account]
    I --> J[10. UPI E-Mandate *]
    J --> K[11. Additional Details]
    K --> L[12. Nominee Option]
    L --> M[13. Investment Consent]
    M --> N[14. SIP Created]
    N --> O[15. First Unit Credited *]

    classDef async fill:#FFFBEB,stroke:#D97706,stroke-width:1.5px,color:#92400E;
    class E,J,O async;
```
*\* Stages highlighted in amber represent asynchronous milestones confirmed by external third-party partners (KYC verification APIs, banking networks, NPCI/UPI gateways, and RTAs).*

---

## 🧩 Event Instrumentation (Task 1)

Under a strict **12-event constraint**, the instrumentation focuses on high-intent user milestones and definitive system confirmations:

| # | Event Name | Type | Exact Trigger | Key Properties |
| :-: | :--- | :---: | :--- | :--- |
| **01** | `app_open` | User-Initiated | App finishes loading and home/welcome screen renders | `app_version`, `device_platform`, `app_open_source`, `app_load_time_seconds` |
| **02** | `mobile_verified` | System-Confirmed | Mobile verification API returns HTTP 200 after correct OTP | `otp_attempts`, `verification_time_seconds` |
| **03** | `email_verified` | System-Confirmed | Email verification API returns success after correct OTP | `otp_attempts`, `verification_time_seconds`, `email_domain` |
| **04** | `pan_verified` | System-Confirmed | External KYC API confirms valid PAN credentials | `verification_time_seconds`, `pan_verification_status`, `verification_attempts` |
| **05** | `sip_created` | System-Confirmed | Backend API confirms successful creation of recurring SIP | `sip_frequency`, `sip_amount`, `scheme_type`, `completion_time_seconds` |
| **06** | `bank_verified` | System-Confirmed | Banking partner API confirms account details post-confirmation | `bank_name`, `verification_time_seconds`, `verification_method` |
| **07** | `mandate_completed` | System-Confirmed | Payment gateway/bank webhook confirms UPI mandate approval | `mandate_approval_time_minutes`, `upi_app_used`, `mandate_status` |
| **08** | `additional_details_saved` | User-Initiated | User submits the additional personal details form | `completion_time_seconds`, `fields_filled`, `validation_errors` |
| **09** | `investment_consent_verified` | System-Confirmed | Investment consent OTP successfully verified by backend API | `otp_verification_time_seconds`, `otp_attempts`, `otp_delivery_time_seconds` |
| **10** | `first_unit_credited` | System-Confirmed | Registrar & Transfer Agent (RTA) confirms unit allocation | `unit_credit_time_hours`, `investment_scheme`, `investment_amount` |
| **11** | `nominee_added` | User-Initiated | User submits the nominee details form | `nominee_added`, `relation_to_nominee`, `completion_time_seconds` |
| **12** | `save_dashboard_viewed` | User-Initiated | Save Dashboard renders user's active portfolio and units | `portfolio_value`, `active_sip_count`, `dashboard_load_time_seconds` |

### Excluded Events & Selection Strategy
- **`welcome_screen_viewed`**: Redundant with `app_open` marking session initialization.
- **`sip_setup_started`**: Intermediate view state; business milestone captured by `sip_created`.
- **`bank_link_started`**: Intermediate linking step; successful outcome captured by `bank_verified`.
- **Strategy:** Prioritized outcome and state-transition events over passive view states to maximize business insight under the 12-event limit.

---

## 💡 Product Thinking (Tasks 2 &amp; 3)

### Task 2 — Drop-Off Hypothesis
- **Hypothesis:** The **bank verification stage (`bank_verified`)** leaks the most users across the onboarding funnel.
- **Reasoning:**
  1. *Trust Friction:* Heightened user hesitation when providing sensitive bank credentials.
  2. *Data Availability:* Users may not have IFSC or account details readily accessible during mobile onboarding.
  3. *Partner API Latency:* Dependency on external banking APIs prone to downtime or slow responses.
  4. *Confidence Drop:* Verification failures at this critical financial step directly trigger abandonment.
- **Falsification Criteria:** The hypothesis is disproven if data shows `bank_verified` maintains a consistently high completion rate, or if another stage (e.g., mandate registration or KYC) exhibits a higher drop-off rate.

### Task 3 — North Star &amp; Counter-Metric
- **North Star Metric:** **Number of users who receive their first investment units (`first_unit_credited`)**.
  - *Rationale:* Measures users reaching the core product outcome and becoming active investors, reflecting genuine user and business value.
- **Counter-Metric:** **Customer Support Ticket Rate related to the onboarding journey**.
  - *Rationale:* Ensures growth in the North Star Metric is not achieved through aggressive or confusing UX that compromises user experience and increases support load.

---

## 🗄️ SQL Analysis (Task 4)

The analysis was performed against the synthetic `events` dataset using PostgreSQL:

```sql
-- Schema Structure
CREATE TABLE events (
    event_id    TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL,
    event_name  TEXT NOT NULL,
    event_ts    TIMESTAMP NOT NULL,
    properties  JSONB
);
```

### Core SQL Deliverables
1. **Funnel Progression & Step-Over-Step Conversion:** Uses Common Table Expressions (CTEs), `COUNT(DISTINCT user_id)`, and `LAG()` window functions to calculate stage volumes and conversion percentages across the 10 available dataset events.
2. **Median Journey Completion Time:** Computes elapsed time (`MIN(event_ts)`) from `app_open` to `first_unit_credited` for completed users using `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ...)`.
3. **Largest Consecutive Drop-Off:** Isolates the maximum user loss between consecutive stages using `LAG(users) - users` ordered descending.

### Documented Analytical Assumptions
- **First-Occurrence Progression:** For time-based metrics, the earliest event timestamp (`MIN(event_ts)`) represents a user's initial stage progression.
- **Deduplication:** Users who re-triggered events or restarted flows are counted exactly once per funnel stage via `COUNT(DISTINCT user_id)`.
- **Completed Cohort Isolation:** Median completion time strictly evaluates users who reached `first_unit_credited`.
- **Event Sequencing:** Analyzed according to the documented sequential product flow.
- **Core Column Derivation:** Queries rely on `event_name`, `user_id`, and `event_ts` without requiring JSON payload parsing.

---

## 🛠️ Tech Stack & Analytical Skills

- **Database:** PostgreSQL
- **Query Techniques:** Common Table Expressions (CTEs), Window Functions (`LAG() OVER ()`), Continuous Percentiles (`PERCENTILE_CONT(0.5)`), Conditional Aggregation (`CASE WHEN`), Timestamp Arithmetic
- **Product Analytics:** Event Instrumentation, Funnel Conversion Analysis, Drop-off Analysis, North Star & Counter-Metric Frameworks
- **Version Control:** Git, GitHub

---

## 🤖 Use of AI

AI tools were used as an assistive technology during the project workflow, including documentation and SQL syntax support. All event definitions, analytical frameworks, hypotheses, metric choices, assumptions, SQL logic, and interpretations were reviewed, understood, and validated by me.

---

## 📄 Case Study Note

*This is a personal portfolio case study based on a fintech investment onboarding scenario. The case study has been anonymized and uses synthetic data.*

---

## 👤 Author

**Kiran Kalisetti**  
*Aspiring Data Analyst*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/kiran-kalisetti)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/kalisettikiran920-afk)
[![Email](https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:kalisettikiran920@gmail.com)
