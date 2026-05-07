package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	DBHost     string
	DBUser     string
	DBPassword string
	DBName     string
	DBPort     string
	ServerPort string
	JWTSecret  string
	SMTPHost   string
	SMTPPort   string
	SMTPUser   string
	SMTPPass   string
	SMTPFrom   string
	MidtransServerKey  string
	MidtransIsProduction bool
}

func LoadConfig() Config {
	err := godotenv.Load(".env")
	if err != nil {
		err = godotenv.Load("../../.env")
	}
	
	if err != nil {
		log.Println("No .env file found or error loading it, looking at environment variables")
	} else {
		log.Println("Loaded configuration from .env file")
	}

	return Config{
		DBHost:     getEnv("DB_HOST", "localhost"),
		DBUser:     getEnv("DB_USER", "root"),
		DBPassword: getEnv("DB_PASSWORD", "secretpassword"),
		DBName:     getEnv("DB_NAME", "hris_db"),
		DBPort:     getEnv("DB_PORT", "5321"),
		ServerPort: getEnv("SERVER_PORT", "8080"),
		JWTSecret:  getEnv("JWT_SECRET", "supersecretkey"),
		SMTPHost:   getEnv("SMTP_HOST", "smtp.gmail.com"),
		SMTPPort:   getEnv("SMTP_PORT", "587"),
		SMTPUser:   getEnv("SMTP_USER", ""),
		SMTPPass:   getEnv("SMTP_PASS", ""),
		SMTPFrom:   getEnv("SMTP_FROM", ""),
		MidtransServerKey:  getEnv("MIDTRANS_SERVER_KEY", ""),
		MidtransIsProduction: getEnv("MIDTRANS_IS_PRODUCTION", "false") == "true",
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
