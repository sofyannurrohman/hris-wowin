# Database Documentation: HRIS Wowin

This document describes the PostgreSQL schema for the HRIS project. The database uses `UUID` for all primary keys and follows a multi-tenant pattern.

## Core Schema Entities

### Organizational Structure
- **companies**: Master table for multi-tenancy. All data is scoped via `company_id`.
- **branches**: Office locations. Includes `latitude`, `longitude`, and `radius_meter` for Geofencing.
- **departments**: Organizational units (supports hierarchy via `parent_id`).
- **job_positions**: Titles and levels (Staff, Manager, C-Level).

### User & Employee
- **users**: Authentication credentials and roles (`superadmin`, `hr_admin`, `employee`).
- **employees**: Detailed personal and professional data. Linked to `users`.
  - Includes Indonesian-specific IDs: NIK, NPWP, BPJS.
  - Features `face_embedding` for AI-based face recognition.

---

### Attendance & Shifts
- **shifts**: Definitions of working hours (start/end, break, flexibility).
- **employee_shifts**: Roster mapping employees to specific shifts on specific dates.
- **attendance_logs**: Real-time clock-in/out records.
  - Stores location (`lat`, `long`), photo (`photo_url`), and radius status (`INSIDE_RADIUS`, `OUTSIDE_RADIUS`).

---

### Leave Management
- **leave_types**: Common types (Annual, Sick, Unpaid).
- **leave_balances**: Tracks quota usage per employee per year.
- **leave_requests**: Submission and approval workflow for time off.

---

### Payroll System
- **payroll_components**: Master list of Earnings, Deductions, and Benefits.
- **employee_salary_settings**: Individual compensation configurations.
- **payroll_runs**: Batch processing for monthly payroll.
- **payslips**: Header record for an employee's focused monthly earnings.
- **payslip_items**: Immutable snapshot of each payroll component used in a specific payslip.

---

## Technical Details

- **Database Engine**: PostgreSQL 15.
- **Extensions**: `uuid-ossp` for primary key generation.
- **Naming Conventions**: `snake_case` for all table and column names.
- **Timezone**: Default `Asia/Jakarta` is used for branch-level attendance tracking.

---

## Mobile Data Handling

The Flutter application utilizes local storage for performance and offline capabilities.

-   **Shared Preferences**: Stores user sessions, JWT tokens, and basic application settings.
-   **Asset Models**: TFLite models (`mobilefacenet.tflite`) are stored locally for edge-side AI inference.
-   **Image Cache**: Temporary storage for camera photos before they are uploaded to the backend.

## Indexing Guidelines

**High-volume tables:**
- employees
- attendance_logs
- leave_requests
- payslips

**Recommended indexes:**
- employees(company_id)
- attendance_logs(employee_id, created_at)
- leave_requests(employee_id, status)
- payslips(employee_id, payroll_run_id)

## Query Safety
**Avoid:**
- SELECT *

**Prefer:**
- SELECT id, first_name, last_name FROM employees WHERE company_id = $1 LIMIT 50 OFFSET 0