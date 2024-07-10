import 'package:flutter/foundation.dart';

logMessage(dynamic message) {
  if (kDebugMode) {
    print(message.toString());
  }
}
