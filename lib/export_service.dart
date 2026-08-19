import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Import de tus modelos (GastoFijo y Transaccion)
import 'dashboard_survival.dart';

class ExportService {
  // ==========================================
  // 1. MÓDULO IRON: IMPRIMIR / EXPORTAR HÁBITOS (PDF)
  // ==========================================
  static Future<void> exportarHabitosIron({
    required String mesAno,
    required List<String> habitos,
    String tipoFrecuencia = 'Mensual',
  }) async {
    try {
      final pdf = pw.Document();

      List<String> headers = [];
      if (tipoFrecuencia == 'Diario') {
        headers = [
          'HÁBITO / RUTINA',
          'HORA',
          'ESTADO DIARIO',
          'NOTAS / OBSERVACIONES'
        ];
      } else if (tipoFrecuencia == 'Semanal') {
        headers = [
          'HÁBITO / RUTINA',
          'LUN',
          'MAR',
          'MIÉ',
          'JUE',
          'VIE',
          'SÁB',
          'DOM',
          'META'
        ];
      } else {
        headers = ['HÁBITO / RUTINA', ...List.generate(31, (i) => '${i + 1}')];
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'LifeFlow 360 - Módulo Iron',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Plantilla ${tipoFrecuencia.toUpperCase()} de Control y Seguimiento de Hábitos',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'MES / AÑO: $mesAno',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // Tabla de Hábitos según frecuencia
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 8,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey800,
                  ),
                  cellHeight: 25,
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  data: habitos.map((habito) {
                    if (tipoFrecuencia == 'Diario') {
                      return [habito, "08:00 AM", "[   ] Completado", ""];
                    } else if (tipoFrecuencia == 'Semanal') {
                      return [habito, "", "", "", "", "", "", "", "___ / 7"];
                    } else {
                      return [habito, ...List.filled(31, "")];
                    }
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );

      // Abre directamente la interfaz nativa para imprimir o guardar como PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Plantilla_${tipoFrecuencia}_Iron_$mesAno.pdf',
      );
    } catch (e) {
      print("❌ Error al exportar PDF de Iron: $e");
    }
  }

