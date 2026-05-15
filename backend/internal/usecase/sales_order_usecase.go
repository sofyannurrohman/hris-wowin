package usecase

import (
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/sofyan/hris_wowin/backend/internal/domain"
	"github.com/sofyan/hris_wowin/backend/internal/repository"
	"github.com/sofyan/hris_wowin/backend/pkg/midtrans"
	"gorm.io/gorm"
)

// SalesOrderUsecase mendefinisikan kontrak bisnis untuk manajemen Pesanan Order (SO).
type SalesOrderUsecase interface {
	// Digunakan salesman (mobile) dan admin (web)
	CreateSO(req CreateSORequest) (*domain.SalesOrder, error)
	GetSOByEmployee(employeeID uuid.UUID) ([]domain.SalesOrder, error)

	// *** ALUR BARU ***
	// Digunakan Admin Nota (web) — verifikasi / tolak nota dari salesman
	AdminConfirmSO(id uuid.UUID, adminID uuid.UUID) error
	AdminRejectSO(id uuid.UUID, adminID uuid.UUID, notes string) error

	// Digunakan Driver (mobile) — konfirmasi pengiriman & tagih pembayaran per nota
	ConfirmDelivery(req ConfirmDeliveryRequest) error
	CollectPayment(req CollectPaymentRequest) (map[string]interface{}, error)

	// Digunakan semua role (web)
	GetSOByBranch(branchID uuid.UUID, status string) ([]domain.SalesOrder, error)
	GetSOByID(id uuid.UUID) (*domain.SalesOrder, error)
	CancelSO(id uuid.UUID) error
	DeleteSO(id uuid.UUID) error

	// Legacy methods — dipertahankan agar tidak break fitur lama
	ConfirmSO(id uuid.UUID, confirmedByID uuid.UUID) error
	RejectSO(id uuid.UUID, rejectedByID uuid.UUID, notes string) error
	ProcessByWarehouse(req ProcessByWarehouseRequest) error
	ConfirmPOD(req ConfirmPODRequest) error
	ConvertToInvoice(id uuid.UUID, companyID uuid.UUID) (*domain.SalesTransaction, error)
	OverrideBackorder(id uuid.UUID) error
}

// --- Request DTOs (Baru - Mobile POS) ---

type ConfirmDeliveryItem struct {
	ProductID        uuid.UUID `json:"product_id" binding:"required"`
	ReturnedQuantity int       `json:"returned_quantity"` // 0 if all delivered perfectly
}

type ConfirmDeliveryRequest struct {
	SOID          uuid.UUID             `json:"so_id" binding:"required"`
	ReceivedBy    string                `json:"received_by" binding:"required"`
	PODImageURL   string                `json:"pod_image_url"`
	Notes         string                `json:"notes"`
	ReturnedItems []ConfirmDeliveryItem `json:"returned_items"` // List of items being returned instantly
}

type CollectPaymentRequest struct {
	SOID          uuid.UUID `json:"so_id" binding:"required"`
	Amount        float64   `json:"amount" binding:"required"`
	PaymentMethod string    `json:"payment_method" binding:"required"` // CASH, QRIS, VA, TEMPO
	PaymentBank   string    `json:"payment_bank"`                      // For VA: 'bca', 'bni', 'bri'
	CollectedBy   string    `json:"collected_by"`
}

// --- Request DTOs (Legacy) ---

type ConfirmPODRequest struct {
	SOID        uuid.UUID `json:"so_id" binding:"required"`
	ReceivedBy  string    `json:"received_by" binding:"required"`
	PODImageURL string    `json:"pod_image_url"`
}

type ProcessByWarehouseRequest struct {
	SOID          uuid.UUID          `json:"so_id" binding:"required"`
	ProcessedByID uuid.UUID          `json:"processed_by_id"`
	Items         []WarehouseItemQty `json:"items" binding:"required,min=1"`
}

type WarehouseItemQty struct {
	ProductID uuid.UUID `json:"product_id" binding:"required"`
	ActualQty int       `json:"actual_qty" binding:"required"`
}


