import 'package:hive/hive.dart';

part 'check_history_model.g.dart';

@HiveType(typeId: 2)
class CheckHistoryModel extends HiveObject {
  @HiveField(0)
  final String checkId;

  @HiveField(1)
  final String inputText;

  @HiveField(2)
  final String verdict;

  @HiveField(3)
  final double confidence;

  @HiveField(4)
  final String scamType;

  @HiveField(5)
  final DateTime checkedAt;

  @HiveField(6)
  final bool hasImage;

  CheckHistoryModel({
    required this.checkId,
    required this.inputText,
    required this.verdict,
    required this.confidence,
    required this.scamType,
    required this.checkedAt,
    required this.hasImage,
  });

  factory CheckHistoryModel.fromVerdict({
    required String checkId,
    required String inputText,
    required String verdict,
    required double confidence,
    required String scamType,
    bool hasImage = false,
  }) {
    return CheckHistoryModel(
      checkId: checkId,
      inputText: inputText,
      verdict: verdict,
      confidence: confidence,
      scamType: scamType,
      checkedAt: DateTime.now(),
      hasImage: hasImage,
    );
  }
}
