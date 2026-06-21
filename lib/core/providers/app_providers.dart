import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../../data/models/action_item.dart';
import '../../data/models/document.dart';
import '../../data/models/property.dart';
import '../../data/repositories/supabase_repository.dart';
import '../../services/action_item_generator_service.dart';
import '../../services/document_classification_service.dart';
import '../../services/document_storage_service.dart';
import '../../services/lease_extraction_service.dart';
import '../../services/pdf_extraction_service.dart';
import '../../services/portfolio_metrics_service.dart';
import '../../services/property_matching_service.dart';
import '../../services/property_status_service.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden in main.dart');
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final supabaseRepositoryProvider = Provider<SupabaseRepository>((ref) {
  return SupabaseRepository(ref.watch(supabaseClientProvider));
});

final pdfExtractionServiceProvider = Provider<PdfExtractionService>((ref) {
  return PdfExtractionService();
});

final leaseExtractionServiceProvider = Provider<LeaseExtractionService>((ref) {
  return LeaseExtractionService(ref.watch(supabaseClientProvider));
});

final documentClassificationServiceProvider =
    Provider<DocumentClassificationService>((ref) {
  return DocumentClassificationService(ref.watch(supabaseClientProvider));
});

final documentStorageServiceProvider = Provider<DocumentStorageService>((ref) {
  return DocumentStorageService(
    ref.watch(supabaseClientProvider),
    ref.watch(supabaseRepositoryProvider),
  );
});

final propertyMatchingServiceProvider = Provider<PropertyMatchingService>((ref) {
  return PropertyMatchingService();
});

final actionItemGeneratorServiceProvider = Provider<ActionItemGeneratorService>((ref) {
  return ActionItemGeneratorService();
});

final propertyStatusServiceProvider = Provider<PropertyStatusService>((ref) {
  return PropertyStatusService();
});

final portfolioMetricsServiceProvider = Provider<PortfolioMetricsService>((ref) {
  return PortfolioMetricsService(ref.watch(propertyStatusServiceProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final portfolioProvider = FutureProvider<List<PortfolioEntry>>((ref) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  return repository.fetchPortfolio();
});

final propertyDetailProvider =
    FutureProvider.family<PropertyDetail, String>((ref, propertyId) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  return repository.fetchPropertyDetail(propertyId);
});

final attentionProvider = FutureProvider<List<ActionItem>>((ref) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  return repository.fetchOpenActionItems();
});

final documentDetailProvider = FutureProvider.family<DocumentDetail, DocumentDetailKey>(
  (ref, key) async {
    final repository = ref.watch(supabaseRepositoryProvider);
    final document = await repository.fetchDocumentById(key.documentId);
    final property = await repository.fetchPropertyById(key.propertyId);
    return DocumentDetail(property: property, document: document);
  },
);

class DocumentDetailKey {
  const DocumentDetailKey({required this.propertyId, required this.documentId});

  final String propertyId;
  final String documentId;

  @override
  bool operator ==(Object other) {
    return other is DocumentDetailKey &&
        other.propertyId == propertyId &&
        other.documentId == documentId;
  }

  @override
  int get hashCode => Object.hash(propertyId, documentId);
}

class DocumentDetail {
  const DocumentDetail({required this.property, required this.document});

  final Property property;
  final Document document;
}
