class AnalyticsKpiModel {
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final int strongTopicsCount; // mastery_score >= 80
  final int totalTopicsCount;
  final int totalFlashcardsCount;
  final int dueFlashcardsCount;

  const AnalyticsKpiModel({
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.strongTopicsCount,
    required this.totalTopicsCount,
    required this.totalFlashcardsCount,
    required this.dueFlashcardsCount,
  });

  double get accuracyPercentage {
    if (totalQuestionsAnswered <= 0) return 0.0;
    return (totalCorrectAnswers * 100.0) / totalQuestionsAnswered;
  }

  factory AnalyticsKpiModel.fromMap(Map<String, dynamic> map) {
    return AnalyticsKpiModel(
      totalQuestionsAnswered: (map['total_questions_answered'] as num?)?.toInt() ?? 0,
      totalCorrectAnswers: (map['total_correct_answers'] as num?)?.toInt() ?? 0,
      strongTopicsCount: (map['strong_topics_count'] as num?)?.toInt() ?? 0,
      totalTopicsCount: (map['total_topics_count'] as num?)?.toInt() ?? 0,
      totalFlashcardsCount: (map['total_flashcards_count'] as num?)?.toInt() ?? 0,
      dueFlashcardsCount: (map['due_flashcards_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TopicMasteryItem {
  final int topicId;
  final int subjectId;
  final String subjectName;
  final String programmingLanguage;
  final String topicName;
  final int masteryScore;
  final int quizCount;

  const TopicMasteryItem({
    required this.topicId,
    required this.subjectId,
    required this.subjectName,
    required this.programmingLanguage,
    required this.topicName,
    required this.masteryScore,
    required this.quizCount,
  });

  bool get isWeak => masteryScore < 50;
  bool get isStrong => masteryScore >= 80;

  factory TopicMasteryItem.fromMap(Map<String, dynamic> map) {
    return TopicMasteryItem(
      topicId: (map['topic_id'] as num).toInt(),
      subjectId: (map['subject_id'] as num).toInt(),
      subjectName: map['subject_name'] as String? ?? 'Chưa rõ môn',
      programmingLanguage: map['programming_language'] as String? ?? '',
      topicName: map['topic_name'] as String? ?? '',
      masteryScore: (map['mastery_score'] as num?)?.toInt() ?? 0,
      quizCount: (map['quiz_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class QuizAttemptHistoryItem {
  final int attemptId;
  final int subjectId;
  final String subjectName;
  final int score;
  final int totalQuestions;
  final int correctCount;
  final int durationSeconds;
  final String completedAt;

  const QuizAttemptHistoryItem({
    required this.attemptId,
    required this.subjectId,
    required this.subjectName,
    required this.score,
    required this.totalQuestions,
    required this.correctCount,
    required this.durationSeconds,
    required this.completedAt,
  });

  factory QuizAttemptHistoryItem.fromMap(Map<String, dynamic> map) {
    return QuizAttemptHistoryItem(
      attemptId: (map['attempt_id'] as num).toInt(),
      subjectId: (map['subject_id'] as num).toInt(),
      subjectName: map['subject_name'] as String? ?? 'Môn học đã xóa',
      score: (map['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (map['total_questions'] as num?)?.toInt() ?? 0,
      correctCount: (map['correct_count'] as num?)?.toInt() ?? 0,
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      completedAt: map['completed_at'] as String? ?? '',
    );
  }
}

class AnalyticsDashboardData {
  final AnalyticsKpiModel kpi;
  final List<TopicMasteryItem> topicMasteryList;
  final List<QuizAttemptHistoryItem> recentAttempts;

  const AnalyticsDashboardData({
    required this.kpi,
    required this.topicMasteryList,
    required this.recentAttempts,
  });
}