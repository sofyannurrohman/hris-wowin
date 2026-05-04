# Project Skills: Super App Wowin

This document outlines the core competencies and technologies necessary to maintain and develop the Super App Wowin project, covering HRIS, Factory, Warehouse, and Sales operations.

## Backend Development (Go)
- **Language**: Go (Golang)
- **Framework/Pattern**: Clean Architecture (Domain, Usecase, Repository, Delivery).
- **HTTP Layer**: Native `net/http` or standard libraries (as seen in `shift_handler.go`).
- **Database**: PostgreSQL with standard SQL queries or lightweight ORM.
- **Caching/Auth**: Redis for session/JWT management.
- **Migration**: SQL-based migrations located in `backend/internal/migrations`.

## Frontend Development (Vue.js)
- **Framework**: Vue.js 3 (Composition API).
- **Build Tool**: Vite.
- **State Management**: Pinia.
- **Routing**: Vue Router.
- **UI Components**: Radix UI (via `reka-ui`) and Shadcn-inspired components.
- **Styling**: Tailwind CSS 4.
- **API Client**: Axios for backend integration.

## Mobile Development (Flutter)
- **Language**: Dart.
- **State Management**: Flutter BLoC (Business Logic Component).
- **Architecture**: Feature-driven Clean Architecture (Data, Domain, Presentation).
- **Dependency Injection**: GetIt.
- **HTTP Layer**: Dio.
- **Local Storage**: Shared Preferences.
- **Mobile AI**: Google ML Kit (Face Detection) and TFLite (Face Embedding).
- **Hardware Integration**: Camera, GPS (Geolocator), and Device Info.

## Database & Infrastructure
- **RDBMS**: PostgreSQL 15.
- **NoSQL**: Redis 7.
- **Containerization**: Docker & Docker Compose for orchestration.
- **Spatial**: Basic GIS logic for Geofencing (radius-based attendance).
- **Mobile Assets**: TFLite models for edge-side face recognition.

## Domain Knowledge

### HRIS (Human Resource Information System)
- **Organizational Structure**: Multi-tenant companies, branches, departments, and job positions.
- **Time Management**: Shifts, employee rosters, and live attendance with GPS validation.
- **Leave Management**: Leave types, annual quotas, and approval workflows.
- **Payroll**: Dynamic payroll components (earning/deduction), tax calculations (PPh21), and payslip generation.

### Factory Operations (Pabrik Utama)
- **Production Tracking**: Monitoring manufacturing processes, output, and efficiency.
- **Machine Maintenance**: Scheduling and logging maintenance for factory equipment.
- **Quality Control**: Managing QC checklists and reporting for manufactured goods.

### Warehouse Operations (Gudang Cabang)
- **Inventory Management**: Stock tracking, SKU management, and branch-specific inventory levels.
- **Stock Movement**: Handling receiving, transfers (mutasi), and stock opname across branches.
- **Logistics**: Coordinating distribution and branch fulfillment.

### Sales Operations (Sales Cabang)
- **CRM & Customer Management**: Managing customer data and relationship history at the branch level.
- **Order Management**: Processing sales orders, invoicing, and tracking delivery status.
- **Sales Performance**: Monitoring sales targets, quotas, and branch-specific revenue metrics.

## Coding Conventions

### Go
- Follow Clean Architecture.
- Handlers must not access the database directly.
- Business logic belongs in the `usecase` layer.
- Repository layer handles all persistence.
- Use context.Context in all service functions.

### Naming
- snake_case for database
- camelCase for JSON
- PascalCase for Go structs

## API Design Rules

- All APIs follow REST conventions:
    - GET    /employees
    - GET    /employees/{id}
    - POST   /employees
    - PATCH  /employees/{id}
    - DELETE /employees/{id}

## Multi-Tenant Security

**All queries MUST be scoped by `company_id`.**
- **Example:**
    SELECT * FROM employees
    WHERE company_id = $1
- Never return cross-company data.

## Performance Considerations
**Large tables:**
- employees
- attendance_logs
- payslips
**Rules:**
- Always use pagination for list endpoints.
- Prefer indexed queries.
- Avoid SELECT * in production queries.