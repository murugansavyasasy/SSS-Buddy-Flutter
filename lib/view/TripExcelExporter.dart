import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/model/OverallTripDetailsModel.dart';
class _Stop {
  final String label;
  final double? lat;
  final double? lon;
  final String person;
  final String reason;
  final String remarks;
  _Stop(this.label, this.lat, this.lon,
      {this.person = '', this.reason = '', this.remarks = ''});
}
class _Leg {
  final String from;
  final String to;
  final double? km; // null => coordinates missing
  final String person;
  final String reason;
  final String remarks;
  _Leg(this.from, this.to, this.km,
      {this.person = '', this.reason = '', this.remarks = ''});
}
class _TripRoute {
  final Overalltripdetailsmodel trip;
  final String startAddr;
  final String endAddr;
  final bool hasEnd;
  final List<_Stop> stops;
  final List<_Leg> legs;
  final double totalKm;

  _TripRoute({
    required this.trip,
    required this.startAddr,
    required this.endAddr,
    required this.hasEnd,
    required this.stops,
    required this.legs,
    required this.totalKm,
  });

  String get routeText => stops.map((s) => s.label).join('  →  ');
}

class TripExcelExporter {
  static final CellStyle _headerStyle = CellStyle(
    fontFamily: 'Arial',
    fontSize: 10,
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('#1F4E78'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle _baseStyle = CellStyle(
    fontFamily: 'Arial',
    fontSize: 10,
  );

  static final CellStyle _boldStyle = CellStyle(
    fontFamily: 'Arial',
    fontSize: 10,
    bold: true,
  );
  static final CellStyle _numStyle = CellStyle(
    fontFamily: 'Arial',
    fontSize: 10,
    numberFormat: NumFormat.standard_2,
  );

  static final CellStyle _totalNumStyle = CellStyle(
    fontFamily: 'Arial',
    fontSize: 10,
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#DDEBF7'),
    numberFormat: NumFormat.standard_2,
  );

  static final CellStyle _totalStyle = CellStyle(
    fontFamily: 'Arial',
    fontSize: 10,
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#DDEBF7'),
  );

  static final CellStyle _wrapStyle = CellStyle(
    fontFamily: 'Arial',
    fontSize: 10,
    textWrapping: TextWrapping.WrapText,
    verticalAlign: VerticalAlign.Top,
  );

  static final CellStyle _noEntryStyle = CellStyle(
    fontFamily: 'Arial',
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#C62828'),
  );
  static const Duration _requestGap = Duration(milliseconds: 1100);
  static DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> exportAndShare({
    required DateTime month,
    DateTime? date,
    required List<int> days,
    required Map<int, List<Overalltripdetailsmodel>> tripsByDay,
    required String username,
  }) async {
    final bytes = await buildWorkbook(
      month: month,
      date: date,
      days: days,
      tripsByDay: tripsByDay,
      username: username,
    );

    final dir = await getTemporaryDirectory();
    final safeName = username.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final period = date != null
        ? DateFormat('yyyy-MM-dd').format(date)
        : DateFormat('yyyy-MM').format(month);
    final file = File('${dir.path}/Trip_Report_${safeName}_$period.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'Trip Report - $username ($period)',
      ),
    );
  }

  static Future<List<int>> buildWorkbook({
    required DateTime month,
    DateTime? date,
    required List<int> days,
    required Map<int, List<Overalltripdetailsmodel>> tripsByDay,
    required String username,
  }) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Trip Report');

    final report = excel['Trip Report'];
    final legsSheet = excel['Route Legs'];
    final sortedDays = [...days]..sort(); // 1 -> 31
    final dateFmt = DateFormat('dd/MM/yyyy');
    final dayFmt = DateFormat('EEEE');
    final addressMemo = <String, String>{};
    final routesByDay = <int, List<_TripRoute>>{};
    var totalKm = 0.0;
    var totalTrips = 0;

    for (final day in sortedDays) {
      final list = <_TripRoute>[];
      for (final trip
      in tripsByDay[day] ?? const <Overalltripdetailsmodel>[]) {
        final r = await _buildRoute(trip, addressMemo);
        list.add(r);
        totalKm += r.totalKm;
        totalTrips++;
      }
      routesByDay[day] = list;
    }

    final periodLabel = date != null
        ? DateFormat('dd MMM yyyy').format(date)
        : DateFormat('MMMM yyyy').format(month);
    _kv(report, 'Employee', TextCellValue(username));
    _kv(report, 'Period', TextCellValue(periodLabel));
    _kv(report, 'Total Trips', IntCellValue(totalTrips));
    _kv(report, 'Total Distance (km)', _km(totalKm), highlight: true);
    report
        .cell(CellIndex.indexByColumnRow(
        columnIndex: 1, rowIndex: report.maxRows - 1))
        .cellStyle = _totalNumStyle;
    report.appendRow([TextCellValue('')]);
    _addHeader(
      report,
      const [
        'Date',
        'Day',
        'Trip ID',
        'Start Time',
        'Start Location (From)',
        'End Time',
        'End Location (To)',
        'Route (From → Places → To)',
        'Total Distance (km)',
      ],
      const [12, 12, 9, 20, 45, 20, 45, 70, 16],
    );
    _addHeader(
      legsSheet,
      const [
        'Date',
        'Trip ID',
        'Leg #',
        'From',
        'To',
        'Distance (km)',
        'Person Met',
        'Reason of Visit',
        'Remarks',
      ],
      const [12, 9, 7, 50, 50, 16, 22, 28, 28],
    );
    for (final day in sortedDays) {
      final dayDate = DateTime(month.year, month.month, day);
      final dateStr = dateFmt.format(dayDate);
      final dayName = dayFmt.format(dayDate);
      final routes = routesByDay[day] ?? const <_TripRoute>[];
      if (routes.isEmpty) {
        report.appendRow([
          TextCellValue(dateStr),
          TextCellValue(dayName),
          TextCellValue('-'),
          TextCellValue('-'),
          TextCellValue('No entry'),
          TextCellValue('-'),
          TextCellValue('-'),
          TextCellValue('-'),
          _km(0),
        ]);
        final r = report.maxRows - 1;
        report
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r))
            .cellStyle = _noEntryStyle;
        report
            .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: r))
            .cellStyle = _numStyle;
        continue;
      }

      for (final tr in routes) {
        final trip = tr.trip;
        report.appendRow([
          TextCellValue(dateStr),
          TextCellValue(dayName),
          IntCellValue(trip.trip_id),
          TextCellValue(trip.start_time),
          TextCellValue(tr.startAddr),
          TextCellValue(trip.end_time ?? '-'),
          TextCellValue(tr.endAddr),
          TextCellValue(tr.routeText),
          _km(tr.totalKm),
        ]);
        final r = report.maxRows - 1;
        for (final c in [4, 6, 7]) {
          report
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
              .cellStyle = _wrapStyle;
        }
        report
            .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: r))
            .cellStyle = _numStyle;
        var n = 0;
        for (final leg in tr.legs) {
          n++;
          legsSheet.appendRow([
            TextCellValue(dateStr),
            IntCellValue(trip.trip_id),
            IntCellValue(n),
            TextCellValue(leg.from),
            TextCellValue(leg.to),
            leg.km == null ? TextCellValue('-') : _km(leg.km!),
            TextCellValue(leg.person),
            TextCellValue(leg.reason),
            TextCellValue(leg.remarks),
          ]);
          final lr = legsSheet.maxRows - 1;
          for (final c in [3, 4, 6, 7, 8]) {
            legsSheet
                .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: lr))
                .cellStyle = _wrapStyle;
          }
          legsSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: lr))
              .cellStyle = _numStyle;
        }

        legsSheet.appendRow([
          TextCellValue(dateStr),
          IntCellValue(trip.trip_id),
          TextCellValue(''),
          TextCellValue('TRIP TOTAL'),
          TextCellValue(tr.hasEnd ? '' : 'Trip not ended'),
          _km(tr.totalKm),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
        ]);
        final tRow = legsSheet.maxRows - 1;
        for (var c = 0; c < 9; c++) {
          legsSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: tRow))
              .cellStyle = _totalStyle;
        }
        legsSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: tRow))
            .cellStyle = _totalNumStyle;
      }
    }

    report.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue(''),
      IntCellValue(totalTrips),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(periodLabel),
      _km(totalKm),
    ]);
    final totalRow = report.maxRows - 1;
    for (var c = 0; c < 9; c++) {
      report
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: totalRow))
          .cellStyle = _totalStyle;
    }
    report
        .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: totalRow))
        .cellStyle = _totalNumStyle;
    _applyBase(report);
    _applyBase(legsSheet);

    excel.setDefaultSheet('Trip Report');

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Excel file generate panna mudiyala');
    }
    return bytes;
  }

  static Future<_TripRoute> _buildRoute(
      Overalltripdetailsmodel trip,
      Map<String, String> memo,
      ) async {
    final startAddr = await _addressFor(
      trip.start_latitude?.toString(),
      trip.start_longitude?.toString(),
      memo,
    );
    final startPt = _parsePoint(
      trip.start_latitude?.toString(),
      trip.start_longitude?.toString(),
    );

    final endLatStr = (trip.end_latitude ?? '').toString().trim();
    final endLonStr = (trip.end_longitude ?? '').toString().trim();
    final hasEnd = endLatStr.isNotEmpty && endLonStr.isNotEmpty;
    final endAddr =
    hasEnd ? await _addressFor(endLatStr, endLonStr, memo) : 'Trip not ended';
    final endPt = hasEnd ? _parsePoint(endLatStr, endLonStr) : null;

    final stops = <_Stop>[
      _Stop(startAddr, startPt?[0], startPt?[1]),
    ];
    for (final v in trip.visit_details) {
      final name = (v.school_name ?? '').trim();
      final latStr = (v.school_latitude ?? '').toString().trim();
      final lonStr = (v.school_longitude ?? '').toString().trim();
      if (name.isEmpty && latStr.isEmpty && lonStr.isEmpty) continue;

      final pt = _parsePoint(latStr, lonStr);
      final label = name.isNotEmpty
          ? name
          : await _addressFor(latStr, lonStr, memo);
      stops.add(_Stop(
        label,
        pt?[0],
        pt?[1],
        person: (v.person_name ?? '').trim(),
        reason: (v.reason_of_visit ?? '').trim(),
        remarks: (v.remarks ?? '').trim(),
      ));
    }

    if (hasEnd) {
      stops.add(_Stop(endAddr, endPt?[0], endPt?[1]));
    }

    final String endLabel = hasEnd
        ? endAddr
        : (stops.length > 1
        ? '${stops.last.label} (trip not ended)'
        : endAddr);
    final double total = trip.totalDistanceKm;
    final rawKm = <double?>[];
    var rawTotal = 0.0;
    double? prevLat = stops.first.lat;
    double? prevLon = stops.first.lon;

    for (var i = 1; i < stops.length; i++) {
      final to = stops[i];
      double? km;
      if (prevLat != null &&
          prevLon != null &&
          to.lat != null &&
          to.lon != null) {
        km = DistanceCalculator.distanceBetween(
            prevLat, prevLon, to.lat!, to.lon!) /
            1000.0;
        rawTotal += km;
      }
      if (to.lat != null && to.lon != null) {
        prevLat = to.lat;
        prevLon = to.lon;
      }
      rawKm.add(km);
    }
    final scale = rawTotal > 0 ? total / rawTotal : 0.0;

    final legs = <_Leg>[];
    for (var i = 1; i < stops.length; i++) {
      final from = stops[i - 1];
      final to = stops[i];
      final raw = rawKm[i - 1];
      legs.add(_Leg(
        from.label,
        to.label,
        raw == null ? null : raw * scale,
        person: to.person,
        reason: to.reason,
        remarks: to.remarks,
      ));
    }

    return _TripRoute(
      trip: trip,
      startAddr: startAddr,
      endAddr: endLabel,
      hasEnd: hasEnd,
      stops: stops,
      legs: legs,
      totalKm: total,
    );
  }
  static Future<String> _addressFor(
      String? latStr,
      String? lonStr,
      Map<String, String> memo,
      ) async {
    if (latStr == null ||
        lonStr == null ||
        latStr.trim().isEmpty ||
        lonStr.trim().isEmpty) {
      return '-';
    }

    final pt = _parsePoint(latStr, lonStr);
    if (pt == null) return '$latStr, $lonStr';

    final lat = pt[0];
    final lon = pt[1];
    final key = TripAddressLoader.cacheKey(lat, lon);

    final inMemo = memo[key];
    if (inMemo != null) return inMemo;

    final prefs = await SharedPreferences.getInstance();
    String? addr = prefs.getString(key);

    if (addr == null || addr.isEmpty) {
      final wait = _requestGap - DateTime.now().difference(_lastRequest);
      if (!wait.isNegative) await Future.delayed(wait);
      _lastRequest = DateTime.now();

      addr = await TripAddressLoader.getCachedAddress(
        latitude: lat,
        longitude: lon,
      );
    }
    if (addr == 'Address unavailable') {
      addr = '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
    }

    memo[key] = addr;
    return addr;
  }

  static List<double>? _parsePoint(String? latStr, String? lonStr) {
    if (latStr == null || lonStr == null) return null;
    if (latStr.trim().isEmpty || lonStr.trim().isEmpty) return null;
    try {
      return [
        DistanceCalculator.parseCoordinate(latStr),
        DistanceCalculator.parseCoordinate(lonStr),
      ];
    } catch (_) {
      return null;
    }
  }
  static void _kv(
      Sheet sheet,
      String label,
      CellValue value, {
        bool highlight = false,
      }) {
    sheet.appendRow([TextCellValue(label), value]);
    final r = sheet.maxRows - 1;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r))
        .cellStyle = _boldStyle;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r))
        .cellStyle = highlight ? _totalStyle : _boldStyle;
  }

  static void _addHeader(
      Sheet sheet,
      List<String> headers,
      List<double> widths,
      ) {
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    final r = sheet.maxRows - 1;
    for (var c = 0; c < headers.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
          .cellStyle = _headerStyle;
      sheet.setColumnWidth(c, widths[c]);
    }
  }

  static void _applyBase(Sheet sheet) {
    for (var r = 0; r < sheet.maxRows; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );
        if (cell.cellStyle == null) cell.cellStyle = _baseStyle;
      }
    }
  }

  static DoubleCellValue _km(double v) =>
      DoubleCellValue(double.parse(v.toStringAsFixed(2)));
}