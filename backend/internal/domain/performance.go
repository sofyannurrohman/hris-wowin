package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// SalesKPI tracks Omzet/Sales targets for sales employees
type SalesKPI struct {
	ID             uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EmployeeID     uuid.UUID `gorm:"type:uuid;not null"`
	TargetOmzet    float64   `gorm:"type:decimal(15,2);not null"`
	AchievedOmzet  float64   `gorm:"type:decimal(15,2);default:0"`
	EstimatedBonus float64   `gorm:"type:decimal(15,2);default:0"`
	PeriodMonth    int       `gorm:"type:int;not null"`
	PeriodYear     int       `gorm:"type:int;not null"`
	CreatedAt      time.Time `gorm:"default:now()"`
	UpdatedAt      time.Time `gorm:"default:now()"`

	Employee *Employee `gorm:"foreignKey:EmployeeID;constraint:OnDelete:CASCADE;"`
}

func (s *SalesKPI) BeforeCreate(tx *gorm.DB) (err error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return
}

// EmployeeKPI tracks Attendance, Productivity, and general metrics for regular employees
type EmployeeKPI struct {
	ID                 uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EmployeeID         uuid.UUID `gorm:"type:uuid;not null"`
	AttendanceScore    float64   `gorm:"type:decimal(5,2);default:0"` // 0-100 scale
	ProductivityScore  float64   `gorm:"type:decimal(5,2);default:0"` // System generated 0-100 scale
	FinalScore         float64   `gorm:"type:decimal(5,2);default:0"` // Aggregate score
	PeriodMonth        int       `gorm:"type:int;not null"`
	PeriodYear         int       `gorm:"type:int;not null"`
	CreatedAt          time.Time `gorm:"default:now()"`
	UpdatedAt          time.Time `gorm:"default:now()"`

	Employee *Employee `gorm:"foreignKey:EmployeeID;constraint:OnDelete:CASCADE;"`
}

func (e *EmployeeKPI) BeforeCreate(tx *gorm.DB) (err error) {
	if e.ID == uuid.Nil {
		e.ID = uuid.New()
	}
	return
}

// ManagerialAppraisal tracks qualitative feedback and rating from a manager
type ManagerialAppraisal struct {
	ID             uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EmployeeID     uuid.UUID  `gorm:"type:uuid;not null"`
	ManagerID      uuid.UUID  `gorm:"type:uuid;not null"`
	ReviewNotes    string     `gorm:"type:text"`
	Rating         float64    `gorm:"type:decimal(3,2);not null"` // 1-5 scale
	ReviewDate     time.Time  `gorm:"type:date;not null"`
	CreatedAt      time.Time  `gorm:"default:now()"`

	Employee *Employee `gorm:"foreignKey:EmployeeID;constraint:OnDelete:CASCADE;"`
	Manager  *Employee `gorm:"foreignKey:ManagerID;constraint:OnDelete:CASCADE;"`
}

func (m *ManagerialAppraisal) BeforeCreate(tx *gorm.DB) (err error) {
	if m.ID == uuid.Nil {
		m.ID = uuid.New()
	}
	return
}
