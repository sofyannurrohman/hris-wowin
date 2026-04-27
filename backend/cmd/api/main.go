package main

import (
	"log"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/sofyan/hris_wowin/backend/config"
	"github.com/sofyan/hris_wowin/backend/internal/delivery/http"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
)

func main() {
	// Initialize Config
	cfg := config.LoadConfig()

	// Initialize Database
	db := config.ConnectDB(cfg)

	// Setup Repositories
	userRepo := repository.NewUserRepository(db)
	employeeRepo := repository.NewEmployeeRepository(db)
	attendanceRepo := repository.NewAttendanceRepository(db)
	leaveRepo := repository.NewLeaveRepository(db)
	overtimeRepo := repository.NewOvertimeRepository(db)
	payrollRepo := repository.NewPayrollRepository(db)
	jobPositionRepo := repository.NewJobPositionRepository(db)
	payrollComponentRepo := repository.NewPayrollComponentRepository(db)
	leaveTypeRepo := repository.NewLeaveTypeRepository(db)
	shiftRepo := repository.NewShiftRepository(db)
	departmentRepo := repository.NewDepartmentRepository(db)
	companyRepo := repository.NewCompanyRepository(db)
	branchRepo := repository.NewBranchRepository(db)
	employeeShiftRepo := repository.NewEmployeeShiftRepository(db)
	reimbursementRepo := repository.NewReimbursementRepository(db)
	performanceRepo := repository.NewPerformanceRepository(db)
	payrollConfigRepo := repository.NewPayrollConfigRepository(db)
	announcementRepo := repository.NewAnnouncementRepository(db)

	// Setup Utils
	emailSender := utils.NewEmailSender(cfg.SMTPHost, cfg.SMTPPort, cfg.SMTPUser, cfg.SMTPPass, cfg.SMTPFrom)

	// Setup UseCases
	authUseCase := usecase.NewAuthUseCase(userRepo, companyRepo, emailSender)
	employeeUseCase := usecase.NewEmployeeUsecase(employeeRepo, userRepo)
	attendanceUseCase := usecase.NewAttendanceUseCase(attendanceRepo, employeeRepo, employeeShiftRepo, leaveRepo)
	leaveUseCase := usecase.NewLeaveUseCase(db, leaveRepo, employeeRepo)
	overtimeUseCase := usecase.NewOvertimeUseCase(overtimeRepo, employeeRepo)
	payrollUseCase := usecase.NewPayrollUseCase(payrollRepo, employeeRepo, payrollConfigRepo, performanceRepo)
	jobPositionUseCase := usecase.NewJobPositionUseCase(jobPositionRepo)
	payrollComponentUseCase := usecase.NewPayrollComponentUseCase(payrollComponentRepo)
	leaveTypeUseCase := usecase.NewLeaveTypeUseCase(leaveTypeRepo)
	shiftUseCase := usecase.NewShiftUseCase(shiftRepo)
	departmentUseCase := usecase.NewDepartmentUseCase(departmentRepo)
	companyUseCase := usecase.NewCompanyUseCase(companyRepo)
	branchUseCase := usecase.NewBranchUseCase(branchRepo)
	employeeShiftUseCase := usecase.NewEmployeeShiftUseCase(employeeShiftRepo, employeeRepo, shiftRepo)
	reimbursementUseCase := usecase.NewReimbursementUseCase(reimbursementRepo, employeeRepo)
	performanceUseCase := usecase.NewPerformanceUseCase(performanceRepo, attendanceRepo, employeeShiftRepo, leaveRepo, attendanceUseCase)
	payrollConfigUseCase := usecase.NewPayrollConfigUseCase(payrollConfigRepo)
	announcementUseCase := usecase.NewAnnouncementUseCase(announcementRepo, employeeRepo)

	// Initialize Gin
	r := gin.Default()

	// CORS Middleware
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}))

	// Serve Static Files
	r.Static("/uploads", "./uploads")

	// Initialize Handlers
	authHandler := http.NewAuthHandler(authUseCase, cfg)
	employeeHandler := http.NewEmployeeHandler(employeeUseCase)
	attendanceHandler := http.NewAttendanceHandler(attendanceUseCase)
	leaveHandler := http.NewLeaveHandler(leaveUseCase)
	userHandler := http.NewUserHandler(db, employeeRepo)
	overtimeHandler := http.NewOvertimeHandler(overtimeUseCase)
	payrollHandler := http.NewPayrollHandler(payrollUseCase)
	jobPositionHandler := http.NewJobPositionHandler(jobPositionUseCase)
	payrollComponentHandler := http.NewPayrollComponentHandler(payrollComponentUseCase)
	leaveTypeHandler := http.NewLeaveTypeHandler(leaveTypeUseCase)
	shiftHandler := http.NewShiftHandler(shiftUseCase)
	departmentHandler := http.NewDepartmentHandler(departmentUseCase)
	companyHandler := http.NewCompanyHandler(companyUseCase)
	branchHandler := http.NewBranchHandler(branchUseCase)
	employeeShiftHandler := http.NewEmployeeShiftHandler(employeeShiftUseCase)
	reimbursementHandler := http.NewReimbursementHandler(reimbursementUseCase)
	performanceHandler := http.NewPerformanceHandler(performanceUseCase, employeeUseCase)
	payrollConfigHandler := http.NewPayrollConfigHandler(payrollConfigUseCase)
	announcementHandler := http.NewAnnouncementHandler(announcementUseCase)

	// API v1 Routes
	v1 := r.Group("/api/v1")
	{
		// Public Routes
		authHandler.SetupRoutes(v1)
		branchHandler.SetupPublicRoutes(v1)
		jobPositionHandler.SetupPublicRoutes(v1)
		v1.Static("/uploads", "./uploads")

		// Protected Routes
		protected := v1.Group("")
		protected.Use(http.AuthMiddleware(cfg.JWTSecret))
		{
			attendanceHandler.SetupRoutes(protected)
			employeeHandler.SetupRoutes(protected)
			leaveHandler.SetupRoutes(protected)
			userHandler.SetupRoutes(protected)
			overtimeHandler.SetupRoutes(protected)
			payrollHandler.SetupRoutes(protected)
			jobPositionHandler.SetupRoutes(protected)
			payrollComponentHandler.SetupRoutes(protected)
			leaveTypeHandler.SetupRoutes(protected)
			shiftHandler.SetupRoutes(protected)
			departmentHandler.SetupRoutes(protected)
			companyHandler.SetupRoutes(protected)
			branchHandler.SetupRoutes(protected)
			employeeShiftHandler.SetupRoutes(protected)
			reimbursementHandler.SetupRoutes(protected)
			performanceHandler.SetupRoutes(protected)
			payrollConfigHandler.SetupRoutes(protected)
			announcementHandler.SetupRoutes(protected)
		}
	}

	// Health Check
	r.GET("/api/v1/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
		})
	})

	log.Printf("Server starting on port %s", cfg.ServerPort)
	if err := r.Run(":" + cfg.ServerPort); err != nil {
		log.Fatal("Failed to start server: ", err)
	}
}
