import 'package:flutter/material.dart';

class ClockOutFailedPage extends StatelessWidget {
  final String errorMessage;

  const ClockOutFailedPage({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox(), // Hidden back button in mockup
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Error Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2), // Light red
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626), // Red
                      size: 60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Clock Out Gagal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A), // Slate 900
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                "Koneksi internet Anda tidak terdeteksi. Silahkan periksa sinyal atau pilih jaringan lainnya dan coba lagi.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 32),

              // Diagnostic Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), // Slate 50
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DIAGNOSTIC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          const SizedBox(height: 4),
                          Text(
                            'Error: ${errorMessage.isNotEmpty ? errorMessage : '503-NET_TIMEOUT'}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Timestamp: 17:02 PM • Location: Unavailable',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Retry Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Go back to Home to try again
                },
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Retry Clock Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8), // Royal blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 16),
              
              // Save Offline Button
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.cloud_off),
                label: const Text(
                  'Save Offline & Sync Later',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 24),
              
              // Contact HR
              Center(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Perlu bantuan? Hubungi HR'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1D4ED8),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Center(
                child: Text(
                  'PT WOWIN POERNOMO PUTRA\nv4.2.0 (Build 392)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1),
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
