package config

import (
	"embed"
	"fmt"
	"log"
	"time"

	"github.com/golang-migrate/migrate/v4"
	migrate_postgres "github.com/golang-migrate/migrate/v4/database/postgres"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

//go:embed migrations/*.sql
var migrationsFS embed.FS

func ConnectDB(cfg Config) *gorm.DB {
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=UTC",
		cfg.DBHost, cfg.DBUser, cfg.DBPassword, cfg.DBName, cfg.DBPort)

	var db *gorm.DB
	var err error
	maxRetries := 5
	for i := 0; i < maxRetries; i++ {
		db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
			Logger: logger.Default.LogMode(logger.Info),
		})
		if err == nil {
			break
		}
		log.Printf("Failed to connect to database (attempt %d/%d). Retrying in 2 seconds... \n", i+1, maxRetries)
		time.Sleep(2 * time.Second)
	}

	if err != nil {
		log.Fatal("Failed to connect to database after maximum retries. \n", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatal("Failed to get DB instance. \n", err)
	}

	// Ensure timezone is UTC as required
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	log.Println("Connected Successfully to Database")

	// Database Migrations using golang-migrate
	log.Println("Running Migrations...")

	d, err := iofs.New(migrationsFS, "migrations")
	if err != nil {
		log.Fatal("Failed to load embedded migrations: \n", err)
	}

	driver, err := migrate_postgres.WithInstance(sqlDB, &migrate_postgres.Config{})
	if err != nil {
		log.Fatal("Failed to create migration driver: \n", err)
	}

	m, err := migrate.NewWithInstance(
		"iofs",
		d,
		"postgres",
		driver,
	)
	if err != nil {
		log.Fatal("Failed to initialize migration instance: \n", err)
	}

	// db.Exec("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";") is handled by init_schema.up.sql

	err = m.Up()
	if err != nil && err != migrate.ErrNoChange {
		log.Fatal("Migration failed: \n", err)
	}
	log.Println("Migrations completed")

	return db
}