type salesOrderUsecase struct {
	soRepo         repository.SalesOrderRepository
	warehouseRepo  repository.WarehouseRepository
	salesRepo      repository.SalesTransactionRepository
	db             *gorm.DB
	midtransClient *midtrans.MidtransClient
}

func NewSalesOrderUsecase(
	soRepo repository.SalesOrderRepository,
	warehouseRepo repository.WarehouseRepository,
	salesRepo repository.SalesTransactionRepository,
	db *gorm.DB,
	midtransClient *midtrans.MidtransClient,
) SalesOrderUsecase {
	return &salesOrderUsecase{soRepo, warehouseRepo, salesRepo, db, midtransClient}
}

// --- Request DTOs ---

type CreateSORequest struct {
	BranchID      uuid.UUID          `json:"branch_id" binding:"required"`
	CompanyID     uuid.UUID          `json:"company_id" binding:"required"`
	EmployeeID    uuid.UUID          `json:"employee_id" binding:"required"`
	StoreID       uuid.UUID          `json:"store_id" binding:"required"`
	StoreCategory string             `json:"store_category"`
	Notes         string             `json:"notes"`
	Items         []SOItemRequest    `json:"items" binding:"required,min=1"`
	VisitID       *uuid.UUID         `json:"visit_id"`
}

type SOItemRequest struct {
	ProductID       uuid.UUID `json:"product_id" binding:"required"`
	OrderedQuantity int       `json:"ordered_quantity" binding:"required,min=1"`
	Unit            string    `json:"unit"`
	PiecesPerUnit   int       `json:"pieces_per_unit"`
	Price           float64   `json:"price"`
}

// --- Implementations ---

// CreateSO membuat Sales Order baru dengan status DRAFT.
// Pada tahap ini TIDAK ada perubahan stok sama sekali.
func (u *salesOrderUsecase) CreateSO(req CreateSORequest) (*domain.SalesOrder, error) {
	now := time.Now()

	count, err := u.soRepo.CountByBranchAndDate(req.BranchID, now)
	if err != nil {
		return nil, err
	}
	soNumber := repository.GenerateSONumber(req.BranchID, now, count)

	so := &domain.SalesOrder{
		SONumber:      soNumber,
		BranchID:      req.BranchID,
		CompanyID:     req.CompanyID,
		EmployeeID:    req.EmployeeID,
		StoreID:       req.StoreID,
		StoreCategory: req.StoreCategory,
		Status:        domain.SOStatusDraft,
		Notes:         req.Notes,
		OrderDate:     now,
		VisitID:       req.VisitID,
	}

	var totalAmount float64
	for _, item := range req.Items {
		ppu := item.PiecesPerUnit
		if ppu <= 0 {
			ppu = 1
		}
		unit := item.Unit
		if unit == "" {
			unit = "PCS"
		}
		totalQty := item.OrderedQuantity * ppu

		subtotal := float64(totalQty) * item.Price
		totalAmount += subtotal
		so.Items = append(so.Items, domain.SalesOrderItem{
			ProductID:       item.ProductID,
			Quantity:        totalQty,
			OrderedQuantity: item.OrderedQuantity,
			Unit:            unit,
			PiecesPerUnit:   ppu,
			Price:           item.Price,
			Subtotal:        subtotal,
		})
	}
	so.TotalAmount = totalAmount

	if err := u.soRepo.Create(so); err != nil {
		return nil, err
	}
	return u.soRepo.FindByID(so.ID)
}

