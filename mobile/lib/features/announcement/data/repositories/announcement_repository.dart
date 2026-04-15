import 'package:dartz/dartz.dart';
import 'package:hris_app/core/error/failures.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/features/announcement/data/models/announcement_model.dart';

abstract class AnnouncementRepository {
  Future<Either<Failure, List<Announcement>>> getAnnouncements();
}

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final ApiClient apiClient;

  AnnouncementRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, List<Announcement>>> getAnnouncements() async {
    try {
      final response = await apiClient.client.get('announcements');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return Right(data.map((e) => Announcement.fromJson(e)).toList());
      }
      return const Left(ServerFailure('Gagal mengambil pengumuman.'));
    } catch (e) {
      // Mock data for initial implementation
      return Right([
        Announcement(
          id: '1',
          title: 'Kebijakan Libur Lebaran 2026',
          content: 'Manajemen mengumumkan libur bersama akan dimulai pada tanggal 20 April 2026.',
          category: AnnouncementCategory.policy,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          author: 'HRD',
        ),
        Announcement(
          id: '2',
          title: 'Selamat Ulang Tahun Budi!',
          content: 'Mari sampaikan harapan terbaik untuk Budi dari tim IT.',
          category: AnnouncementCategory.birthday,
          createdAt: DateTime.now(),
          author: 'Management',
        ),
      ]);
    }
  }
}
