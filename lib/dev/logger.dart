import 'package:flutter/foundation.dart';

logMessage(dynamic message) {
  if (kDebugMode) {
    const greenColor = '\u001B[32m';
    const resetColor = '\u001B[0m';

    print('$greenColor$message$resetColor');
  }
}