  // ==========================================
  // 2. MÓDULO SURVIVAL: GENERAR Y COMPARTIR PDF
  // ==========================================
  static Future<void> exportarPDF({
    required double ingresos,
    required double totalFijos,
    required double ahorroRecomendado,
    required double disponibleGastos,
    required double limiteDiario,
    required List<GastoFijo> gastosFijos,
    required List<Transaccion> transacciones,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Encabezado
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Reporte Financiero - Survival Finances',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Tabla Resumen
              pw.Text(
                'RESUMEN DE PRESUPUESTO',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Indicador', 'Monto (\$)'],
                data: [
                  [
                    'Sueldo / Ingreso Mensual',
                    '\$${ingresos.toStringAsFixed(0)}',
                  ],
                  ['Total Gastos Fijos', '\$${totalFijos.toStringAsFixed(0)}'],
                  [
                    'Ahorro Mensual Recomendado',
                    '\$${ahorroRecomendado.toStringAsFixed(0)}',
                  ],
                  [
                    'Disponible para Gastos Libre',
                    '\$${disponibleGastos.toStringAsFixed(0)}',
                  ],
                  [
                    'Límite Diario Recomendado',
                    '\$${limiteDiario.toStringAsFixed(0)}',
                  ],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                cellHeight: 22,
              ),
              pw.SizedBox(height: 15),

              // Tabla Gastos Fijos
              pw.Text(
                'DETALLE DE GASTOS FIJOS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              gastosFijos.isEmpty
                  ? pw.Text('No hay gastos fijos registrados.')
                  : pw.Table.fromTextArray(
                      headers: ['Concepto', 'Monto (\$)'],
                      data: gastosFijos
                          .map(
                            (f) => [
                              f.concepto,
                              '\$${f.monto.toStringAsFixed(0)}',
                            ],
                          )
                          .toList(),
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.red800,
                      ),
                      cellHeight: 20,
                    ),
              pw.SizedBox(height: 15),

              // Tabla Gastos Diarios
              pw.Text(
                'HISTORIAL DE MOVIMIENTOS DIARIOS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              transacciones.isEmpty
                  ? pw.Text('No hay movimientos registrados hoy.')
                  : pw.Table.fromTextArray(
                      headers: ['Fecha', 'Categoría', 'Concepto', 'Monto (\$)'],
                      data: transacciones
                          .map(
                            (t) => [
                              '${t.fecha.day}/${t.fecha.month}/${t.fecha.year}',
                              t.categoria,
                              t.concepto,
                              '-\$${t.monto.toStringAsFixed(0)}',
                            ],
                          )
                          .toList(),
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.teal800,
                      ),
                      cellHeight: 20,
                    ),
            ];
          },
        ),
      );

      // Abrir diálogo de compartir PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Reporte_Survival_Finances.pdf',
      );
    } catch (e) {
      print("❌ Error al exportar PDF: $e");
    }
  }

  // ==========================================
  // 3. MÓDULO SURVIVAL: GENERAR Y COMPARTIR EXCEL (.xlsx)
  // ==========================================
  static Future<void> exportarExcel({
    required double ingresos,
    required double totalFijos,
    required double ahorroRecomendado,
    required double disponibleGastos,
    required double limiteDiario,
    required List<GastoFijo> gastosFijos,
    required List<Transaccion> transacciones,
  }) async {
    try {
      var excel = Excel.createExcel();

      // Hoja 1: Resumen
      Sheet sheetResumen = excel['Resumen'];
      excel.setDefaultSheet('Resumen');

      sheetResumen.appendRow([
        TextCellValue('REPORTE FINANCIERO - SURVIVAL FINANCES'),
      ]);
      sheetResumen.appendRow([TextCellValue('')]);
      sheetResumen.appendRow([
        TextCellValue('Concepto'),
        TextCellValue('Monto (\$)'),
      ]);
      sheetResumen.appendRow([
        TextCellValue('Ingreso Mensual'),
        DoubleCellValue(ingresos),
      ]);
      sheetResumen.appendRow([
        TextCellValue('Total Gastos Fijos'),
        DoubleCellValue(totalFijos),
      ]);
      sheetResumen.appendRow([
        TextCellValue('Ahorro Recomendado'),
        DoubleCellValue(ahorroRecomendado),
      ]);
      sheetResumen.appendRow([
        TextCellValue('Disponible Libre'),
        DoubleCellValue(disponibleGastos),
      ]);
      sheetResumen.appendRow([
        TextCellValue('Límite Diario Recomendado'),
        DoubleCellValue(limiteDiario),
      ]);

      // Hoja 2: Gastos Fijos
      Sheet sheetFijos = excel['Gastos Fijos'];
      sheetFijos.appendRow([
        TextCellValue('Concepto'),
        TextCellValue('Monto (\$)'),
      ]);
      for (var f in gastosFijos) {
        sheetFijos.appendRow([
          TextCellValue(f.concepto),
          DoubleCellValue(f.monto),
        ]);
      }

      // Hoja 3: Movimientos Diarios
      Sheet sheetDiarios = excel['Movimientos Diarios'];
      sheetDiarios.appendRow([
        TextCellValue('Fecha'),
        TextCellValue('Categoría'),
        TextCellValue('Concepto'),
        TextCellValue('Monto (\$)'),
      ]);
      for (var t in transacciones) {
        sheetDiarios.appendRow([
          TextCellValue('${t.fecha.day}/${t.fecha.month}/${t.fecha.year}'),
          TextCellValue(t.categoria),
          TextCellValue(t.concepto),
          DoubleCellValue(t.monto),
        ]);
      }

      // Eliminar hoja vacía si existe
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Obtener bytes del Excel
      final fileBytes = excel.save();
      if (fileBytes == null || fileBytes.isEmpty) {
        print("❌ Error: No se pudieron generar los bytes del Excel");
        return;
      }

      // Guardar archivo en directorio temporal
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Reporte_Survival_Finances.xlsx';

      final file = File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      final xFile = XFile(
        file.path,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      // Abrir menú para compartir
      await Share.shareXFiles([
        xFile,
      ], text: '📊 Reporte de finanzas exportado desde Survival Finances');
    } catch (e) {
      print("❌ Error al exportar Excel: $e");
    }
  }
}
