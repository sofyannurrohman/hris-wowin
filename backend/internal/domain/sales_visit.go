package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SalesVisit struct {
	ID           uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	EmployeeID   uuid.UUID  `gorm:"type:uuid;not null" json:"employee_id"`
	StoreID      uuid.UUID  `gorm:"type:uuid;not null" json:"store_id"`
	
	CheckInTime  time.Time  `gorm:"not null" json:"check_in_time"`
	CheckOutTime *time.Time `json:"check_out_time"`
	
	Latitude     float64    `gorm:"type:decimal(10,8)" json:"latitude"`
	Longitude    float64    `gorm:"type:decimal(11,8)" json:"longitude"`
	SelfieURL    string     `gorm:"type:text" json:"selfie_url"`
	
	Notes        string     `gorm:"type:text" json:"notes"`
	Type         string     `gorm:"type:varchar(20);default:'CHECKIN'" json:"type"` // 'CHECKIN', 'CHECKOUT'
	
	CreatedAt    time.Time  `gorm:"default:now()" json:"created_at"`
	UpdatedAt    time.Time  `gorm:"default:now()" json:"updated_at"`
	
	Employee     *Employee  `gorm:"foreignKey:EmployeeID" json:"employee,omitempty"`
	Store        *Store     `gorm:"foreignKey:StoreID" json:"store,omitempty"`
	Transactions []SalesTransaction `gorm:"foreignKey:VisitID" json:"transactions,omitempty"`
}

func (s *SalesVisit) BeforeCreate(tx *gorm.DB) (err error) {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return
}
