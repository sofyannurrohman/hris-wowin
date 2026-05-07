package midtrans

import (
	"os"

	"github.com/midtrans/midtrans-go"
	"github.com/midtrans/midtrans-go/coreapi"
)

type MidtransClient struct {
	CoreAPI coreapi.Client
}

func NewMidtransClient() *MidtransClient {
	serverKey := os.Getenv("MIDTRANS_SERVER_KEY")
	env := midtrans.Sandbox
	if os.Getenv("MIDTRANS_IS_PRODUCTION") == "true" {
		env = midtrans.Production
	}

	client := coreapi.Client{}
	client.New(serverKey, env)

	return &MidtransClient{
		CoreAPI: client,
	}
}

func (m *MidtransClient) CreateQRIS(orderID string, amount int64) (*coreapi.ChargeResponse, error) {
	req := &coreapi.ChargeReq{
		PaymentType: coreapi.PaymentTypeQris,
		TransactionDetails: midtrans.TransactionDetails{
			OrderID:  orderID,
			GrossAmt: amount,
		},
		Qris: &coreapi.QrisDetails{
			Acquirer: "gopay", // Default acquirer for QRIS
		},
	}

	return m.CoreAPI.ChargeTransaction(req)
}

func (m *MidtransClient) CreateBankTransfer(orderID string, amount int64, bank string) (*coreapi.ChargeResponse, error) {
	if bank == "mandiri" {
		req := &coreapi.ChargeReq{
			PaymentType: coreapi.PaymentTypeEChannel,
			TransactionDetails: midtrans.TransactionDetails{
				OrderID:  orderID,
				GrossAmt: amount,
			},
			EChannel: &coreapi.EChannelDetail{
				BillInfo1: "Pembayaran Sales",
				BillInfo2: "Wowin Indonesia",
			},
		}
		return m.CoreAPI.ChargeTransaction(req)
	}

	var bankEnum midtrans.Bank
	switch bank {
	case "bca":
		bankEnum = midtrans.BankBca
	case "bni":
		bankEnum = midtrans.BankBni
	case "bri":
		bankEnum = midtrans.BankBri
	default:
		bankEnum = midtrans.BankBca
	}

	req := &coreapi.ChargeReq{
		PaymentType: coreapi.PaymentTypeBankTransfer,
		TransactionDetails: midtrans.TransactionDetails{
			OrderID:  orderID,
			GrossAmt: amount,
		},
		BankTransfer: &coreapi.BankTransferDetails{
			Bank: bankEnum,
		},
	}

	return m.CoreAPI.ChargeTransaction(req)
}
