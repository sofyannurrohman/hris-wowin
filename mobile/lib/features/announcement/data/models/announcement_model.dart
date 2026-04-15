import 'package:equatable/equatable.dart';

enum AnnouncementCategory { info, alert, birthday, policy }

class Announcement extends Equatable {
  final String id;
  final String title;
  final String content;
  final AnnouncementCategory category;
  final DateTime createdAt;
  final String? author;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.author,
  });

  @override
  List<Object?> get props => [id, title, content, category, createdAt, author];

  factory Announcement.fromJson(Map<String, dynamic> json) {
    AnnouncementCategory category = AnnouncementCategory.info;
    switch (json['category']?.toString().toLowerCase()) {
      case 'alert': category = AnnouncementCategory.alert; break;
      case 'birthday': category = AnnouncementCategory.birthday; break;
      case 'policy': category = AnnouncementCategory.policy; break;
    }

    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: category,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      author: json['author'],
    );
  }
}