// ConfirmSO mengkonfirmasi SO dan melakukan reserve stok di gudang.
// Validasi: stok tersedia (Quantity - ReservedQuantity) >= qty order untuk setiap item.
// ConfirmSO mengkonfirmasi SO dan melakukan reserve stok di gudang.
// Status berubah menjadi WAITING_WAREHOUSE untuk diproses oleh tim gudang.
func (u *salesOrderUsecase) ConfirmSO(id uuid.UUID, confirmedByID uuid.UUID) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		soRepo := repository.NewSalesOrderRepository(tx)
		wRepo := repository.NewWarehouseRepository(tx)

		so, err := soRepo.FindByID(id)
		if err != nil {
			return err
		}
		if so.Status != domain.SOStatusDraft {
			return errors.New("hanya SO dengan status DRAFT yang bisa dikonfirmasi")
		}

		// Validasi & Reserve stok (FEFO - First Expired First Out)
		allFulfilled := true
		for i := range so.Items {
			item := &so.Items[i]
			
			// Ambil semua batch yang tersedia (FEFO)
			batches, err := wRepo.GetAvailableBatches(so.BranchID, item.ProductID, "GOOD")
			if err != nil {
				return err
			}

			remainingToReserve := item.Quantity
			totalReserved := 0

			// 1. Reserve dari batch yang ada (FEFO)
			for _, b := range batches {
				if remainingToReserve <= 0 {
					break
				}

				availableInBatch := b.Quantity - b.ReservedQuantity
				if availableInBatch <= 0 {
					continue
				}

				alloc := remainingToReserve
				if availableInBatch < remainingToReserve {
					alloc = availableInBatch
				}

				if err := wRepo.ReserveStock(so.BranchID, item.ProductID, b.BatchNo, alloc); err != nil {
					return err
				}

				// Simpan rincian batch
				resBatch := &domain.SalesOrderItemBatch{
					SalesOrderItemID: item.ID,
					BatchNo:          b.BatchNo,
					Quantity:         alloc,
				}
				if err := tx.Create(resBatch).Error; err != nil {
					return err
				}

				totalReserved += alloc
				remainingToReserve -= alloc
			}

			// 2. Jika masih ada sisa (Backorder), reserve dari batch "BACKORDER"
			if remainingToReserve > 0 {
				allFulfilled = false
				if err := wRepo.ReserveStock(so.BranchID, item.ProductID, "BACKORDER", remainingToReserve); err != nil {
					return err
				}
				// Simpan rincian batch backorder
				resBatch := &domain.SalesOrderItemBatch{
					SalesOrderItemID: item.ID,
					BatchNo:          "BACKORDER",
					Quantity:         remainingToReserve,
				}
				if err := tx.Create(resBatch).Error; err != nil {
					return err
				}
				totalReserved += remainingToReserve
			}

			item.ReservedQuantity = totalReserved
			// Update item reserved qty in DB
			if err := tx.Model(item).Update("reserved_quantity", totalReserved).Error; err != nil {
				return err
			}
		}

		now := time.Now()
		if allFulfilled {
			so.Status = domain.SOStatusWaitingWarehouse
		} else {
			so.Status = domain.SOStatusWaitingStock
		}
		
		so.ConfirmedAt = &now
		so.ConfirmedByID = &confirmedByID
		return soRepo.Update(so)
	})
}


// CancelSO membatalkan SO. Jika SO sudah ter-reserve, stok reserve dilepas kembali.
func (u *salesOrderUsecase) CancelSO(id uuid.UUID) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		soRepo := repository.NewSalesOrderRepository(tx)
		wRepo := repository.NewWarehouseRepository(tx)

		so, err := soRepo.FindByID(id)
		if err != nil {
			return err
		}
		if so.Status == domain.SOStatusConverted || so.Status == domain.SOStatusShipped {
			return errors.New("SO yang sudah diproses tidak dapat dibatalkan")
		}

		// Lepaskan reserve stok jika statusnya WAITING_WAREHOUSE atau WAITING_STOCK
		if so.Status == domain.SOStatusWaitingWarehouse || so.Status == domain.SOStatusWaitingStock {
			for _, item := range so.Items {
				for _, b := range item.Batches {
					if b.Quantity > 0 {
						if err := wRepo.ReleaseStock(so.BranchID, item.ProductID, b.BatchNo, b.Quantity); err != nil {
							return err
						}
					}
				}
			}
		}

		so.Status = domain.SOStatusCancelled
		return soRepo.Update(so)
	})
}

