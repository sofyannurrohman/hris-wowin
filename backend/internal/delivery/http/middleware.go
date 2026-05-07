package http

import (
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/usecase"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

func AuthMiddleware(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		token := ""

		if authHeader != "" {
			parts := strings.Split(authHeader, " ")
			if len(parts) == 2 && parts[0] == "Bearer" {
				token = parts[1]
			}
		}

		// Fallback to query parameter for window.open/exports
		if token == "" {
			token = c.Query("token")
		}

		if token == "" {
			utils.ErrorResponse(c, http.StatusUnauthorized, "Authorization token required")
			c.Abort()
			return
		}

		claims, err := utils.ValidateToken(token, secret)
		if err != nil {
			// Log the actual error internally for debugging
			log.Printf("Token validation failed: %v", err)
			utils.ErrorResponse(c, http.StatusUnauthorized, "Invalid or expired token")
			c.Abort()
			return
		}

		c.Set("userID", claims.UserID)
		c.Set("user_id", claims.UserID.String()) // Compatibility
		c.Set("companyID", claims.CompanyID)
		c.Set("company_id", claims.CompanyID.String()) // Compatibility
		c.Set("role", claims.Role)
		c.Next()
	}
}

func EmployeeMiddleware(employeeUseCase usecase.EmployeeUsecase) gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr, exists := c.Get("user_id")
		if !exists {
			c.Next()
			return
		}

		userID := uuid.MustParse(userIDStr.(string))
		employee, err := employeeUseCase.GetEmployeeByUserID(userID)
		if err == nil && employee != nil {
			c.Set("employeeID", employee.ID)
			c.Set("employee_id", employee.ID.String())
			if employee.BranchID != nil {
				c.Set("branchID", *employee.BranchID)
				c.Set("branch_id", employee.BranchID.String())
			}
			if employee.CompanyID != nil {
				c.Set("companyID", *employee.CompanyID)
				c.Set("company_id", employee.CompanyID.String())
			}
		}

		c.Next()
	}
}

func RoleMiddleware(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole, exists := c.Get("role")
		if !exists {
			utils.ErrorResponse(c, http.StatusUnauthorized, "Unauthorized")
			c.Abort()
			return
		}

		valid := false
		for _, role := range roles {
			if role == userRole.(string) {
				valid = true
				break
			}
		}

		if !valid {
			utils.ErrorResponse(c, http.StatusForbidden, "Forbidden: insufficient permissions")
			c.Abort()
			return
		}

		c.Next()
	}
}
