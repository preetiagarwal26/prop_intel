import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../services/document_storage_service.dart';
import '../models/document.dart';
import '../models/document_type.dart';
import '../models/lease.dart';
import '../models/property.dart';

class SupabaseRepository {
  SupabaseRepository(this._client);

  final SupabaseClient _client;

  String get currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw RepositoryException('User is not authenticated.');
    }
    return user.id;
  }

  Future<List<Property>> fetchProperties() async {
    try {
      final response = await _client
          .from('properties')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => Property.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to load properties.', cause: e);
    }
  }

  Future<Property> fetchPropertyById(String propertyId) async {
    try {
      final response = await _client
          .from('properties')
          .select()
          .eq('id', propertyId)
          .single();

      return Property.fromJson(response);
    } catch (e) {
      throw RepositoryException('Failed to load property.', cause: e);
    }
  }

  Future<List<Lease>> fetchLeasesForProperty(String propertyId) async {
    try {
      final response = await _client
          .from('leases')
          .select()
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => Lease.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to load leases.', cause: e);
    }
  }

  Future<List<Document>> fetchDocumentsForProperty(String propertyId) async {
    try {
      final response = await _client
          .from('documents')
          .select()
          .eq('property_id', propertyId)
          .order('uploaded_at', ascending: false);

      return (response as List)
          .map((row) => Document.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to load documents.', cause: e);
    }
  }

  Future<PropertyDetail> fetchPropertyDetail(String propertyId) async {
    final property = await fetchPropertyById(propertyId);
    final leases = await fetchLeasesForProperty(propertyId);
    final documents = await fetchDocumentsForProperty(propertyId);
    return PropertyDetail(
      property: property,
      leases: leases,
      documents: documents,
    );
  }

  Future<String> getDocumentSignedUrl(String storagePath) async {
    try {
      final response = await _client.storage
          .from(DocumentStorageService.bucketName)
          .createSignedUrl(storagePath, 3600);
      return response;
    } catch (e) {
      throw RepositoryException('Failed to open document.', cause: e);
    }
  }

  Future<Property> createProperty(Property property) async {
    try {
      final response = await _client
          .from('properties')
          .insert({
            ...property.toInsertJson(),
            'user_id': currentUserId,
          })
          .select()
          .single();

      return Property.fromJson(response);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message.isNotEmpty ? e.message : 'Failed to create property.',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException('Failed to create property.', cause: e);
    }
  }

  Future<Property> updateProperty(Property property) async {
    try {
      final response = await _client
          .from('properties')
          .update(property.toUpdateJson())
          .eq('id', property.id)
          .select()
          .single();

      return Property.fromJson(response);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message.isNotEmpty ? e.message : 'Failed to update property.',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException('Failed to update property.', cause: e);
    }
  }

  Future<Lease> createLease(Lease lease) async {
    try {
      final response = await _client
          .from('leases')
          .insert(lease.toInsertJson())
          .select()
          .single();

      return Lease.fromJson(response);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message.isNotEmpty ? e.message : 'Failed to create lease.',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException('Failed to create lease.', cause: e);
    }
  }

  Future<Document> createDocumentPlaceholder({
    required String fileName,
    required String storagePath,
  }) async {
    try {
      final response = await _client
          .from('documents')
          .insert({
            'user_id': currentUserId,
            'file_name': fileName,
            'storage_path': storagePath,
          })
          .select()
          .single();

      return Document.fromJson(response);
    } catch (e) {
      throw RepositoryException('Failed to create document record.', cause: e);
    }
  }

  Future<Document> updateDocument({
    required String documentId,
    required String propertyId,
    String? leaseId,
    required DocumentType documentType,
    required double classificationConfidence,
    required Map<String, dynamic> extractedMetadata,
  }) async {
    try {
      final response = await _client
          .from('documents')
          .update({
            'property_id': propertyId,
            'lease_id': leaseId,
            'document_type': documentType.value,
            'classification_confidence': classificationConfidence,
            'extracted_metadata': extractedMetadata,
          })
          .eq('id', documentId)
          .select()
          .single();

      return Document.fromJson(response);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message.isNotEmpty ? e.message : 'Failed to update document.',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException('Failed to update document.', cause: e);
    }
  }

  Future<List<PortfolioEntry>> fetchPortfolio() async {
    final properties = await fetchProperties();
    final entries = <PortfolioEntry>[];

    for (final property in properties) {
      final leases = await fetchLeasesForProperty(property.id);
      final documents = await fetchDocumentsForProperty(property.id);
      entries.add(PortfolioEntry(
        property: property,
        leases: leases,
        documents: documents,
      ));
    }

    return entries;
  }
}

class PropertyDetail {
  const PropertyDetail({
    required this.property,
    required this.leases,
    required this.documents,
  });

  final Property property;
  final List<Lease> leases;
  final List<Document> documents;
}

class PortfolioEntry {
  const PortfolioEntry({
    required this.property,
    required this.leases,
    required this.documents,
  });

  final Property property;
  final List<Lease> leases;
  final List<Document> documents;
}
