import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/document.dart';
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
    required String leaseId,
  }) async {
    try {
      final response = await _client
          .from('documents')
          .update({
            'property_id': propertyId,
            'lease_id': leaseId,
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
      entries.add(PortfolioEntry(property: property, leases: leases));
    }

    return entries;
  }
}

class PortfolioEntry {
  const PortfolioEntry({required this.property, required this.leases});

  final Property property;
  final List<Lease> leases;
}
