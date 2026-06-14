import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors/app_exception.dart';
import '../data/models/lease_extraction.dart';

class LeaseExtractionService {
  LeaseExtractionService(this._client);

  final SupabaseClient _client;

  Future<LeaseExtraction> extractLeaseData(String leaseText) async {
    if (leaseText.trim().isEmpty) {
      throw LeaseExtractionException('Lease text is empty.');
    }

    try {
      final response = await _client.functions.invoke(
        'extract-lease',
        body: {'leaseText': leaseText},
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Lease extraction failed (${response.status}).';
        throw LeaseExtractionException(message);
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw LeaseExtractionException('Invalid extraction response.');
      }

      return LeaseExtraction.fromJson(data);
    } on LeaseExtractionException {
      rethrow;
    } on FunctionException catch (e) {
      throw LeaseExtractionException(
        e.details ?? 'Lease extraction service unavailable.',
        cause: e,
      );
    } catch (e) {
      throw LeaseExtractionException(
        'Failed to extract lease data.',
        cause: e,
      );
    }
  }
}
