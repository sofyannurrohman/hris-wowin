# System Architecture: HRIS Wowin

HRIS Wowin is a modern Human Resource Information System built with a Go backend and a Vue.js frontend, orchestrated using Docker.

## Backend Architecture (Go)

The backend follows **Clean Architecture** principles to ensure separation of concerns and maintainability.

### Layers:
1.  **Domain (`backend/internal/domain`)**: Contains core entities (structs) and repository/usecase interfaces. This layer is independent of any external frameworks.
2.  **Usecase (`backend/internal/usecase`)**: Business logic layer. Implements the service logic, orchestrates data flow between repositories.
3.  **Repository (`backend/internal/repository`)**: Data access layer. Implements the persistence logic (PostgreSQL).
4.  **Delivery (`backend/internal/delivery`)**: Entry point for external communication.
    *   **HTTP (`backend/internal/delivery/http`)**: RESTful API handlers and routing.
5.  **Config & Pkg**: Configurations and shared utilities.

### Communication:
-   Internal communication flows from outer layers to inner layers via interfaces (Dependency Inversion).
-   External communication follows RESTful JSON standards.

---

## Frontend Architecture (Vue.js)

The frontend is a Single Page Application (SPA) built with **Vue.js 3** and **TypeScript**.

### Key Technologies:
-   **Composition API**: For reactive and modular component logic.
-   **Pinia**: Global state management (Auth, User sessions, Dashboards).
-   **Vue Router**: Progressive routing for the SPA.
-   **Axios**: Interplays with the Go backend API.
-   **Tailwind CSS**: Utility-first CSS for responsive design.
-   **Shadcn-Vue**: Pre-styled UI components.

### Structure:
-   `src/components`: Reusable UI elements (Buttons, Inputs, Modals).
-   `src/views`: Page-level components mapped to routes.
-   `src/layouts`: Dashboard and Auth base layouts.
-   `src/api`: Axios instance and endpoint definitions.

---

## Mobile Architecture (Flutter)

The mobile application is built with **Flutter** and follows **Clean Architecture** organized by features.

### Layers (per Feature):
1.  **Domain**: Entities, Usecase interfaces, and Repository interfaces.
2.  **Data**: Repository implementations, Data sources (Remote/Local), and Models (DTOs).
3.  **Presentation**: BLoC (State Management) and Widgets (UI).

### Key Technologies:
-   **flutter_bloc**: Predictable state management via Events and States.
-   **GetIt**: Service locator for dependency injection.
-   **Dio**: Advanced HTTP client for API communication.
-   **ML Kit & TFLite**: On-device AI processing for face verification.

### Core Features:
-   `lib/core`: Shared resources, themes, and network configurations.
-   `lib/features`: Specific modules like `attendance`, `leave`, and `payroll`.

---

## Infrastructure

-   **Docker Compose**: Manages three main services:
    -   `hris_backend`: Go API server.
    -   `hris_frontend`: Vue.js client (served via Vite dev or Nginx build).
    -   `hris_postgres`: Primary database.
    -   `hris_redis`: Caching, session management, and JWT blacklisting.
