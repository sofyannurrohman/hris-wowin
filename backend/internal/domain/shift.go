package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Shift struct {
	ID         uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	CompanyID  *uuid.UUID `gorm:"type:uuid"`
	Name       string     `gorm:"type:varchar(50);not null"`
	StartTime  time.Time  `gorm:"type:time;not null"`
	EndTime    time.Time  `gorm:"type:time;not null"`
	BreakStart *time.Time `gorm:"type:time"`
	BreakEnd   *time.Time `gorm:"type:time"`
	BranchID   *uuid.UUID `gorm:"type:uuid"`
	IsFlexible bool       `gorm:"default:false"`
	CreatedAt  time.Time  `gorm:"default:now()"`

	Company *Company `gorm:"foreignKey:CompanyID"`
	Branch  *Branch  `gorm:"foreignKey:BranchID"`
}

func (s *Shift) BeforeCreate(tx *gorm.DB) (err error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return
}

type EmployeeShift struct {
	ID         uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EmployeeID uuid.UUID `gorm:"type:uuid;not null"`
	ShiftID    uuid.UUID `gorm:"type:uuid;not null"`
	Date       time.Time `gorm:"type:date;not null;uniqueIndex:idx_emp_shift_date"`
	IsOffDay   bool      `gorm:"default:false"`

	Employee *Employee `gorm:"foreignKey:EmployeeID"`
	Shift    *Shift    `gorm:"foreignKey:ShiftID"`
}

func (es *EmployeeShift) BeforeCreate(tx *gorm.DB) (err error) {
	if es.ID == uuid.Nil {
		es.ID = uuid.New()
	}
	return
}
