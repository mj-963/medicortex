import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domains/pubmed/pubmed_fulltext_service.dart';

/// Provider for PubMed full text service
final fullTextServiceProvider = Provider<PubMedFullTextService>((ref) {
  return PubMedFullTextService();
});
