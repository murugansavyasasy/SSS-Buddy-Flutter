import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  static void info(dynamic message) {
    _logger.i(message);
  }

  static void error(dynamic message) {
    _logger.e(message);
  }

  static void warning(dynamic message) {
    _logger.w(message);
  }

  static void debug(dynamic message) {
    _logger.d(message);
  }
}