// RejectSO menolak SO oleh admin gudang. Stok reserve dilepas kembali.
func (u *salesOrderUsecase) RejectSO(id uuid.UUID, rejectedByID uuid.UUID, notes string) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		soRepo := repository.NewSalesOrderRepository(tx)
		wRepo := repository.NewWarehouseRepository(tx)

		so, err := soRepo.FindByID(id)
		if err != nil {
			return err
		}
		if so.Status != domain.SOStatusDraft && so.Status != domain.SOStatusWaitingWarehouse && so.Status != domain.SOStatusProcessing && so.Status != domain.SOStatusWaitingStock {
			return errors.New("hanya SO dengan status DRAFT, antrian, atau proses gudang yang bisa ditolak")
		}

		// Lepaskan reserve stok
		for _, item := range so.Items {
			for _, b := range item.Batches {
				if b.Quantity > 0 {
					if err := wRepo.ReleaseStock(so.BranchID, item.ProductID, b.BatchNo, b.Quantity); err != nil {
						return err
					}
				}
			}
		}

		now := time.Now()
		so.Status = domain.SOStatusRejected
		so.RejectedAt = &now
		so.RejectedByID = &rejectedByID
		so.Notes = notes
		return soRepo.Update(so)
	})
}

// ProcessByWarehouse melakukan validasi fisik barang oleh gudang.


// Hasilnya adalah Surat Jalan (DO) dan status berubah menjadi SHIPPED.
func (u *salesOrderUsecase) ProcessByWarehouse(req ProcessByWarehouseRequest) error {
	return u.db.Transaction(func(tx *gorm.DB) error {
		soRepo := repository.NewSalesOrderRepository(tx)
		wRepo := repository.NewWarehouseRepository(tx)

		so, err := soRepo.FindByID(req.SOID)
		if err != nil {
			return err
		}
		if so.Status != domain.SOStatusWaitingWarehouse && so.Status != domain.SOStatusProcessing {
			return errors.New("SO tidak dalam status untuk diproses gudang")
		}

		// Generate Nomor Surat Jalan (DO)
		now := time.Now()
		// Untuk kemudahan, kita pakai format DO-SO_NUMBER
		doNo := "DO-" + so.SONumber

		// Map input qty dari request
		qtyMap := make(map[uuid.UUID]int)
		for _, it := range req.Items {
			qtyMap[it.ProductID] = it.ActualQty
		}

		// Update items dan mutasi stok fisik
		for i, item := range so.Items {
			actualQty, exists := qtyMap[item.ProductID]
			if !exists {
				actualQty = 0 // Jika tidak diinput gudang, anggap 0
			}
			
			so.Items[i].ActualQuantity = actualQty
			
			// 1. Potong Stok Fisik permanen & Lepas Reserve dari Batch
			remainingToDeduct := actualQty
			for _, b := range item.Batches {
				deductFromThisBatch := b.Quantity
				if deductFromThisBatch > remainingToDeduct {
					deductFromThisBatch = remainingToDeduct
				}

				if deductFromThisBatch > 0 {
					stock, err := wRepo.GetStock(so.BranchID, item.ProductID, "GOOD", b.BatchNo)
					if err != nil {
						return err
					}
					stock.Quantity -= deductFromThisBatch
					stock.ReservedQuantity -= deductFromThisBatch
					if err := wRepo.UpdateStock(stock); err != nil {
						return err
					}
					remainingToDeduct -= deductFromThisBatch
				}

				// Jika actualQty < reserved, sisa reservasi di batch ini harus dilepas
				// Simple: release whatever was reserved in this batch
				if b.Quantity > deductFromThisBatch {
					if err := wRepo.ReleaseStock(so.BranchID, item.ProductID, b.BatchNo, b.Quantity-deductFromThisBatch); err != nil {
						return err
					}
				}
			}

			// 3. Catat Log Mutasi Gudang (Surat Jalan)
			if actualQty > 0 {
				wRepo.CreateLog(&domain.WarehouseLog{
					BranchID:  so.BranchID,
					ProductID: item.ProductID,
					Type:      "OUT",
					Source:    "SURAT_JALAN: " + doNo,
					Quantity:  actualQty,
				})
			}
		}

		so.Status = domain.SOStatusShipped
		so.DeliveryOrderNo = &doNo
		so.ShippedAt = &now
		// Gudang hanya konfirmasi stok keluar — pembuatan invoice dilakukan driver setelah barang sampai
		return soRepo.Update(so)
	})
}

