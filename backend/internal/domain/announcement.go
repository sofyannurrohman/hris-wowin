package domain

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Announcement struct {
	ID        uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Title     string    `gorm:"type:varchar(255);not null" json:"title"`
	Content   string    `gorm:"type:text;not null" json:"content"`
	Category  string    `gorm:"type:varchar(50);default:'policy'" json:"category"` // policy, birthday, event
	Author    string    `gorm:"type:varchar(100)" json:"author"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	CreatedAt time.Time `gorm:"default:now()" json:"created_at"`
	UpdatedAt time.Time `gorm:"default:now()" json:"updated_at"`
}

func (a *Announcement) BeforeCreate(tx *gorm.DB) (err error) {
	if a.ID == uuid.Nil {
		a.ID = uuid.New()
	}
	return
}
