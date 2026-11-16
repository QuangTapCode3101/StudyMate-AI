import '../../../core/models/shared_models.dart';

class WeakTopicItem {
  final TopicModel topic;
  final String subjectName;

  WeakTopicItem({required this.topic, required this.subjectName});
}

class DashboardSummaryData {
  final String? activeSubjectName;
  final TopicModel? continueTopic;
  final int dueFlashcardsCount;
  final List<WeakTopicItem> weakTopics;
  final int totalMasteredCards;
  final int totalTopicsCount;

  DashboardSummaryData({
    this.activeSubjectName,
    this.continueTopic,
    required this.dueFlashcardsCount,
    required this.weakTopics,
    required this.totalMasteredCards,
    required this.totalTopicsCount,
  });

  bool get isEmpty => totalTopicsCount == 0;
}