class StringUtils {
  static List<String> splitByLength(String value, int length) {
    List<String> pieces = [];

    for (int i = 0; i < value.length; i += length) {
      int offset = i + length;
      pieces.add(
          value.substring(i, offset >= value.length ? value.length : offset));
    }
    return pieces;
  }
}
