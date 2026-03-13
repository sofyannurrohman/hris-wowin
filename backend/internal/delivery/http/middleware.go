package http

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/sofyan/hris_wowin/backend/pkg/utils"
)

func AuthMiddleware(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			utils.ErrorResponse(c, http.StatusUnauthorized, "Authorization header required")
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			utils.ErrorResponse(c, http.StatusUnauthorized, "Authorization header format must be Bearer {token}")
			c.Abort()
			return
		}

		claims, err := utils.ValidateToken(parts[1], secret)
		if err != nil {
			utils.ErrorResponse(c, http.StatusUnauthorized, "Invalid or expired token")
			c.Abort()
			return
		}

		c.Set("userID", claims.UserID)
		c.Set("user_id", claims.UserID.String()) // Compatibility for handlers expecting string
		c.Set("companyID", claims.CompanyID)
		c.Set("role", claims.Role)
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
