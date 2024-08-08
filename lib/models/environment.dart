import 'package:envied/envied.dart';

part 'environment.g.dart';

@Envied(path: 'environment.env')
abstract class Environment {
  @EnviedField(varName: 'key', obfuscate: true)
  static String key = _Environment.key;
}