// ConfirmPOD mengkonfirmasi barang telah sampai di tangan pelanggan.
func (u *salesOrderUsecase) ConfirmPOD(req ConfirmPODRequest) error {
	so, err := u.soRepo.FindByID(req.SOID)
	if err != nil {
		return err
	}
	if so.Status != domain.SOStatusShipped {
		return errors.New("hanya pesanan yang sedang dikirim (SHIPPED) yang bisa dikonfirmasi terima")
	}

	now := time.Now()
	so.Status = domain.SOStatusDelivered
	so.ReceivedAt = &now
	so.ReceivedBy = req.ReceivedBy
	if req.PODImageURL != "" {
		so.PODImageURL = &req.PODImageURL
	}
	return u.soRepo.Update(so)
}

// ConvertToInvoice mengkonversi SO yang sudah DELIVERED menjadi SalesTransaction (Invoice).
func (u *salesOrderUsecase) ConvertToInvoice(id uuid.UUID, companyID uuid.UUID) (*domain.SalesTransaction, error) {
	var resultInvoice *domain.SalesTransaction

	err := u.db.Transaction(func(tx *gorm.DB) error {
		soRepo := repository.NewSalesOrderRepository(tx)
		salesRepo := repository.NewSalesTransactionRepository(tx)

		so, err := soRepo.FindByID(id)
		if err != nil {
			return err
		}
		if so.Status != domain.SOStatusDelivered {
			return errors.New("hanya SO yang sudah diterima pelanggan (DELIVERED) yang bisa diterbitkan fakturnya")
		}

		// Generate nomor invoice
		now := time.Now()
		invoiceCount, _ := salesRepo.CountByCompanyAndDate(companyID, now)
		invoiceNo := fmt.Sprintf("INV-%s-%04d", now.Format("20060102"), invoiceCount+1)

		// Hitung ulang TotalAmount berdasarkan ActualQuantity
		var actualTotal float64
		for _, it := range so.Items {
			actualTotal += float64(it.ActualQuantity) * it.Price
		}

		// Buat SalesTransaction (Invoice)
		invoice := &domain.SalesTransaction{
			CompanyID:       companyID,
			StoreID:         so.StoreID,
			EmployeeID:      so.EmployeeID,
			ReceiptNo:       invoiceNo,
			TotalAmount:     actualTotal,
			StoreCategory:   so.StoreCategory,
			TransactionDate: now,
			PeriodMonth:     int(now.Month()),
			PeriodYear:      now.Year(),
			Status:          "VERIFIED",
			PaymentStatus:   string(domain.PaymentStatusUnpaid),
			PaymentMethod:   "CASH",
			Notes:           &so.Notes,
		}

		for _, soItem := range so.Items {
			if soItem.ActualQuantity > 0 {
				invoice.Items = append(invoice.Items, domain.SalesItem{
					ProductID:          soItem.ProductID,
					Quantity:           soItem.ActualQuantity,
					PriceAtTransaction: soItem.Price,
					Subtotal:           float64(soItem.ActualQuantity) * soItem.Price,
				})
			}
		}

		if err := salesRepo.Create(invoice); err != nil {
			return err
		}

		// Update SO ke CONVERTED
		invoiceID := invoice.ID
		so.Status = domain.SOStatusConverted
		so.InvoiceID = &invoiceID
		so.ConvertedAt = &now
		if err := soRepo.Update(so); err != nil {
			return err
		}

		resultInvoice = invoice
		return nil
	})

	return resultInvoice, err
}


