package main

import (
	"encoding/json"
	"fmt"
	"github.com/google/uuid"
)

type TestReq struct {
	ID *uuid.UUID `json:"id"`
}

func main() {
	jsonData := `{"id": ""}`
	var req TestReq
	err := json.Unmarshal([]byte(jsonData), &req)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
	} else {
		fmt.Printf("Success: %v\n", req.ID)
	}
}
