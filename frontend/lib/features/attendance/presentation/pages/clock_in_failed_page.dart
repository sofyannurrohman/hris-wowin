import 'package:flutter/material.dart';

class ClockInFailedPage extends StatelessWidget {
  final String errorMessage;

  const ClockInFailedPage({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF2F2), // Light red tint
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Clock In',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Error Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 15,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Color(0xFFDC2626), // Red
                      size: 60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Title
              const Text(
                'Clock In Gagal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626), // Red
                ),
              ),
              const SizedBox(height: 24),
              
              // Message Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2), // Lighter red box
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  children: [
                    Text(
                      errorMessage.isNotEmpty ? errorMessage : "Tidak dapat mengidentifikasi wajah Anda. Wajah Anda tidak jelas.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.visibility_off_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text('Cek kondisi pencahayaan', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.face, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text('Hapus masker atau kacamata', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Try Again Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Go back to Home to try again
                },
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626), // Red
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 16),
              
              // Contact Support Button
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.support_agent),
                label: const Text('Hubungi Bantuan'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              // Bottom Handle mock
              Center(
                child: Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
