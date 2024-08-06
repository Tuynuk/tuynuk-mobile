import 'package:envied/envied.dart';

part 'environment.g.dart';

@Envied(path: 'env.env')
abstract class Environment {
  @EnviedField(varName: 'key', obfuscate: true)
  static String key = _Environment.key;
}
