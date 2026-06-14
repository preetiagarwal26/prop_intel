import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/lease.dart';
import '../../data/models/lease_upload_draft.dart';
import '../../data/models/property.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.draft});

  final LeaseUploadDraft draft;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late LeaseUploadDraft _draft;
  bool _isSaving = false;
  String? _error;

  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;
  late final TextEditingController _unitController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _rentController;
  late final TextEditingController _depositController;
  late final TextEditingController _lateFeeController;
  late final TextEditingController _tenantsController;
  late final TextEditingController _landlordController;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _addressController = TextEditingController(text: _draft.propertyAddress);
    _cityController = TextEditingController(text: _draft.city);
    _stateController = TextEditingController(text: _draft.state);
    _zipController = TextEditingController(text: _draft.zipCode);
    _unitController = TextEditingController(text: _draft.unitNumber);
    _startDateController = TextEditingController(text: _draft.leaseStartDate);
    _endDateController = TextEditingController(text: _draft.leaseEndDate);
    _rentController = TextEditingController(text: _draft.monthlyRent);
    _depositController = TextEditingController(text: _draft.securityDeposit);
    _lateFeeController = TextEditingController(text: _draft.lateFee);
    _tenantsController = TextEditingController(text: _draft.tenantNames.join(', '));
    _landlordController = TextEditingController(text: _draft.landlordName);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _unitController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _lateFeeController.dispose();
    _tenantsController.dispose();
    _landlordController.dispose();
    super.dispose();
  }

  void _syncDraftFromControllers() {
    _draft.propertyAddress = _addressController.text.trim();
    _draft.city = _cityController.text.trim();
    _draft.state = _stateController.text.trim();
    _draft.zipCode = _zipController.text.trim();
    _draft.unitNumber = _unitController.text.trim();
    _draft.leaseStartDate = _startDateController.text.trim();
    _draft.leaseEndDate = _endDateController.text.trim();
    _draft.monthlyRent = _rentController.text.trim();
    _draft.securityDeposit = _depositController.text.trim();
    _draft.lateFee = _lateFeeController.text.trim();
    _draft.tenantNames = _tenantsController.text
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    _draft.landlordName = _landlordController.text.trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _syncDraftFromControllers();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final repository = ref.read(supabaseRepositoryProvider);
    final extraction = _draft.toExtraction();

    try {
      final Property property;
      if (_draft.createNewProperty || _draft.matchedProperty == null) {
        property = await repository.createProperty(
          Property(
            id: '',
            userId: repository.currentUserId,
            propertyAddress: _draft.propertyAddress,
            city: _draft.city,
            state: _draft.state,
            zipCode: _draft.zipCode,
            unitNumber: _draft.unitNumber.isEmpty ? null : _draft.unitNumber,
          ),
        );
      } else {
        property = await repository.updateProperty(
          _draft.matchedProperty!.copyWith(
            propertyAddress: _draft.propertyAddress,
            city: _draft.city,
            state: _draft.state,
            zipCode: _draft.zipCode,
            unitNumber: _draft.unitNumber.isEmpty ? null : _draft.unitNumber,
          ),
        );
      }

      final lease = await repository.createLease(
        Lease(
          id: '',
          propertyId: property.id,
          leaseStartDate: extraction.leaseStartDateValue,
          leaseEndDate: extraction.leaseEndDateValue,
          monthlyRent: extraction.monthlyRentValue,
          securityDeposit: extraction.securityDepositValue,
          lateFee: extraction.lateFeeValue,
          tenantNames: _draft.tenantNames,
          landlordName: _draft.landlordName.isEmpty ? null : _draft.landlordName,
          rawExtractionJson: extraction.toJson(),
        ),
      );

      await repository.updateDocument(
        documentId: _draft.documentId,
        propertyId: property.id,
        leaseId: lease.id,
      );

      ref.invalidate(portfolioProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lease saved successfully.')),
        );
        context.go('/portfolio');
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Failed to save lease. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    final matchLabel = _draft.createNewProperty
        ? 'New property'
        : 'Existing property (${( _draft.matchResult.confidence * 100).toStringAsFixed(0)}% match)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Confirm'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSaving ? null : () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Chip(
              avatar: Icon(
                _draft.createNewProperty ? Icons.add_home : Icons.home,
              ),
              label: Text(matchLabel),
            ),
            const SizedBox(height: 16),
            Text('Property Info', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _field(_addressController, 'Property address', required: true),
            _field(_cityController, 'City', required: true),
            _field(_stateController, 'State', required: true),
            _field(_zipController, 'ZIP code', required: true),
            _field(_unitController, 'Unit number'),
            SwitchListTile(
              title: const Text('Create as new property'),
              subtitle: const Text('Turn off to update the matched property instead'),
              value: _draft.createNewProperty,
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _draft.createNewProperty = value),
            ),
            const SizedBox(height: 24),
            Text('Lease Info', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _field(_startDateController, 'Lease start date (YYYY-MM-DD)'),
            _field(_endDateController, 'Lease end date (YYYY-MM-DD)'),
            _field(_rentController, 'Monthly rent'),
            _field(_depositController, 'Security deposit'),
            _field(_lateFeeController, 'Late fee'),
            _field(_tenantsController, 'Tenant names (comma-separated)'),
            _field(_landlordController, 'Landlord name'),
            const SizedBox(height: 8),
            Text('File: ${_draft.fileName}'),
            if (_draft.monthlyRent.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Parsed rent preview: ${currency.format(_draft.toExtraction().monthlyRentValue ?? 0)}'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Lease'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }
}
