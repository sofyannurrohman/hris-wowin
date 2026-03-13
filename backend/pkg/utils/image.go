package utils

import (
	"bytes"
	"image/jpeg"

	"github.com/disintegration/imaging"
)

// CompressImage decodes an image from a byte slice, resizes it to a maximum width
// while preserving aspect ratio, and re-encodes it as a JPEG with the specified quality.
func CompressImage(data []byte, maxWidth int, quality int) ([]byte, error) {
	reader := bytes.NewReader(data)

	// Decode the image
	img, err := imaging.Decode(reader)
	if err != nil {
		return nil, err
	}

	// Resize the image if its width is greater than maxWidth
	if img.Bounds().Dx() > maxWidth {
		img = imaging.Resize(img, maxWidth, 0, imaging.Lanczos)
	}

	// Encode it back to a byte slice as JPEG
	var buf bytes.Buffer
	err = jpeg.Encode(&buf, img, &jpeg.Options{Quality: quality})
	if err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}
