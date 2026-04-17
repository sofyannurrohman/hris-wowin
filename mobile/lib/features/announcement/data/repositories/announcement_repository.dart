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
      return Left(ServerFailure(e.toString()));
    }
  }
}
