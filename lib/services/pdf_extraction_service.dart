import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../core/errors/app_exception.dart';

class PdfExtractionService {
  Future<String> extractText(Uint8List bytes) async {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();

      if (text.trim().isEmpty) {
        throw PdfExtractionException(
          'This PDF has no selectable text; OCR is out of scope for Sprint 1.',
        );
      }

      return text;
    } on PdfExtractionException {
      rethrow;
    } catch (e) {
      throw PdfExtractionException(
        'Failed to read PDF. Please upload a valid lease PDF.',
        cause: e,
      );
    } finally {
      document?.dispose();
    }
  }
}
