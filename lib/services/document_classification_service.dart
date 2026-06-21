import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors/app_exception.dart';
import '../data/models/document_classification.dart';

class DocumentClassificationService {
  DocumentClassificationService(this._client);

  final SupabaseClient _client;

  Future<DocumentClassification> classifyDocument(String documentText) async {
    if (documentText.trim().isEmpty) {
      throw DocumentClassificationException('Document text is empty.');
    }

    try {
      final response = await _client.functions.invoke(
        'classify-document',
        body: {'documentText': documentText},
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Document classification failed (${response.status}).';
        throw DocumentClassificationException(message);
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw DocumentClassificationException('Invalid classification response.');
      }

      return DocumentClassification.fromJson(data);
    } on DocumentClassificationException {
      rethrow;
    } on FunctionException catch (e) {
      throw DocumentClassificationException(
        e.details ?? 'Document classification service unavailable.',
        cause: e,
      );
    } catch (e) {
      throw DocumentClassificationException(
        'Failed to classify document.',
        cause: e,
      );
    }
  }
}
