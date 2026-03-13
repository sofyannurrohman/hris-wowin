package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AttendanceLog struct {
	ID         uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	EmployeeID uuid.UUID  `gorm:"type:uuid;not null"`
	ShiftID    *uuid.UUID `gorm:"type:uuid"`

	ClockInTime  *time.Time
	ClockOutTime *time.Time

	ClockInLat            float64 `gorm:"type:decimal(10,8)"`
	ClockInLong           float64 `gorm:"type:decimal(11,8)"`
	ClockInPhotoURL       string  `gorm:"type:text"`
	ClockInDeviceID       string  `gorm:"type:varchar(100)"`
	ClockInLocationStatus string  `gorm:"type:varchar(20)"`

	ClockOutLat      float64 `gorm:"type:decimal(10,8)"`
	ClockOutLong     float64 `gorm:"type:decimal(11,8)"`
	ClockOutPhotoURL string  `gorm:"type:text"`

	Status string `gorm:"type:varchar(20)"`
	Notes  string `gorm:"type:text"`

	CreatedAt time.Time `gorm:"default:now()"`
	UpdatedAt time.Time `gorm:"default:now()"`

	Employee *Employee `gorm:"foreignKey:EmployeeID"`
	Shift    *Shift    `gorm:"foreignKey:ShiftID"`
}

func (a *AttendanceLog) BeforeCreate(tx *gorm.DB) (err error) {
	if a.ID == uuid.Nil {
		a.ID = uuid.New()
	}
	return
}
