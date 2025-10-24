import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track which papers are selected for RAG operations
final selectedPapersProvider = StateNotifierProvider<SelectedPapersNotifier, Set<String>>((ref) {
  return SelectedPapersNotifier();
});

class SelectedPapersNotifier extends StateNotifier<Set<String>> {
  SelectedPapersNotifier() : super({});

  void togglePaper(String pmid) {
    if (state.contains(pmid)) {
      state = {...state}..remove(pmid);
    } else {
      state = {...state, pmid};
    }
  }

  void selectPaper(String pmid) {
    state = {...state, pmid};
  }

  void deselectPaper(String pmid) {
    state = {...state}..remove(pmid);
  }

  void selectAll(List<String> pmids) {
    state = {...pmids};
  }

  void clearSelection() {
    state = {};
  }

  bool isSelected(String pmid) {
    return state.contains(pmid);
  }
}
