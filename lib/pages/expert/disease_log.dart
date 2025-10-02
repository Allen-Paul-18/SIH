import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;

/* ========== ENTRY-POINT (optional) ========== */
void main() => runApp(const _DiseaseApp());

class _DiseaseApp extends StatelessWidget {
  const _DiseaseApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disease Log & Reports',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
        fontFamily: 'Roboto',
      ),
      home: const DiseaseLogScreen(),
    );
  }
}

/* =========================================================
                   MAIN SCREEN (TAB LAYOUT)
========================================================= */
class DiseaseLogScreen extends StatefulWidget {
  const DiseaseLogScreen({super.key});

  @override
  State<DiseaseLogScreen> createState() => _DiseaseLogScreenState();
}

class _DiseaseLogScreenState extends State<DiseaseLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  /* ------------ dummy data ------------ */
  final List<DiseaseCase> _cases = dummyCases;
  List<DiseaseCase> _filtered = [];

  /* ------------ filters ------------ */
  String _speciesFilter = 'All';
  String _regionFilter = 'All';
  DateTimeRange? _dateRange;

  /* ------------ alerts ------------ */
  bool _showAlert = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _filtered = List.from(_cases);
    _checkAlerts();
  }

  void _checkAlerts() {
    final critical = _cases.where((c) => c.severity == Severity.critical).length;
    _showAlert = critical > 2;
  }

  /* ------------ filter logic ------------ */
  void _applyFilters() {
    _filtered = _cases.where((c) {
      final spec = _speciesFilter == 'All' || c.species == _speciesFilter;
      final reg = _regionFilter == 'All' || c.region == _regionFilter;
      var date = true;
      if (_dateRange != null) {
        date = c.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            c.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }
      return spec && reg && date;
    }).toList();
    setState(() {});
  }

  /* ------------ export ------------ */
  Future<void> _exportCSV() async {
    final rows = <List<dynamic>>[
      ['Case-ID', 'Species', 'Region', 'Date', 'Symptoms', 'Severity']
    ];
    for (var c in _filtered) {
      rows.add([c.id, c.species, c.region, DateFormat('yyyy-MM-dd').format(c.date),
        c.symptoms.join('; '), describeEnum(c.severity)]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/disease_report.csv')..writeAsStringSync(csv);
    OpenFile.open(file.path);
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Disease Outbreak Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Case-ID', 'Species', 'Region', 'Date', 'Symptoms', 'Severity'],
            data: _filtered.map((c) => [
              c.id, c.species, c.region,
              DateFormat('yyyy-MM-dd').format(c.date),
              c.symptoms.join(', '),
              describeEnum(c.severity)
            ]).toList(),
          ),
        ],
      ),
    ));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/disease_report.pdf')
      ..writeAsBytesSync(await pdf.save());
    OpenFile.open(file.path);
  }

  /* ------------ UI ------------ */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5F3F),
        title: const Text('Disease Log & Reports'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'List', icon: Icon(Icons.list)),
            Tab(text: 'Map', icon: Icon(Icons.map)),
            Tab(text: 'Filters', icon: Icon(Icons.filter_list)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_showAlert)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade400,
              child: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unusual disease spike detected. Please review critical cases.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: TabBarView(controller: _tabCtrl, children: [
            _CaseListView(filtered: _filtered),
            _MapView(cases: _filtered),
            _FilterView(
              species: _speciesFilter,
              region: _regionFilter,
              dateRange: _dateRange,
              onSpecies: (v) => setState(() => _speciesFilter = v),
              onRegion: (v) => setState(() => _regionFilter = v),
              onDate: (v) => setState(() => _dateRange = v),
              onApply: _applyFilters,
              onExportCsv: _exportCSV,
              onExportPdf: _exportPDF,
            ),
          ])),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCaseSheet(),
        backgroundColor: const Color(0xFF2D5F3F),
        icon: const Icon(Icons.add),
        label: const Text('Add Case'),
      ),
    );
  }

  /* ------------ ADD CASE BOTTOM SHEET ------------ */
  void _showAddCaseSheet() {
    final formKey = GlobalKey<FormState>();
    final speciesCtrl = TextEditingController();
    final symptomsCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final regionCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    Severity severity = Severity.mild;
    LatLng? gps;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setState2) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add New Disease Case',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: speciesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Species *',
                      hintText: 'e.g., Cattle, Goat, Poultry',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: symptomsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Symptoms *',
                      hintText: 'Comma separated',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: regionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Region / Village *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    leading: const Icon(Icons.calendar_today),
                    title: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState2(() => selectedDate = d);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Severity', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: Severity.values
                        .map(
                          (s) => Expanded(
                        child: RadioListTile<Severity>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(describeEnum(s)),
                          value: s,
                          groupValue: severity,
                          onChanged: (v) => setState2(() => severity = v!),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    leading: const Icon(Icons.location_on),
                    title: Text(gps == null
                        ? 'Tap to capture GPS'
                        : 'Lat ${gps!.latitude.toStringAsFixed(4)}, Lng ${gps!.longitude.toStringAsFixed(4)}'),
                    trailing: const Icon(Icons.my_location),
                    onTap: () async {
                      // In real app: use geolocator package
                      setState2(() => gps = const LatLng(12.9716, 77.5946));
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5F3F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final newCase = DiseaseCase(
                          id: 'CASE-${DateTime.now().millisecondsSinceEpoch}',
                          species: speciesCtrl.text,
                          symptoms: symptomsCtrl.text
                              .split(',')
                              .map((e) => e.trim())
                              .toList(),
                          region: regionCtrl.text,
                          date: selectedDate,
                          severity: severity,
                          notes: notesCtrl.text,
                          latLng: gps,
                        );
                        setState(() => _cases.add(newCase));
                        _applyFilters();
                        _checkAlerts();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Save Case',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/* =========================================================
                        MODEL
========================================================= */
enum Severity { mild, moderate, critical }

class DiseaseCase {
  final String id;
  final String species;
  final List<String> symptoms;
  final String region;
  final DateTime date;
  final Severity severity;
  final String notes;
  final LatLng? latLng;

  DiseaseCase({
    required this.id,
    required this.species,
    required this.symptoms,
    required this.region,
    required this.date,
    required this.severity,
    this.notes = '',
    this.latLng,
  });
}

/* =========================================================
                        DUMMY DATA
========================================================= */
final List<DiseaseCase> dummyCases = [
  DiseaseCase(
    id: 'DC001',
    species: 'Cattle',
    symptoms: ['Fever', 'Lameness'],
    region: 'Mysuru',
    date: DateTime.now().subtract(const Duration(days: 2)),
    severity: Severity.critical,
    notes: 'Suspected FMD',
    latLng: const LatLng(12.2958, 76.6394),
  ),
  DiseaseCase(
    id: 'DC002',
    species: 'Goat',
    symptoms: ['Cough', 'Nasal discharge'],
    region: 'Hassan',
    date: DateTime.now().subtract(const Duration(days: 5)),
    severity: Severity.mild,
    latLng: const LatLng(13.0063, 76.0991),
  ),
  DiseaseCase(
    id: 'DC003',
    species: 'Poultry',
    symptoms: ['Drop in egg production', 'Cough'],
    region: 'Bidadi',
    date: DateTime.now().subtract(const Duration(days: 1)),
    severity: Severity.moderate,
    latLng: const LatLng(12.9464, 77.3859),
  ),
];

/* =========================================================
                        WIDGET CHUNKS
========================================================= */
class _CaseListView extends StatelessWidget {
  final List<DiseaseCase> filtered;

  const _CaseListView({required this.filtered});

  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No cases found', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final c = filtered[i];
        final color = c.severity == Severity.critical
            ? Colors.red.shade100
            : c.severity == Severity.moderate
            ? Colors.orange.shade100
            : Colors.green.shade100;
        final textColor = c.severity == Severity.critical
            ? Colors.red.shade700
            : c.severity == Severity.moderate
            ? Colors.orange.shade700
            : Colors.green.shade700;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.species,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        describeEnum(c.severity),
                        style: TextStyle(
                            color: textColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c.symptoms.join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(c.region, style: TextStyle(color: Colors.grey.shade600)),
                    const Spacer(),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd MMM').format(c.date),
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapView extends StatelessWidget {
  final List<DiseaseCase> cases;

  const _MapView({required this.cases});

  Set<Marker> _markers() {
    return cases.map((c) {
      final color = c.severity == Severity.critical
          ? BitmapDescriptor.hueRed
          : c.severity == Severity.moderate
          ? BitmapDescriptor.hueOrange
          : BitmapDescriptor.hueGreen;
      return Marker(
        markerId: MarkerId(c.id),
        position: c.latLng ?? const LatLng(0, 0),
        infoWindow: InfoWindow(
          title: c.species,
          snippet: c.symptoms.join(', '),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(color),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(12.9716, 77.5946),
        zoom: 7,
      ),
      markers: _markers(),
    );
  }
}

class _FilterView extends StatelessWidget {
  final String species;
  final String region;
  final DateTimeRange? dateRange;
  final ValueChanged<String> onSpecies;
  final ValueChanged<String> onRegion;
  final ValueChanged<DateTimeRange?> onDate;
  final VoidCallback onApply;
  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;

  const _FilterView({
    required this.species,
    required this.region,
    required this.dateRange,
    required this.onSpecies,
    required this.onRegion,
    required this.onDate,
    required this.onApply,
    required this.onExportCsv,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Species'),
          DropdownButton<String>(
            value: species,
            isExpanded: true,
            items: ['All', 'Cattle', 'Goat', 'Poultry', 'Swine']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => onSpecies(v!),
          ),
          const SizedBox(height: 16),
          const Text('Region'),
          DropdownButton<String>(
            value: region,
            isExpanded: true,
            items: ['All', 'Mysuru', 'Hassan', 'Bidadi', 'Mandya']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => onRegion(v!),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            leading: const Icon(Icons.date_range),
            title: Text(dateRange == null
                ? 'Select date range'
                : '${DateFormat('dd MMM').format(dateRange!.start)} - ${DateFormat('dd MMM').format(dateRange!.end)}'),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final d = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              onDate(d);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5F3F),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onApply,
              icon: const Icon(Icons.filter_alt, color: Colors.white),
              label: const Text('Apply Filters',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 40),
          const Text('Export Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onExportCsv,
                  icon: const Icon(Icons.table_view),
                  label: const Text('CSV'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onExportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}