import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../services/document_storage_service.dart';
import '../models/action_item.dart';
import '../models/document.dart';
import '../models/document_flag.dart';
import '../models/document_type.dart';
import '../models/lease.dart';
import '../models/occupancy_status.dart';
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
    final actionItems = await fetchOpenActionItemsForProperty(propertyId);
    return PropertyDetail(
      property: property,
      leases: leases,
      documents: documents,
      actionItems: actionItems,
    );
  }

  Future<List<ActionItem>> fetchOpenActionItems() async {
    try {
      final response = await _client
          .from('action_items')
          .select()
          .eq('status', ActionItemStatus.open.value)
          .order('due_date', ascending: true);

      final items = (response as List)
          .map((row) => ActionItem.fromJson(row as Map<String, dynamic>))
          .toList();
      return _sortActionItems(items);
    } catch (e) {
      throw RepositoryException('Failed to load action items.', cause: e);
    }
  }

  Future<List<ActionItem>> fetchOpenActionItemsForProperty(String propertyId) async {
    try {
      final response = await _client
          .from('action_items')
          .select()
          .eq('property_id', propertyId)
          .eq('status', ActionItemStatus.open.value)
          .order('due_date', ascending: true);

      final items = (response as List)
          .map((row) => ActionItem.fromJson(row as Map<String, dynamic>))
          .toList();
      return _sortActionItems(items);
    } catch (e) {
      throw RepositoryException('Failed to load property action items.', cause: e);
    }
  }

  Future<void> replaceActionItemsForDocument({
    required String documentId,
    required List<ActionItemDraft> drafts,
  }) async {
    try {
      await _client
          .from('action_items')
          .delete()
          .eq('document_id', documentId)
          .eq('status', ActionItemStatus.open.value);

      if (drafts.isEmpty) {
        return;
      }

      await _client.from('action_items').insert(
            drafts
                .map(
                  (draft) => {
                    'user_id': currentUserId,
                    'property_id': draft.propertyId,
                    'document_id': draft.documentId,
                    'item_type': draft.itemType,
                    'title': draft.title,
                    'description': draft.description,
                    'due_date': draft.dueDate?.toIso8601String().split('T').first,
                    'severity': draft.severity.value,
                    'status': ActionItemStatus.open.value,
                    'source_key': draft.sourceKey,
                  },
                )
                .toList(),
          );
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message.isNotEmpty ? e.message : 'Failed to save action items.',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException('Failed to save action items.', cause: e);
    }
  }

  Future<ActionItem> updateActionItemStatus({
    required String actionItemId,
    required ActionItemStatus status,
  }) async {
    try {
      final response = await _client
          .from('action_items')
          .update({
            'status': status.value,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', actionItemId)
          .select()
          .single();

      return ActionItem.fromJson(response);
    } catch (e) {
      throw RepositoryException('Failed to update action item.', cause: e);
    }
  }

  List<ActionItem> _sortActionItems(List<ActionItem> items) {
    final sorted = List<ActionItem>.from(items);
    sorted.sort((a, b) {
      final severityCompare =
          a.severity.sortOrder.compareTo(b.severity.sortOrder);
      if (severityCompare != 0) {
        return severityCompare;
      }
      if (a.dueDate == null && b.dueDate == null) {
        return 0;
      }
      if (a.dueDate == null) {
        return 1;
      }
      if (b.dueDate == null) {
        return -1;
      }
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return sorted;
  }

  Future<Document> fetchDocumentById(String documentId) async {
    try {
      final response = await _client
          .from('documents')
          .select()
          .eq('id', documentId)
          .single();

      return Document.fromJson(response);
    } catch (e) {
      throw RepositoryException('Failed to load document.', cause: e);
    }
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

  Future<Property> updatePropertyOccupancy({
    required String propertyId,
    OccupancyStatus? occupancyStatus,
  }) async {
    try {
      final response = await _client
          .from('properties')
          .update({
            'occupancy_status': occupancyStatus?.value,
          })
          .eq('id', propertyId)
          .select()
          .single();

      return Property.fromJson(response);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message.isNotEmpty ? e.message : 'Failed to update occupancy.',
        cause: e,
      );
    } catch (e) {
      throw RepositoryException('Failed to update occupancy.', cause: e);
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
    String? summary,
    List<String> keyPoints = const [],
    List<DocumentFlag> flags = const [],
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
            'summary': summary,
            'key_points': keyPoints,
            'flags': flags.map((f) => f.toJson()).toList(),
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
    required this.actionItems,
  });

  final Property property;
  final List<Lease> leases;
  final List<Document> documents;
  final List<ActionItem> actionItems;
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
