package main

import (
	"log"
	"math/rand"
	"time"

	"github.com/sofyan/hris_wowin/backend/config"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	log.Println("Starting database seeder...")

	cfg := config.LoadConfig()
	db := config.ConnectDB(cfg)

	rand.Seed(time.Now().UnixNano())

	// 1. Create Company
	company := domain.Company{
		Name:      "PT Sentraweb",
		TaxNumber: "123456789",
		Address:   "Jakarta Selatan",
	}
	if err := db.FirstOrCreate(&company, domain.Company{Name: company.Name}).Error; err != nil {
		log.Fatalf("Failed to seed company: %v", err)
	}
	log.Printf("Company seeded: %s\n", company.ID)

	// 2. Create Branch
	branch := domain.Branch{
		CompanyID: &company.ID,
		Name:      "Head Office",
		Address:   "Jakarta Selatan",
	}
	if err := db.FirstOrCreate(&branch, domain.Branch{Name: branch.Name}).Error; err != nil {
		log.Fatalf("Failed to seed branch: %v", err)
	}
	log.Printf("Branch seeded: %s\n", branch.ID)

	// 3. Create Departments
	departments := []domain.Department{
		{CompanyID: &company.ID, Name: "Engineering"},
		{CompanyID: &company.ID, Name: "Product"},
		{CompanyID: &company.ID, Name: "Human Resources"},
	}
	for i := range departments {
		if err := db.FirstOrCreate(&departments[i], domain.Department{Name: departments[i].Name}).Error; err != nil {
			log.Fatalf("Failed to seed department %s: %v", departments[i].Name, err)
		}
	}
	log.Println("Departments seeded.")

	// 4. Create Job Positions
	positions := []domain.JobPosition{
		{CompanyID: &company.ID, Title: "CTO", Level: 9},
		{CompanyID: &company.ID, Title: "Software Engineer", Level: 3},
		{CompanyID: &company.ID, Title: "HR Manager", Level: 5},
	}
	for i := range positions {
		if err := db.FirstOrCreate(&positions[i], domain.JobPosition{Title: positions[i].Title}).Error; err != nil {
			log.Fatalf("Failed to seed job position %s: %v", positions[i].Title, err)
		}
	}
	log.Println("Job Positions seeded.")

	// Hash password
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)

	// 5. Create Users and Employees (Admin)
	adminUser := domain.User{
		Email:        "sofyan@sentraweb.id",
		PasswordHash: string(hashedPassword),
		Role:         domain.RoleSuperAdmin,
		IsActive:     true,
		CompanyID:    &company.ID,
	}
	if err := db.Where(domain.User{Email: adminUser.Email}).FirstOrCreate(&adminUser).Error; err != nil {
		log.Fatalf("Failed to seed admin user: %v", err)
	}

	adminEmployee := domain.Employee{
		UserID:           adminUser.ID,
		CompanyID:        &company.ID,
		BranchID:         &branch.ID,
		DepartmentID:     &departments[0].ID,
		JobPositionID:    &positions[0].ID,
		EmployeeIDNumber: "EMP-001",
		FirstName:        "Sofyan",
		LastName:         "Nur Rohman",
		JoinDate:         time.Now().AddDate(-2, 0, 0),
		EmploymentStatus: "PERMANENT",
	}
	if err := db.Where(domain.Employee{EmployeeIDNumber: adminEmployee.EmployeeIDNumber}).FirstOrCreate(&adminEmployee).Error; err != nil {
		log.Fatalf("Failed to seed admin employee: %v", err)
	}
	log.Printf("Admin seeded: %s\n", adminEmployee.ID)

	// 6. Create Users and Employees (Staff)
	staffUser := domain.User{
		Email:        "staff@sentraweb.id",
		PasswordHash: string(hashedPassword),
		Role:         domain.RoleEmployee,
		IsActive:     true,
		CompanyID:    &company.ID,
	}
	if err := db.Where(domain.User{Email: staffUser.Email}).FirstOrCreate(&staffUser).Error; err != nil {
		log.Fatalf("Failed to seed staff user: %v", err)
	}

	staffEmployee := domain.Employee{
		UserID:           staffUser.ID,
		CompanyID:        &company.ID,
		BranchID:         &branch.ID,
		DepartmentID:     &departments[0].ID,
		JobPositionID:    &positions[1].ID,
		EmployeeIDNumber: "EMP-002",
		FirstName:        "Budi",
		LastName:         "Santoso",
		JoinDate:         time.Now().AddDate(-1, 0, 0),
		EmploymentStatus: "PERMANENT",
		ManagerID:        &adminEmployee.ID,
	}
	if err := db.Where(domain.Employee{EmployeeIDNumber: staffEmployee.EmployeeIDNumber}).FirstOrCreate(&staffEmployee).Error; err != nil {
		log.Fatalf("Failed to seed staff employee: %v", err)
	}
	log.Printf("Staff seeded: %s\n", staffEmployee.ID)

	allEmployees := []domain.Employee{adminEmployee, staffEmployee}

	// 7. Create Shifts and EmployeeShifts
	shiftTimeStart, _ := time.Parse("15:04", "09:00")
	shiftTimeEnd, _ := time.Parse("15:04", "18:00")
	shift := domain.Shift{
		CompanyID: &company.ID,
		Name:      "Regular Shift",
		StartTime: shiftTimeStart,
		EndTime:   shiftTimeEnd,
	}
	if err := db.FirstOrCreate(&shift, domain.Shift{Name: shift.Name}).Error; err != nil {
		log.Fatalf("Failed to seed shift: %v", err)
	}

	for _, emp := range allEmployees {
		db.FirstOrCreate(&domain.EmployeeShift{
			EmployeeID: emp.ID,
			ShiftID:    shift.ID,
			Date:       time.Now(),
		})
	}

	// 8. Create Random Attendances
	log.Println("Seeding attendances...")
	for _, emp := range allEmployees {
		for d := 0; d < 5; d++ {
			date := time.Now().AddDate(0, 0, -d)

			checkInHour := 8
			checkInMin := rand.Intn(90)
			if checkInMin >= 60 {
				checkInHour = 9
				checkInMin -= 60
			}
			checkInTime := time.Date(date.Year(), date.Month(), date.Day(), checkInHour, checkInMin, 0, 0, time.Local)
			checkOutTime := checkInTime.Add(time.Duration(8+rand.Intn(2)) * time.Hour)

			status := "PRESENT"
			if checkInHour == 9 {
				status = "LATE"
			}

			// Check if attendance already exists for this day
			var existingAtt domain.AttendanceLog
			startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.Local)
			endOfDay := startOfDay.AddDate(0, 0, 1)
			
			err := db.Where("employee_id = ? AND clock_in_time >= ? AND clock_in_time < ?", emp.ID, startOfDay, endOfDay).First(&existingAtt).Error
			if err != nil {
				att := domain.AttendanceLog{
					EmployeeID:   emp.ID,
					ShiftID:      &shift.ID,
					ClockInTime:  &checkInTime,
					ClockOutTime: &checkOutTime,
					ClockInLat:   -6.2088,
					ClockInLong:  106.8456,
					Status:       status,
				}
				db.Create(&att)
			}
		}
	}

	// 9. Leave Types & Leaves
	leaveType := domain.LeaveType{
		CompanyID: &company.ID,
		Name:      "Annual Leave",
	}
	if err := db.FirstOrCreate(&leaveType, domain.LeaveType{Name: leaveType.Name}).Error; err != nil {
		log.Fatalf("Failed to seed leave type: %v", err)
	}

	// 9b. Add Izin Types
	izinTypes := []domain.LeaveType{
		{CompanyID: &company.ID, Name: "Izin Sakit", IsPaid: true, RequiresQuota: false, DefaultQuota: 0},
		{CompanyID: &company.ID, Name: "Izin Terkena Musibah", IsPaid: true, RequiresQuota: false, DefaultQuota: 0},
		{CompanyID: &company.ID, Name: "Izin Lainnya", IsPaid: false, RequiresQuota: false, DefaultQuota: 0},
	}
	for _, it := range izinTypes {
		db.FirstOrCreate(&domain.LeaveType{}, it)
	}

	log.Println("Seeding leaves...")
	leaves := []domain.LeaveRequest{
		{EmployeeID: staffEmployee.ID, LeaveTypeID: leaveType.ID, StartDate: time.Now().AddDate(0, 0, 5), EndDate: time.Now().AddDate(0, 0, 8), Reason: "Vacation", Status: "PENDING"},
		{EmployeeID: staffEmployee.ID, LeaveTypeID: leaveType.ID, StartDate: time.Now().AddDate(0, 0, -2), EndDate: time.Now().AddDate(0, 0, -2), Reason: "Sick", Status: "APPROVED", ApprovedBy: &adminEmployee.ID},
	}
	for i := range leaves {
		db.Where(domain.LeaveRequest{
			EmployeeID: leaves[i].EmployeeID,
			StartDate:  leaves[i].StartDate,
			EndDate:    leaves[i].EndDate,
		}).FirstOrCreate(&leaves[i])
	}

	// 10. Create Overtimes
	log.Println("Seeding overtimes...")
	overtimes := []domain.Overtime{
		{EmployeeID: staffEmployee.ID, Date: time.Now().AddDate(0, 0, -1), StartTime: time.Now().AddDate(0, 0, -1).Add(18 * time.Hour), EndTime: time.Now().AddDate(0, 0, -1).Add(20 * time.Hour), DurationMinutes: 120, Reason: "Project deadline", Status: domain.OvertimePending},
	}
	for i := range overtimes {
		db.Where(domain.Overtime{
			EmployeeID: overtimes[i].EmployeeID,
			Date:       overtimes[i].Date,
			Reason:     overtimes[i].Reason,
		}).FirstOrCreate(&overtimes[i])
	}

	// 11. Initialize Leave Balances for all employees and types
	log.Println("Initializing leave balances...")
	var allEmployeesForBalances []domain.Employee
	db.Find(&allEmployeesForBalances)
	var allLeaveTypes []domain.LeaveType
	db.Find(&allLeaveTypes)

	currentYear := time.Now().Year()
	for _, emp := range allEmployeesForBalances {
		for _, lt := range allLeaveTypes {
			db.FirstOrCreate(&domain.LeaveBalance{}, domain.LeaveBalance{
				EmployeeID:  emp.ID,
				LeaveTypeID: lt.ID,
				Year:        currentYear,
			}).Updates(domain.LeaveBalance{
				BalanceTotal: lt.DefaultQuota,
			})
		}
	}

	log.Println("Database seeded successfully!")
}
