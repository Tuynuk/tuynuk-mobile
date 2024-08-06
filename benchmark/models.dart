class BenchmarkTimer {
  final String _name;

  int run(Function() action) {
    final start = DateTime.now().millisecondsSinceEpoch;
    action.call();
    final end = DateTime.now().millisecondsSinceEpoch;
    final result = end - start;
    print("Benchmark for ($_name): $result ms");
    return result;
  }

  BenchmarkTimer(this._name);
}