// DeleteSO menghapus SO permanen. Hanya SO dengan status DRAFT yang bisa dihapus.
func (u *salesOrderUsecase) DeleteSO(id uuid.UUID) error {
	so, err := u.soRepo.FindByID(id)
	if err != nil {
		return err
	}
	if so.Status != domain.SOStatusDraft {
		return errors.New("hanya SO dengan status DRAFT yang bisa dihapus")
	}
	return u.soRepo.Delete(id)
}

func (u *salesOrderUsecase) GetSOByEmployee(employeeID uuid.UUID) ([]domain.SalesOrder, error) {
	return u.soRepo.FindByEmployee(employeeID)
}

func (u *salesOrderUsecase) GetSOByBranch(branchID uuid.UUID, status string) ([]domain.SalesOrder, error) {
	return u.soRepo.FindByBranch(branchID, status)
}

func (u *salesOrderUsecase) GetSOByID(id uuid.UUID) (*domain.SalesOrder, error) {
	return u.soRepo.FindByID(id)
}


func (u *salesOrderUsecase) OverrideBackorder(id uuid.UUID) error {
	so, err := u.soRepo.FindByID(id)
	if err != nil {
		return err
	}
	if so.Status != domain.SOStatusWaitingStock {
		return errors.New("hanya pesanan dalam antrean backorder yang bisa di-override")
	}

	so.Status = domain.SOStatusWaitingWarehouse
	return u.soRepo.Update(so)
}

// =============================================================================
// ALUR BARU: Admin Nota, Driver, & Pembayaran
// =============================================================================

// AdminConfirmSO digunakan Admin Nota untuk menyetujui nota pesanan dari salesman.
// Status berubah DRAFT → CONFIRMED, sehingga nota siap dibatch oleh Supervisor.
func (u *salesOrderUsecase) AdminConfirmSO(id uuid.UUID, adminID uuid.UUID) error {
	so, err := u.soRepo.FindByID(id)
	if err != nil {
		return err
	}
	if so.Status != domain.SOStatusDraft {
		return errors.New("hanya pesanan dengan status DRAFT yang bisa diverifikasi")
	}

	now := time.Now()
	so.Status = domain.SOStatusConfirmed
	so.AdminNotaConfirmedAt = &now
	so.AdminNotaConfirmedByID = &adminID
	return u.soRepo.Update(so)
}

// AdminRejectSO digunakan Admin Nota untuk menolak nota pesanan dari salesman.
func (u *salesOrderUsecase) AdminRejectSO(id uuid.UUID, adminID uuid.UUID, notes string) error {
	so, err := u.soRepo.FindByID(id)
	if err != nil {
		return err
	}
	if so.Status != domain.SOStatusDraft {
		return errors.New("hanya pesanan dengan status DRAFT yang bisa ditolak oleh Admin Nota")
	}

	now := time.Now()
	so.Status = domain.SOStatusRejected
	so.RejectedAt = &now
	so.RejectedByID = &adminID
	so.AdminNotaRejectNotes = notes
	return u.soRepo.Update(so)
}

// ConfirmDelivery digunakan Driver untuk mengkonfirmasi bahwa barang sudah diserahkan ke customer.
// Status SO berubah IN_DELIVERY → DELIVERED.
func (u *salesOrderUsecase) ConfirmDelivery(req ConfirmDeliveryRequest) error {
	so, err := u.soRepo.FindByID(req.SOID)
	if err != nil {
		return err
	}
	if so.Status != domain.SOStatusInDelivery {
		return fmt.Errorf("pesanan tidak dalam status pengiriman aktif (status saat ini: %s)", so.Status)
	}

	// 1. Process Instant Returns & Recalculate Total
	returnedMap := make(map[uuid.UUID]int)
	for _, ri := range req.ReturnedItems {
		returnedMap[ri.ProductID] = ri.ReturnedQuantity
	}

	newTotalAmount := 0.0
	for i := range so.Items {
		item := &so.Items[i]
		retQty := returnedMap[item.ProductID]
		
		// If returned, ActualQuantity is ordered - returned. Otherwise, ActualQuantity = ordered.
		item.ActualQuantity = item.OrderedQuantity - retQty
		if item.ActualQuantity < 0 {
			item.ActualQuantity = 0
		}
		
		// Recalculate subtotal
		item.Subtotal = float64(item.ActualQuantity * item.PiecesPerUnit) * item.Price
		newTotalAmount += item.Subtotal
	}

	so.TotalAmount = newTotalAmount

	// 2. Update SO Status
	now := time.Now()
	so.Status = domain.SOStatusDelivered
	so.ReceivedAt = &now
	so.ReceivedBy = req.ReceivedBy
	if req.PODImageURL != "" {
		so.PODImageURL = &req.PODImageURL
	}
	if req.Notes != "" {
		if so.Notes != "" {
			so.Notes += "\n" + req.Notes
		} else {
			so.Notes = req.Notes
		}
	}

	// 3. Save SO (this will save Items if GORM configured to save associations, or we do it explicitly)
	// For safety, we update SO first, then loop items to save if needed, but since it's a pointer, Save(so) updates associations in GORM by default.
	return u.soRepo.Update(so)
}

