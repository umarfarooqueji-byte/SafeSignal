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

  AlertModel({
    required this.id,
    required this.headline,
    required this.summary,
    this.sourceUrl,
    required this.isTrending,
    required this.publishedAt,
    required this.category,
    required this.isNew,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      headline: json['headline'] ?? '',
      summary: json['summary'] ?? '',
      sourceUrl: json['source_url'],
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
        ),
        AlertModel(
          id: 'alert_002',
          headline: 'Fake Investment App Alert',
          summary:
              'A new investment app promising 300% returns in 30 days is being circulated on WhatsApp. Do not invest.',
          isTrending: false,
          publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
          category: 'investment',
          isNew: true,
        ),
        AlertModel(
          id: 'alert_003',
          headline: 'OTP Fraud: नई Technique',
          summary:
              'Scammers अब आपके Bank का Customer Care बनकर OTP मांग रहे हैं। Bank कभी OTP नहीं मांगता।',
          isTrending: false,
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
          category: 'otp',
          isNew: false,
        ),
      ];
}
