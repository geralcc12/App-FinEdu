import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Colores App
const Color darkScaffoldBackground = Color(0xFF121212);
const Color darkCardBackground = Color(0xFF1E1E1E);
const Color darkPrimaryTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const Color accentColorGreen = Color(0xFF00D19A);
const Color accentColorRed = Colors.redAccent;

const List<Color> pieChartColors = [
  Colors.blueAccent,
  Colors.orangeAccent,
  Colors.purpleAccent,
  Colors.tealAccent,
  Colors.pinkAccent,
  Colors.amberAccent,
  Colors.lightGreenAccent,
  Colors.cyanAccent,
];

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  _ReportesPageState createState() => _ReportesPageState();
}

enum PeriodoReporte { diario, semanal, mensual }

class _ReportesPageState extends State<ReportesPage> {
  PeriodoReporte _selectedPeriod = PeriodoReporte.mensual;
  bool _isLoading = false;
  List<DocumentSnapshot> _ingresosFiltrados = [];
  List<DocumentSnapshot> _gastosFiltrados = [];
  DateTime _currentDate = DateTime.now();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchAndFilterTransactions();
  }

  String _getAppBarTitle() {
    try {
      switch (_selectedPeriod) {
        case PeriodoReporte.diario:
          return 'Reporte Diario (${DateFormat.yMd().format(_currentDate)})';
        case PeriodoReporte.semanal:
          DateTime inicioSemana = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
          DateTime finSemana = inicioSemana.add(const Duration(days: 6));
          return 'Reporte Semanal (${DateFormat.MMMd().format(inicioSemana)} - ${DateFormat.MMMd().format(finSemana)})';
        case PeriodoReporte.mensual:
          return 'Reporte Mensual (${DateFormat.yMMMM().format(_currentDate)})';
      }
    } catch (e) {
      return "Reportes"; // Fallback title
    }
  }

  Future<void> _fetchAndFilterTransactions() async {
    if (_currentUser == null) return;
    setState(() {
      _isLoading = true;
    });
    DateTimeRange rangoFechas;
    switch (_selectedPeriod) {
      case PeriodoReporte.diario:
        DateTime inicioDia = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
        DateTime finDia = DateTime(_currentDate.year, _currentDate.month, _currentDate.day, 23, 59, 59);
        rangoFechas = DateTimeRange(start: inicioDia, end: finDia);
        break;
      case PeriodoReporte.semanal:
        DateTime inicioSemana = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
        inicioSemana = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
        DateTime finSemana = inicioSemana.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        rangoFechas = DateTimeRange(start: inicioSemana, end: finSemana);
        break;
      case PeriodoReporte.mensual:
        DateTime inicioMes = DateTime(_currentDate.year, _currentDate.month, 1);
        DateTime finMes = DateTime(_currentDate.year, _currentDate.month + 1, 0, 23, 59, 59); // Fin del mes
        rangoFechas = DateTimeRange(start: inicioMes, end: finMes);
        break;
    }

    try {
      QuerySnapshot ingresosSnap = await _firestore
          .collection('ingresos')
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(rangoFechas.start))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(rangoFechas.end))
          .orderBy('fecha', descending: true)
          .get();
      QuerySnapshot gastosSnap = await _firestore
          .collection('gastos')
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(rangoFechas.start))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(rangoFechas.end))
          .orderBy('fecha', descending: true)
          .get();
      if (mounted) {
        setState(() {
          _ingresosFiltrados = ingresosSnap.docs;
          _gastosFiltrados = gastosSnap.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar reportes: ${e.toString()}')));
      }
    }
  }

  Map<String, double> _getGastosPorCategoriaData(List<DocumentSnapshot> gastosDocs) {
    Map<String, double> data = {};
    for (var doc in gastosDocs) {
      final docData = doc.data() as Map<String, dynamic>?;
      if (docData != null) {
        final categoria = docData['categoria'] as String? ?? 'Otros';
        final monto = (docData['monto'] as num? ?? 0.0).toDouble();
        data[categoria] = (data[categoria] ?? 0.0) + monto;
      }
    }
    return data;
  }

