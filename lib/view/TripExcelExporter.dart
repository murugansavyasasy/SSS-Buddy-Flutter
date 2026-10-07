// lib/components/TripExcelExporter.dart
//
// Terminal: flutter pub add excel path_provider
// (share_plus & shared_preferences already project-la irukku)

import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/model/OverallTripDetailsModel.dart';

class TripExcelExporter {
  // ------------------------------------------------------------
  // STYLES
  // ------------------------------------------------------------
  static final CellStyle _headerStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('#1F4E78'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  static final CellStyle _boldStyle = CellStyle(bold: true);

  static final CellStyle _totalStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#DDEBF7'),
  );

  static final CellStyle _wrapStyle = CellStyle(
    textWrapping: TextWrapping.WrapText,
    verticalAlign: VerticalAlign.Top,
  );

  static final CellStyle _noEntryStyle = CellStyle(
    fontColorHex: ExcelColor.fromHexString('#C62828'),
  );

  // Nominatim allows max 1 request / second.
  static const Duration _requestGap = Duration(milliseconds: 1100);
  static DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  // ------------------------------------------------------------
  // PUBLIC: build + share
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // WORKBOOK
  // ------------------------------------------------------------
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
    final visitsSheet = excel['Visits'];

    final sortedDays = [...days]..sort(); // 1 -> 31
    final dateFmt = DateFormat('dd/MM/yyyy');
    final dayFmt = DateFormat('EEEE');

    // ---- Totals (needed for the summary block at the top)
    var totalKm = 0.0;
    var totalTrips = 0;
    for (final d in sortedDays) {
      for (final t in tripsByDay[d] ?? const <Overalltripdetailsmodel>[]) {
        totalKm += t.totalDistanceKm;
        totalTrips++;
      }
    }

    final periodLabel = date != null
        ? DateFormat('dd MMM yyyy').format(date)
        : DateFormat('MMMM yyyy').format(month);

    // ---- Summary block
    _kv(report, 'Employee', TextCellValue(username));
    _kv(report, 'Period', TextCellValue(periodLabel));
    _kv(report, 'Total Trips', IntCellValue(totalTrips));
    _kv(report, 'Total Distance (km)', _km(totalKm), highlight: true);
    report.appendRow([TextCellValue('')]); // blank spacer

    // ---- Table header
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
        'Visited Places',
        'Distance (km)',
      ],
      const [12, 12, 9, 20, 45, 20, 45, 40, 14],
    );
    _addHeader(
      visitsSheet,
      const [
        'Date',
        'Trip ID',
        '#',
        'School',
        'Person',
        'Reason of Visit',
        'Remarks',
        'Latitude',
        'Longitude',
        'Distance from previous (km)',
      ],
      const [12, 9, 5, 30, 22, 25, 30, 14, 14, 16],
    );

    // Address cache for this export (same home/office repeats every day).
    final addressMemo = <String, String>{};

    for (final day in sortedDays) {
      final dayDate = DateTime(month.year, month.month, day);
      final dateStr = dateFmt.format(dayDate);
      final dayName = dayFmt.format(dayDate);
      final dayTrips = tripsByDay[day] ?? const <Overalltripdetailsmodel>[];

      // ---- No entry day
      if (dayTrips.isEmpty) {
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
        continue;
      }

      for (final trip in dayTrips) {
        final startAddr = await _addressFor(
          trip.start_latitude,
          trip.start_longitude,
          addressMemo,
        );

        final hasEnd = (trip.end_latitude ?? '').trim().isNotEmpty &&
            (trip.end_longitude ?? '').trim().isNotEmpty;
        final endAddr = hasEnd
            ? await _addressFor(
          trip.end_latitude,
          trip.end_longitude,
          addressMemo,
        )
            : 'Trip not ended';

        final places = trip.visit_details
            .map((v) => (v.school_name ?? '').trim())
            .where((s) => s.isNotEmpty)
            .join('  →  ');

        // ---- Trip row
        report.appendRow([
          TextCellValue(dateStr),
          TextCellValue(dayName),
          IntCellValue(trip.trip_id),
          TextCellValue(trip.start_time),
          TextCellValue(startAddr),
          TextCellValue(trip.end_time ?? '-'),
          TextCellValue(endAddr),
          TextCellValue(places.isEmpty ? '-' : places),
          _km(trip.totalDistanceKm),
        ]);
        final r = report.maxRows - 1;
        for (final c in [4, 6, 7]) {
          report
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
              .cellStyle = _wrapStyle;
        }

        // ---- Visits rows (leg distance from previous point, x1.3 road factor)
        double? prevLat;
        double? prevLon;
        final startPt = _parsePoint(trip.start_latitude, trip.start_longitude);
        if (startPt != null) {
          prevLat = startPt[0];
          prevLon = startPt[1];
        }

        var n = 0;
        for (final v in trip.visit_details) {
          n++;
          final lat = v.latitude;
          final lon = v.longitude;

          double? leg;
          if (lat != null && lon != null) {
            if (prevLat != null && prevLon != null) {
              leg = DistanceCalculator.distanceBetween(
                  prevLat, prevLon, lat, lon) /
                  1000.0 *
                  1.3;
            }
            prevLat = lat;
            prevLon = lon;
          }

          visitsSheet.appendRow([
            TextCellValue(dateStr),
            IntCellValue(trip.trip_id),
            IntCellValue(n),
            TextCellValue(v.school_name ?? ''),
            TextCellValue(v.person_name ?? ''),
            TextCellValue(v.reason_of_visit ?? ''),
            TextCellValue(v.remarks ?? ''),
            TextCellValue(v.school_latitude ?? ''),
            TextCellValue(v.school_longitude ?? ''),
            leg == null ? TextCellValue('') : _km(leg),
          ]);
        }
      }
    }

    // ---- Overall total row (end of table)
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

    excel.setDefaultSheet('Trip Report');

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Excel file generate panna mudiyala');
    }
    return bytes;
  }

  // ------------------------------------------------------------
  // ADDRESS LOOKUP (uses the same cache as TripAddressLoader)
  // ------------------------------------------------------------
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
      // Not cached -> hit Nominatim, respecting its 1 req/sec limit.
      final wait = _requestGap - DateTime.now().difference(_lastRequest);
      if (!wait.isNegative) await Future.delayed(wait);
      _lastRequest = DateTime.now();

      addr = await TripAddressLoader.getCachedAddress(
        latitude: lat,
        longitude: lon,
      );
    }

    // Lookup fail aanaalum blank vara koodadhu -> coordinates kaattuvom.
    if (addr == 'Address unavailable') {
      addr = '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
    }

    memo[key] = addr;
    return addr;
  }

  static List<double>? _parsePoint(String? latStr, String? lonStr) {
    if (latStr == null || lonStr == null) return null;
    try {
      return [
        DistanceCalculator.parseCoordinate(latStr),
        DistanceCalculator.parseCoordinate(lonStr),
      ];
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  /// "Label | value" row used for the summary block at the top.
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

  static DoubleCellValue _km(double v) =>
      DoubleCellValue(double.parse(v.toStringAsFixed(2)));
}