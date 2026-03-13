package domain

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// FloatArray is a custom type to allow GORM to save float arrays into PostgreSQL JSONB/Text columns
type FloatArray []float32

func (a FloatArray) Value() (driver.Value, error) {
	return json.Marshal(a)
}

func (a *FloatArray) Scan(value interface{}) error {
	b, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed")
	}
	return json.Unmarshal(b, &a)
}

type Employee struct {
	ID            uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID        uuid.UUID  `gorm:"type:uuid;not null"`
	CompanyID     *uuid.UUID `gorm:"type:uuid"`
	BranchID      *uuid.UUID `gorm:"type:uuid"`
	DepartmentID  *uuid.UUID `gorm:"type:uuid"`
	JobPositionID *uuid.UUID `gorm:"type:uuid"`

	// Personal Data
	EmployeeIDNumber   string     `gorm:"type:varchar(50);not null"`
	FirstName          string     `gorm:"type:varchar(100);not null"`
	LastName           string     `gorm:"type:varchar(100)"`
	PhoneNumber        string     `gorm:"type:varchar(20)"`
	Gender             string     `gorm:"type:varchar(10)"`
	BirthDate          *time.Time `gorm:"type:date"`
	BirthPlace         string     `gorm:"type:varchar(100)"`
	MaritalStatus      string     `gorm:"type:varchar(20)"`
	AddressKTP         string     `gorm:"type:text"`
	AddressResidential string     `gorm:"type:text"`
	EmergencyContact   string     `gorm:"type:text"`
	FaceReferenceURL   string     `gorm:"type:text"`
	FaceEmbedding      FloatArray `gorm:"type:jsonb"`
	IsFaceRegistered   bool

	// Government IDs
	IdentityNumber            string `gorm:"type:varchar(50)"`
	NpwpNumber                string `gorm:"type:varchar(50)"`
	BpjsKetenagakerjaanNumber string `gorm:"type:varchar(50)"`
	BpjsKesehatanNumber       string `gorm:"type:varchar(50)"`
	PtkpStatus                string `gorm:"type:varchar(10)"`

	// Bank Information
	BankName          string `gorm:"type:varchar(50)"`
	BankAccountNumber string `gorm:"type:varchar(50)"`
	AccountHolderName string `gorm:"type:varchar(100)"`

	// Employment Status
	JoinDate         time.Time  `gorm:"type:date;not null"`
	EndDate          *time.Time `gorm:"type:date"`
	EmploymentStatus string     `gorm:"type:varchar(50)"`
	ManagerID        *uuid.UUID `gorm:"type:uuid"`

	CreatedAt time.Time `gorm:"default:now()"`
	UpdatedAt time.Time `gorm:"default:now()"`

	User        *User        `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE;"`
	Company     *Company     `gorm:"foreignKey:CompanyID"`
	Branch      *Branch      `gorm:"foreignKey:BranchID"`
	Department  *Department  `gorm:"foreignKey:DepartmentID"`
	JobPosition *JobPosition `gorm:"foreignKey:JobPositionID"`
	Manager     *Employee    `gorm:"foreignKey:ManagerID"`
}

func (e *Employee) BeforeCreate(tx *gorm.DB) (err error) {
	if e.ID == uuid.Nil {
		e.ID = uuid.New()
	}
	return
}
