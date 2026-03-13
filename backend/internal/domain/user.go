package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Role string

const (
	RoleSuperAdmin Role = "superadmin"
	RoleHRAdmin    Role = "hr_admin"
	RoleEmployee   Role = "employee"
)

type User struct {
	ID           uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	Email        string     `gorm:"type:varchar(255);unique;not null"`
	PasswordHash string     `gorm:"type:varchar(255);not null"`
	Role         Role       `gorm:"type:varchar(50);default:'employee'"`
	IsActive     bool       `gorm:"default:true"`
	CreatedAt    time.Time  `gorm:"default:now()"`
	UpdatedAt    time.Time  `gorm:"default:now()"`
	CompanyID    *uuid.UUID `gorm:"type:uuid"`
	LastLoginAt  *time.Time

	Company *Company `gorm:"foreignKey:CompanyID"`
}

func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return
}
