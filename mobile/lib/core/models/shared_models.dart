import 'dart:convert';

class SubjectModel {
  final int? id;
  final String name;
  final String programmingLanguage;
  final String createdAt;
  final int docCount;
  final int topicCount;
  final double avgMasteryScore;

  SubjectModel({
    this.id,
    required this.name,
    required this.programmingLanguage,
    required this.createdAt,
    this.docCount = 0,
    this.topicCount = 0,
    this.avgMasteryScore = 0.0,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'programming_language': programmingLanguage,
        'created_at': createdAt,
      };

  factory SubjectModel.fromMap(Map<String, dynamic> map) => SubjectModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        programmingLanguage: map['programming_language'] as String,
        createdAt: map['created_at'] as String,
        docCount: (map['doc_count'] as num?)?.toInt() ?? 0,
        topicCount: (map['topic_count'] as num?)?.toInt() ?? 0,
        avgMasteryScore: (map['avg_score'] as num?)?.toDouble() ?? 0.0,
      );
}

class TopicModel {
  final int? id;
  final int subjectId;
  final int documentId;
  final String name;
  final List<String> keywords;
  final List<int> chunkIndices;
  final int masteryScore;
  final int quizCount;
  final String updatedAt;

  TopicModel({
    this.id,
    required this.subjectId,
    required this.documentId,
    required this.name,
    required this.keywords,
    required this.chunkIndices,
    this.masteryScore = 0,
    this.quizCount = 0,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'subject_id': subjectId,
        'document_id': documentId,
        'name': name,
        'keywords_json': jsonEncode(keywords),
        'chunk_indices_json': jsonEncode(chunkIndices),
        'mastery_score': masteryScore,
        'quiz_count': quizCount,
        'updated_at': updatedAt,
      };

  factory TopicModel.fromMap(Map<String, dynamic> map) => TopicModel(
        id: map['id'] as int?,
        subjectId: map['subject_id'] as int,
        documentId: map['document_id'] as int,
        name: map['name'] as String,
        keywords: List<String>.from(jsonDecode(map['keywords_json'] as String)),
        chunkIndices:
            List<int>.from(jsonDecode(map['chunk_indices_json'] as String)),
        masteryScore: (map['mastery_score'] as num?)?.toInt() ?? 0,
        quizCount: (map['quiz_count'] as num?)?.toInt() ?? 0,
        updatedAt: map['updated_at'] as String,
      );
}

class QuestionModel {
  final int? id;
  final int topicId;
  final String questionType; // 'CONCEPT' | 'PREDICT_OUTPUT' | 'SPOT_BUG'
  final String questionText;
  final String? codeSnippet;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuestionModel({
    this.id,
    required this.topicId,
    required this.questionType,
    required this.questionText,
    this.codeSnippet,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'topic_id': topicId,
        'question_type': questionType,
        'question_text': questionText,
        'code_snippet': codeSnippet,
        'options_json': jsonEncode(options),
        'correct_index': correctIndex,
        'explanation': explanation,
      };

  factory QuestionModel.fromMap(Map<String, dynamic> map) => QuestionModel(
        id: map['id'] as int?,
        topicId: map['topic_id'] as int,
        questionType: map['question_type'] as String,
        questionText: map['question_text'] as String,
        codeSnippet: map['code_snippet'] as String?,
        options: List<String>.from(jsonDecode(map['options_json'] as String)),
        correctIndex: map['correct_index'] as int,
        explanation: map['explanation'] as String,
      );
}