import 'dart:developer';

import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class ViewFileScreen extends StatefulWidget {
  final String pdfUrl;

  const ViewFileScreen({super.key, required this.pdfUrl});

  @override
  State<ViewFileScreen> createState() => _ViewFileScreenState();
}

class _ViewFileScreenState extends State<ViewFileScreen> {
  PDFDocument? doc;
  @override
  @override
  void initState() {
    super.initState();
    log(widget.pdfUrl);
    loadPDFDocument();
  }

  void loadPDFDocument() async {
    try {
      doc = await PDFDocument.fromURL(widget.pdfUrl);
      setState(() {});
    } catch (e) {
      log("pdf view page");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: doc != null
            ? PDFView(
                filePath: doc!.filePath.toString(),
              )
            : const Center(child: CircularProgressIndicator()));
  }
}