Future<void> _generarYMostrarPdf({
  required double totalIngresos,
  required double totalGastos,
  required double balance,
  required Map<String, double> gastosPorCategoriaData,
}) async {
    final pdf = pw.Document();
    
    String fechaGeneracion = DateFormat.yMMMMd('es_ES').add_jms().format(DateTime.now());
    final String tituloReporteApp = _getAppBarTitle();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
            padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
            decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey700))),
            child: pw.Text('Reporte Financiero - FinEdu', 
                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey))
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', 
                style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey))
          );
        },
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  pw.Text(tituloReporteApp, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  pw.Text(fechaGeneracion, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ]
              )
            ),
            pw.SizedBox(height: 20),
            
            pw.Header(level: 1, text: 'Resumen del Periodo', textStyle: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
            pw.TableHelper.fromTextArray(
              border: null,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
              headerHeight: 25,
              cellHeight: 30,
              cellStyle: const pw.TextStyle(fontSize: 12),
              headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
              columnWidths: {
                0: const pw.FixedColumnWidth(150),
                1: const pw.FlexColumnWidth(),
              },
              headers: <String>['Concepto', 'Monto'],
              data: <List<String>>[
                ['Ingresos Totales', 'S/ ${totalIngresos.toStringAsFixed(2)}'],
                ['Gastos Totales', 'S/ ${totalGastos.toStringAsFixed(2)}'],
                ['Balance', 'S/ ${balance.toStringAsFixed(2)}'],
              ],
            ),
            pw.SizedBox(height: 25),

            if (gastosPorCategoriaData.isNotEmpty)
              pw.Header(level: 1, text: 'Desglose de Gastos por Categoría', textStyle: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
            if (gastosPorCategoriaData.isNotEmpty)
              pw.TableHelper.fromTextArray(
                border: null,
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal50),
                headerHeight: 25,
                cellHeight: 30,
                cellStyle: const pw.TextStyle(fontSize: 12),
                headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                columnWidths: {
                  0: const pw.FixedColumnWidth(150),
                  1: const pw.FlexColumnWidth(),
                },
                headers: <String>['Categoría', 'Monto Gastado'],
                data: gastosPorCategoriaData.entries.map((entry) {
                  return [entry.key, 'S/ ${entry.value.toStringAsFixed(2)}'];
                }).toList(),
              ),
            
            pw.SizedBox(height: 30),
            pw.Paragraph(text: "Nota: Este es un reporte autogenerado. Los datos reflejan las transacciones registradas en la aplicación hasta la fecha de generación.", 
                         style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic))
          ];
        },
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    double uiTotalIngresos = _ingresosFiltrados.fold(0.0, (sum, item) => sum + ((item.data() as Map<String, dynamic>?)?['monto'] as num? ?? 0.0));
    double uiTotalGastos = _gastosFiltrados.fold(0.0, (sum, item) => sum + ((item.data() as Map<String, dynamic>?)?['monto'] as num? ?? 0.0));
    double uiBalance = uiTotalIngresos - uiTotalGastos;
    Map<String, double> uiGastosPorCategoria = _getGastosPorCategoriaData(_gastosFiltrados);

    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: Text(_getAppBarTitle(), style: const TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.bold, fontSize: 16)), 
        backgroundColor: darkCardBackground, 
        elevation: 1, 
        iconTheme: const IconThemeData(color: darkPrimaryTextColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: darkPrimaryTextColor),
            tooltip: 'Generar PDF',
            onPressed: _isLoading 
                ? null 
                : () => _generarYMostrarPdf(
                    totalIngresos: uiTotalIngresos,
                    totalGastos: uiTotalGastos,
                    balance: uiBalance,
                    gastosPorCategoriaData: uiGastosPorCategoria,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: SegmentedButton<PeriodoReporte>(
              segments: const <ButtonSegment<PeriodoReporte>>[
                ButtonSegment<PeriodoReporte>(value: PeriodoReporte.diario, label: Text('Diario'), icon: Icon(Icons.calendar_view_day)),
                ButtonSegment<PeriodoReporte>(value: PeriodoReporte.semanal, label: Text('Semanal'), icon: Icon(Icons.calendar_view_week)),
                ButtonSegment<PeriodoReporte>(value: PeriodoReporte.mensual, label: Text('Mensual'), icon: Icon(Icons.calendar_today)),
              ],
              selected: <PeriodoReporte>{_selectedPeriod},
              onSelectionChanged: (Set<PeriodoReporte> newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                  _fetchAndFilterTransactions();
                });
              },
              style: SegmentedButton.styleFrom(backgroundColor: darkCardBackground, foregroundColor: darkSecondaryTextColor, selectedForegroundColor: Colors.black, selectedBackgroundColor: accentColorGreen),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: accentColorGreen))
                : _buildReportContent(uiTotalIngresos, uiTotalGastos, uiBalance, uiGastosPorCategoria),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(double totalIngresos, double totalGastos, double balance, Map<String, double> gastosPorCategoria) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: accentColorGreen));
    }
    if (_ingresosFiltrados.isEmpty && _gastosFiltrados.isEmpty && !_isLoading) {
      return const Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No hay transacciones registradas en este periodo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: darkSecondaryTextColor, fontSize: 16),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCard('Ingresos Totales', totalIngresos, accentColorGreen),
          const SizedBox(height: 12),
          _buildSummaryCard('Gastos Totales', totalGastos, accentColorRed),
          const SizedBox(height: 12),
          _buildSummaryCard('Balance del Periodo', balance, balance >= 0 ? accentColorGreen : accentColorRed, isBalance: true),
          const SizedBox(height: 24),
          if (totalIngresos > 0 || totalGastos > 0)
            _buildIncomeExpenseBarChart(totalIngresos, totalGastos),
          const SizedBox(height: 24),
          if (gastosPorCategoria.isNotEmpty)
             _buildExpensesByCategoryPieChart(gastosPorCategoria),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseBarChart(double totalIngresos, double totalGastos) {
    return Card(
      color: darkCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresos vs. Gastos',
              style: TextStyle(color: darkPrimaryTextColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (totalIngresos > totalGastos ? totalIngresos : totalGastos) * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          String text = '';
                          if (value == 0) text = 'Ingresos';
                          if (value == 1) text = 'Gastos';
                          return SideTitleWidget(axisSide: meta.axisSide, space: 4.0, child: Text(text, style: const TextStyle(color: darkSecondaryTextColor, fontSize: 12)));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: ((totalIngresos > totalGastos ? totalIngresos : totalGastos) * 1.2 / 5).clamp(1, double.infinity), getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(color: darkSecondaryTextColor, fontSize: 10)))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: darkSecondaryTextColor.withOpacity(0.2), strokeWidth: 0.5)),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [BarChartRodData(toY: totalIngresos, color: accentColorGreen, width: 22, borderRadius: BorderRadius.circular(4))],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [BarChartRodData(toY: totalGastos, color: accentColorRed, width: 22, borderRadius: BorderRadius.circular(4))],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesByCategoryPieChart(Map<String, double> gastosPorCategoria) {
    if (gastosPorCategoria.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: Text(
            'No hay gastos para mostrar en el gráfico.',
            style: TextStyle(color: darkSecondaryTextColor, fontSize: 14),
          ),
        ),
      );
    }
    int colorIndex = 0;
    List<PieChartSectionData> sections = gastosPorCategoria.entries.map((entry) {
      final color = pieChartColors[colorIndex % pieChartColors.length];
      colorIndex++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${(entry.value / gastosPorCategoria.values.reduce((a, b) => a + b) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: [const Shadow(color: Colors.black, blurRadius: 2)]),
      );
    }).toList();

    return Card(
      color: darkCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gastos por Categoría',
              style: TextStyle(color: darkPrimaryTextColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Puedes manejar interacciones aquí si es necesario
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: gastosPorCategoria.entries.map((entry) {
                      final color = pieChartColors[gastosPorCategoria.keys.toList().indexOf(entry.key) % pieChartColors.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${entry.key} - S/ ${entry.value.toStringAsFixed(2)}',
                                style: const TextStyle(color: darkSecondaryTextColor, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, {bool isBalance = false}) {
    return Card(
      color: darkCardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 16, color: darkSecondaryTextColor)),
            Text(
              '${isBalance && amount < 0 ? '-' : ''}S/ ${amount.abs().toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
