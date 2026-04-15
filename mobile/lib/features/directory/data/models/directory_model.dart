import 'package:equatable/equatable.dart';

class EmployeeDirectory extends Equatable {
  final String id;
  final String name;
  final String position;
  final String department;
  final String phoneNumber;
  final String? profileUrl;

  const EmployeeDirectory({
    required this.id,
    required this.name,
    required this.position,
    required this.department,
    required this.phoneNumber,
    this.profileUrl,
  });

  @override
  List<Object?> get props => [id, name, position, department, phoneNumber, profileUrl];

  factory EmployeeDirectory.fromJson(Map<String, dynamic> json) {
    return EmployeeDirectory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      department: json['department'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      profileUrl: json['profile_url'],
    );
  }
}