// CollectPayment digunakan Driver untuk mencatat tagihan pembayaran yang diterima dari customer.
// Status SO berubah DELIVERED → PAID (jika full) atau tetap DELIVERED dengan PaymentStatus PARTIAL.
func (u *salesOrderUsecase) CollectPayment(req CollectPaymentRequest) (map[string]interface{}, error) {
	so, err := u.soRepo.FindByID(req.SOID)
	if err != nil {
		return nil, err
	}
	if so.Status != domain.SOStatusDelivered && so.Status != domain.SOStatusPaid {
		return nil, errors.New("pembayaran hanya bisa dicatat setelah barang dikonfirmasi diterima customer")
	}

	now := time.Now()
	resData := make(map[string]interface{})

	// 1. Midtrans Logic (QRIS / VA)
	if (req.PaymentMethod == "QRIS" || req.PaymentMethod == "VA") && u.midtransClient != nil {
		orderID := fmt.Sprintf("PAY-SO-%s-%d", so.SONumber, now.Unix())
		
		if req.PaymentMethod == "QRIS" {
			resp, err := u.midtransClient.CreateQRIS(orderID, int64(req.Amount))
			if err == nil && resp != nil {
				for _, action := range resp.Actions {
					if action.Name == "generate-qr-code" {
						resData["midtrans_qris_url"] = action.URL
						break
					}
				}
			}
		} else if req.PaymentMethod == "VA" && req.PaymentBank != "" {
			resp, err := u.midtransClient.CreateBankTransfer(orderID, int64(req.Amount), req.PaymentBank)
			if err == nil && resp != nil {
				if len(resp.VaNumbers) > 0 {
					resData["midtrans_va_number"] = resp.VaNumbers[0].VANumber
					resData["midtrans_bank"] = resp.VaNumbers[0].Bank
				} else if resp.BillKey != "" {
					resData["midtrans_bill_key"] = resp.BillKey
					resData["midtrans_biller_code"] = resp.BillerCode
					resData["midtrans_bank"] = "mandiri"
				}
			}
		}
	}

	// 2. Record Payment Log
	payment := domain.SalesPayment{
		SalesOrderID:   &so.ID,
		Amount:         req.Amount,
		PaymentMethod:  req.PaymentMethod,
		CollectedBy:    req.CollectedBy,
		PaymentStatus:  "SUCCESS", // Default for cash, digital status handled via webhook
	}
	if err := u.soRepo.AddPayment(&payment); err != nil {
		return nil, err
	}

	// 3. Update SO Totals
	so.PaymentCollectedAmount += req.Amount
	so.PaymentCollectedAt = &now
	so.PaymentMethod = req.PaymentMethod

	if so.PaymentCollectedAmount >= so.TotalAmount {
		so.PaymentStatus = "PAID"
		so.Status = domain.SOStatusPaid
	} else {
		so.PaymentStatus = "PARTIAL"
	}

	if err := u.soRepo.Update(so); err != nil {
		return nil, err
	}

	return resData, nil
}

