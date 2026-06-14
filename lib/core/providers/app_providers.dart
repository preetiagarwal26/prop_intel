import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../../data/repositories/supabase_repository.dart';
import '../../services/document_storage_service.dart';
import '../../services/lease_extraction_service.dart';
import '../../services/pdf_extraction_service.dart';
import '../../services/property_matching_service.dart';

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

final documentStorageServiceProvider = Provider<DocumentStorageService>((ref) {
  return DocumentStorageService(
    ref.watch(supabaseClientProvider),
    ref.watch(supabaseRepositoryProvider),
  );
});

final propertyMatchingServiceProvider = Provider<PropertyMatchingService>((ref) {
  return PropertyMatchingService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final portfolioProvider = FutureProvider<List<PortfolioEntry>>((ref) async {
  final repository = ref.watch(supabaseRepositoryProvider);
  return repository.fetchPortfolio();
});
