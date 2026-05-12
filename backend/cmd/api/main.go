package main

import (
	"log"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/sofyan/hris_wowin/backend/config"
	"github.com/sofyan/hris_wowin/backend/internal/delivery/http"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/pkg/midtrans"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

func main() {
	// Initialize Config
	cfg := config.LoadConfig()

	// Initialize Database
	db := config.ConnectDB(cfg)

	// Run AutoMigrate for critical models to ensure schema sync
	db.AutoMigrate(
		&domain.SalesKPI{},
		&domain.BannerOrder{},
		&domain.Factory{},
		&domain.Product{},
		&domain.FactoryStock{},
		&domain.ProductionLog{},
		&domain.ProductTransfer{},
		&domain.FactoryInventoryLog{},
		&domain.WarehouseStock{},
		&domain.WarehouseLog{},
		&domain.Vehicle{},
		&domain.Notification{},
		&domain.DeliveryBatch{},
		&domain.DeliveryItem{},
		&domain.SalesPayment{},
		&domain.SalesItem{},
		&domain.SalesStock{},
		&domain.SalesTransfer{},
		&domain.SalesTransaction{},
		&domain.SalesOrder{},
		&domain.SalesOrderItem{},
		&domain.SalesOrderItemBatch{},
		&domain.SalesReturn{},
		&domain.SalesReturnItem{},
		&domain.ProductionRecipe{},
		&domain.ProductionRecipeItem{},
	)
	
	// Force drop unique constraint if it still exists and replace with non-unique index
	db.Exec("DROP INDEX IF EXISTS idx_product_transfers_delivery_order_no CASCADE")
	db.Exec("CREATE INDEX IF NOT EXISTS idx_product_transfers_delivery_order_no ON product_transfers(delivery_order_no)")


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
	storeRepo := repository.NewStoreRepository(db)
	salesRepo := repository.NewSalesTransactionRepository(db)
	bannerOrderRepo := repository.NewBannerOrderRepository(db)
	factoryRepo := repository.NewFactoryRepository(db)
	warehouseRepo := repository.NewWarehouseRepository(db)
	vehicleRepo := repository.NewVehicleRepository(db)
	notificationRepo := repository.NewNotificationRepository(db)
	financeRepo := repository.NewFinanceRepository(db)
	deliveryRepo := repository.NewDeliveryRepository(db)
	salesTransferRepo := repository.NewSalesTransferRepository(db)
	salesOrderRepo := repository.NewSalesOrderRepository(db)
	salesReturnRepo := repository.NewSalesReturnRepository(db)

	// Setup Utils
	emailSender := utils.NewEmailSender(cfg.SMTPHost, cfg.SMTPPort, cfg.SMTPUser, cfg.SMTPPass, cfg.SMTPFrom)
	midtransClient := midtrans.NewMidtransClient()

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
	salesUseCase := usecase.NewSalesUsecase(salesRepo, performanceRepo, storeRepo, attendanceRepo, companyRepo, midtransClient)
	bannerOrderUseCase := usecase.NewBannerOrderUseCase(bannerOrderRepo)
	factoryUseCase := usecase.NewFactoryUsecase(factoryRepo, db)
	warehouseUseCase := usecase.NewWarehouseUsecase(warehouseRepo, notificationRepo, salesRepo, salesOrderRepo, db)
	vehicleUseCase := usecase.NewVehicleUsecase(vehicleRepo)
	financeUsecase := usecase.NewFinanceUsecase(financeRepo)
	deliveryUsecase := usecase.NewDeliveryUsecase(deliveryRepo, salesRepo)
	salesTransferUsecase := usecase.NewSalesTransferUsecase(salesTransferRepo, warehouseRepo, db)
	salesOrderUsecase := usecase.NewSalesOrderUsecase(salesOrderRepo, warehouseRepo, salesRepo, db)
	salesReturnUsecase := usecase.NewSalesReturnUsecase(salesReturnRepo, salesOrderRepo, salesRepo, warehouseRepo, db)

	// Initialize Gin
	r := gin.Default()
	r.MaxMultipartMemory = 100 << 20 // 100 MiB

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
	storeHandler := http.NewStoreHandler(storeRepo, employeeUseCase)
	salesHandler := http.NewSalesHandler(salesUseCase, employeeUseCase)
	bannerOrderHandler := http.NewBannerOrderHandler(bannerOrderUseCase, employeeUseCase)
	factoryHandler := http.NewFactoryHandler(factoryUseCase)
	warehouseHandler := http.NewWarehouseHandler(warehouseUseCase)
	vehicleHandler := http.NewVehicleHandler(vehicleUseCase)
	notificationHandler := http.NewNotificationHandler(notificationRepo)
	financeHandler := http.NewFinanceHandler(financeUsecase)
	deliveryHandler := http.NewDeliveryHandler(deliveryUsecase, employeeUseCase)
	salesTransferHandler := http.NewSalesTransferHandler(salesTransferUsecase)
	salesOrderHandler := http.NewSalesOrderHandler(salesOrderUsecase, employeeUseCase)
	salesReturnHandler := http.NewSalesReturnHandler(salesReturnUsecase, employeeUseCase)

	// API v1 Routes
	v1 := r.Group("/api/v1")
	{
		// Public Routes
		authHandler.SetupRoutes(v1)
		branchHandler.SetupPublicRoutes(v1)
		jobPositionHandler.SetupPublicRoutes(v1)
		salesHandler.SetupPublicRoutes(v1)
		v1.Static("/uploads", "./uploads")

		// Protected Routes
		protected := v1.Group("")
		protected.Use(http.AuthMiddleware(cfg.JWTSecret))
		protected.Use(http.EmployeeMiddleware(employeeUseCase))
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
			branchHandler.SetupProtectedPublicRoutes(protected)
			employeeShiftHandler.SetupRoutes(protected)
			reimbursementHandler.SetupRoutes(protected)
			performanceHandler.SetupRoutes(protected)
			payrollConfigHandler.SetupRoutes(protected)
			announcementHandler.SetupRoutes(protected)
			storeHandler.SetupRoutes(protected)
			salesHandler.SetupMobileRoutes(protected)
			salesHandler.RegisterRoutes(protected)
			bannerOrderHandler.SetupRoutes(protected)
			factoryHandler.RegisterRoutes(protected)
			warehouseHandler.RegisterRoutes(protected)
			vehicleHandler.RegisterRoutes(protected)
			notificationHandler.RegisterRoutes(protected)
			financeHandler.RegisterRoutes(protected)
			deliveryHandler.RegisterRoutes(protected)
			salesTransferHandler.RegisterRoutes(protected)
			salesOrderHandler.RegisterRoutes(protected)
			salesOrderHandler.SetupMobileRoutes(protected)
			salesReturnHandler.RegisterRoutes(protected)
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
