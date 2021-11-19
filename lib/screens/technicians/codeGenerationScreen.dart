import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfLib;
import 'package:printing/printing.dart';

class CodeGenerationScreen extends StatefulWidget {
  CodeGenerationScreen({Key key}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<CodeGenerationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNumberTextController = TextEditingController();
  final _lastNumberTextController = TextEditingController();

  void _generateBarcodes() async {
    if(_formKey.currentState.validate()) {
      int firstNumber = int.parse(_firstNumberTextController.text);
      int lastNumber = int.parse(_lastNumberTextController.text);

      final font = await rootBundle.load("OpenSans-Regular.ttf");
      final ttf = pdfLib.Font.ttf(font);
      final fontBold = await rootBundle.load("OpenSans-Bold.ttf");
      final ttfBold = pdfLib.Font.ttf(fontBold);
      final fontItalic = await rootBundle.load("OpenSans-Italic.ttf");
      final ttfItalic = pdfLib.Font.ttf(fontItalic);
      final fontBoldItalic = await rootBundle.load("OpenSans-BoldItalic.ttf");
      final ttfBoldItalic = pdfLib.Font.ttf(fontBoldItalic);
      final pdfLib.ThemeData themeData = pdfLib.ThemeData.withFont(
        base: ttf,
        bold: ttfBold,
        italic: ttfItalic,
        boldItalic: ttfBoldItalic,
      );

      final pdf = pdfLib.Document();

      pdf.addPage(
        pdfLib.Page(
          theme: themeData,//TODO: vs pageTheme?
          pageFormat: PdfPageFormat.a4,
          build: (pdfLib.Context context) {
            return pdfLib.Center(
              child: pdfLib.BarcodeWidget(
                barcode: pdfLib.Barcode.qrCode(),
                data: firstNumber.toString()
              ),
            ); // Center
          }
        )
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'barcodes.pdf');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SizedBox(width: 400, height: 600,
          child: Form(key: _formKey,
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Generate a printable document', style: Theme
                  .of(context)
                  .textTheme
                  .headline5),
                SizedBox(height: 20),
                TextFormField(
                  controller: _firstNumberTextController,
                  decoration: InputDecoration(hintText: 'First number'),
                  validator: (value) {
                    if (value.isEmpty || int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) => _generateBarcodes(),
                ),
                TextFormField(
                  controller: _lastNumberTextController,
                  decoration: InputDecoration(hintText: 'Last number'),
                  validator: (value) {
                    if (value.isEmpty || int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onFieldSubmitted: (value) => _generateBarcodes(),
                ),
                SizedBox(height: 5),
                ElevatedButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                      return states.contains(MaterialState.disabled) ? null : Colors.white;
                    }),
                    backgroundColor: MaterialStateColor.resolveWith((Set<MaterialState> states) {
                      return states.contains(MaterialState.disabled) ? null : Color(0xff667d9d);
                    }),
                  ),
                  onPressed: () => _generateBarcodes(),
                  child: Text('Generate'),
                )
              ]
            )
          )
        ),
      )
    );
  }
}