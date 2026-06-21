import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/errors/app_exception.dart';
import '../data/models/document.dart';
import '../data/repositories/supabase_repository.dart';

class DocumentStorageService {
  DocumentStorageService(this._client, this._repository);

  final SupabaseClient _client;
  final SupabaseRepository _repository;

  static const bucketName = 'lease-documents';
  static const _uuid = Uuid();

  Future<({Document document, String storagePath})> uploadDocument({
    required String fileName,
    required List<int> bytes,
  }) async {
    final userId = _repository.currentUserId;
    final documentId = _uuid.v4();
    final storagePath = '$userId/$documentId/$fileName';

    try {
      await _client.storage.from(bucketName).uploadBinary(
            storagePath,
            bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
            fileOptions: const FileOptions(upsert: true),
          );

      final document = await _repository.createDocumentPlaceholder(
        fileName: fileName,
        storagePath: storagePath,
      );

      return (document: document, storagePath: storagePath);
    } catch (e) {
      throw AppStorageException('Failed to upload document.', cause: e);
    }
  }
}
