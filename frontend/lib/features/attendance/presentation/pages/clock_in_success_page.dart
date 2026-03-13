import 'package:flutter/material.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';
import 'package:hris_app/features/home/presentation/pages/home_page.dart';
import 'package:intl/intl.dart';


class ClockInSuccessPage extends StatelessWidget {
  final Attendance attendance;

  const ClockInSuccessPage({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    final checkInTime = DateFormat('HH:mm').format(attendance.checkIn);
    final ampm = DateFormat('a').format(attendance.checkIn);
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(attendance.checkIn).toUpperCase();

    // Convert the API selfie path (assuming it starts with /uploads/...)
    // to a local file path because the flutter app is picking it from the camera.
    // However, if the `selfiePath` from `attendance` is actually an HTTP URL (from backend),
    // we should use Image.network. For now, since it returns local path strings when uploaded,
    // or maybe the backend returns a URL. Let's handle it as a network image assuming full URL,
    // or fallback to a local file if it's the raw path from the camera block.
    // Based on `attendance_usecase.go`, it returns `"/uploads/selfies/uuid_123.jpg"`. 
    // We would need the full base URL. Since we don't have it explicitly here, we can show a placeholder if needed,
    // or assume we have the original camera path. Let's just use the returned path appended to the API base URL.
    // For simplicity of UI dev, we can extract the base url or just use a placeholder icon.
    final bool hasSelfie = attendance.selfiePath.isNotEmpty;
    // Assuming backend runs on 10.0.2.2:8000 for Android emulator or localhost:8000
    // We'll construct a mock URL or just show the placeholder for safety.
    final String selfieUrl = hasSelfie ? 'http://localhost:8080${attendance.selfiePath}' : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // Light green tint
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Success Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Color(0xFF22C55E), // Green
                      size: 50,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Clock In Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You are checked in for the day.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 48),

              // Info Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Left Green Bar
                      Container(
                        width: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF22C55E)),
                                          const SizedBox(width: 8),
                                          Text(
                                            dateStr,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            checkInTime,
                                            style: const TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            ampm,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  // Selfie Image
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade100, width: 2),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: hasSelfie
                                          // Note: Because of local testing, Image.network might fail depending on emulator/web.
                                          // We use an icon as fallback if it fails.
                                          ? Image.network(
                                              selfieUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.grey),
                                            )
                                          : const Icon(Icons.person, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF22C55E)),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'PT Wowin - Factory 1', // Mock location based on coordinates could be added here
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF334155),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Shift: Pagi (07:30 - 16:30)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  Text(
                                    attendance.status == 'on_time' ? 'On Time' : 'Late',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: attendance.status == 'on_time' ? const Color(0xFF22C55E) : Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Back to Home Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E63B), // Bright green
                  foregroundColor: const Color(0xFF064E3B), // Dark green text
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
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
