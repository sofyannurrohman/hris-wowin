import 'package:dartz/dartz.dart';
import 'package:hris_app/core/error/failures.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/features/directory/data/models/directory_model.dart';

abstract class DirectoryRepository {
  Future<Either<Failure, List<EmployeeDirectory>>> getDirectory({String? query});
}

class DirectoryRepositoryImpl implements DirectoryRepository {
  final ApiClient apiClient;

  DirectoryRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, List<EmployeeDirectory>>> getDirectory({String? query}) async {
    try {
      final response = await apiClient.client.get('employees/directory', queryParameters: {'q': query});
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return Right(data.map((e) => EmployeeDirectory.fromJson(e)).toList());
      }
      return const Left(ServerFailure('Gagal memuat direktori.'));
    } catch (e) {
      // Mock data for initial rollout
      return Right([
        const EmployeeDirectory(
          id: '1',
          name: 'Sofyan Nurrohman',
          position: 'Fullstack Dev',
          department: 'IT',
          phoneNumber: '08123456789',
        ),
        const EmployeeDirectory(
          id: '2',
          name: 'Andi Kusuma',
          position: 'Manager',
          department: 'Sales',
          phoneNumber: '08198765432',
        ),
        const EmployeeDirectory(
          id: '3',
          name: 'Siti Aminah',
          position: 'Staff Finance',
          department: 'Finance',
          phoneNumber: '08112233445',
        ),
      ]);
    }
  }
}
