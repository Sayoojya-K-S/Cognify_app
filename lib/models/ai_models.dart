class SimplifyResponse {
  final String summary;
  final String simplifiedText;
  final List<String> bulletNotes;

  SimplifyResponse({
    required this.summary,
    required this.simplifiedText,
    required this.bulletNotes,
  });

  factory SimplifyResponse.fromJson(Map<String, dynamic> json) {
    return SimplifyResponse(
      summary: json['summary'] as String? ?? '',
      simplifiedText: json['simplified_text'] as String? ?? '',
      bulletNotes: (json['bullet_notes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      correctAnswerIndex: json['correct_answer_index'] as int? ?? 0,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class QuizResponse {
  final List<QuizQuestion> quizQuestions;

  QuizResponse({required this.quizQuestions});

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      quizQuestions: (json['quiz_questions'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
