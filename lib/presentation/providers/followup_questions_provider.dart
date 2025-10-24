import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to store generated follow-up questions
final followUpQuestionsProvider = StateNotifierProvider<FollowUpQuestionsNotifier, List<String>>((ref) {
  return FollowUpQuestionsNotifier();
});

class FollowUpQuestionsNotifier extends StateNotifier<List<String>> {
  FollowUpQuestionsNotifier() : super([]);

  void setQuestions(List<String> questions) {
    state = questions;
  }

  void clearQuestions() {
    state = [];
  }

  void addQuestion(String question) {
    state = [...state, question];
  }
}
