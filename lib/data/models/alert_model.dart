import 'package:hive/hive.dart';

part 'alert_model.g.dart';

@HiveType(typeId: 1)
class AlertModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String headline;

  @HiveField(2)
  final String summary;

  @HiveField(3)
  final String? sourceUrl;

  @HiveField(4)
  final bool isTrending;

  @HiveField(5)
  final DateTime publishedAt;

  @HiveField(6)
  final String category; // digital_arrest, lottery, otp, investment, etc.

  @HiveField(7)
  final bool isNew;

  @HiveField(8)
  final String? imageUrl;

  AlertModel({
    required this.id,
    required this.headline,
    required this.summary,
    this.sourceUrl,
    required this.isTrending,
    required this.publishedAt,
    required this.category,
    required this.isNew,
    this.imageUrl,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      headline: json['headline'] ?? '',
      summary: json['summary'] ?? '',
      sourceUrl: json['source_url'],
      imageUrl: json['image_url'],
      isTrending: json['is_trending'] ?? false,
      publishedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
      category: json['category'] ?? 'general',
      isNew: json['is_new'] ?? false,
    );
  }

  static List<AlertModel> mockAlerts() => [
        AlertModel(
          id: 'alert_001',
          headline: 'Digital Arrest Scam बढ़ रहा है',
          summary:
              'CBI/ED/Police के नाम पर Video Call करके लोगों को डरा-धमका कर पैसे ऐंठे जा रहे हैं। ऐसी कोई भी Call आए तो फौरन 1930 पर Report करें।',
          isTrending: true,
          publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
          category: 'digital_arrest',
          isNew: true,
          imageUrl: 'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?auto=format&fit=crop&w=600&q=80',
        ),
        AlertModel(
          id: 'mock_1',
          headline: 'Massive WhatsApp OTP Scam Uncovered in Delhi',
          summary: 'Hackers are stealing WhatsApp accounts by tricking users into forwarding SMS OTPs. Never share your 6-digit codes.',
          isTrending: true,
          publishedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          category: 'otp',
          isNew: true,
          imageUrl: 'https://images.unsplash.com/photo-1614064641913-a520faff8424?auto=format&fit=crop&w=600&q=80',
        ),
        AlertModel(
          id: 'mock_2',
          headline: 'New "Digital Arrest" Scheme Targeting Seniors',
          summary: 'Fake police officers are video-calling victims, claiming they are under "digital arrest" for money laundering.',
          isTrending: true,
          publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
          category: 'digital_arrest',
          isNew: true,
          imageUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?auto=format&fit=crop&w=600&q=80',
        ),
      ];
}
