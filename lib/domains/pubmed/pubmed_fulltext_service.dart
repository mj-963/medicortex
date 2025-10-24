import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to fetch full text from PubMed Central (PMC)
class PubMedFullTextService {
  static const String _pmcApiBase = 'https://www.ncbi.nlm.nih.gov/research/bionlp/RESTful/pmcoa.cgi';

  /// Fetch full text for a given PMID
  /// Returns the full text if available, or null if not available in PMC
  Future<FullTextResult?> fetchFullText(String pmid) async {
    try {
      debugPrint('🔍 Fetching full text for PMID: $pmid');
      
      // First, check if the article is available in PMC
      final pmcId = await _getPmcId(pmid);
      
      if (pmcId == null) {
        debugPrint('⚠️  Article not available in PMC Open Access');
        return null;
      }
      
      debugPrint('✅ Found PMC ID: $pmcId');
      
      // Fetch the full text from PMC
      final fullText = await _fetchFromPmc(pmcId);
      
      if (fullText != null) {
        debugPrint('✅ Successfully fetched full text (${fullText.length} chars)');
        return FullTextResult(
          pmid: pmid,
          pmcId: pmcId,
          fullText: fullText,
          source: 'PMC',
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching full text: $e');
      return null;
    }
  }

  /// Get PMC ID from PMID using E-utilities
  Future<String?> _getPmcId(String pmid) async {
    try {
      final url = Uri.parse(
        'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?'
        'dbfrom=pubmed&db=pmc&id=$pmid&retmode=json',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final linksets = data['linksets'] as List?;
        
        if (linksets != null && linksets.isNotEmpty) {
          final linkset = linksets[0] as Map<String, dynamic>;
          final linksetdbs = linkset['linksetdbs'] as List?;
          
          if (linksetdbs != null && linksetdbs.isNotEmpty) {
            final links = linksetdbs[0] as Map<String, dynamic>;
            final pmcIds = links['links'] as List?;
            
            if (pmcIds != null && pmcIds.isNotEmpty) {
              return pmcIds[0].toString();
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting PMC ID: $e');
      return null;
    }
  }

  /// Fetch full text from PMC using PMC ID
  Future<String?> _fetchFromPmc(String pmcId) async {
    try {
      // Use PMC OA service to get full text
      final url = Uri.parse(
        '$_pmcApiBase/BioC_json/PMC$pmcId/unicode',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract text from BioC format
        final documents = data['documents'] as List?;
        if (documents != null && documents.isNotEmpty) {
          final doc = documents[0] as Map<String, dynamic>;
          final passages = doc['passages'] as List?;
          
          if (passages != null) {
            final textParts = <String>[];
            
            for (final passage in passages) {
              final passageMap = passage as Map<String, dynamic>;
              final text = passageMap['text'] as String?;
              final infons = passageMap['infons'] as Map<String, dynamic>?;
              final sectionType = infons?['section_type'] as String?;
              
              if (text != null && text.isNotEmpty) {
                // Add section header if available
                if (sectionType != null) {
                  textParts.add('\n## ${_formatSectionType(sectionType)}\n');
                }
                textParts.add(text);
              }
            }
            
            return textParts.join('\n\n');
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching from PMC: $e');
      return null;
    }
  }

  /// Format section type for display
  String _formatSectionType(String sectionType) {
    switch (sectionType.toLowerCase()) {
      case 'title':
        return 'Title';
      case 'abstract':
        return 'Abstract';
      case 'intro':
        return 'Introduction';
      case 'methods':
        return 'Methods';
      case 'results':
        return 'Results';
      case 'discuss':
        return 'Discussion';
      case 'concl':
        return 'Conclusion';
      case 'ack':
        return 'Acknowledgments';
      case 'ref':
        return 'References';
      default:
        return sectionType;
    }
  }
}

/// Result of full text fetch
class FullTextResult {
  final String pmid;
  final String pmcId;
  final String fullText;
  final String source;

  FullTextResult({
    required this.pmid,
    required this.pmcId,
    required this.fullText,
    required this.source,
  });

  /// Get a summary of the full text (first 500 chars)
  String get summary {
    if (fullText.length <= 500) return fullText;
    return '${fullText.substring(0, 500)}...';
  }

  /// Get word count
  int get wordCount => fullText.split(RegExp(r'\s+')).length;
}
