class BenchmarkTimer {
  final String _name;

  Future<void> runAsync(Future<void> Function() action) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    await action();
    final end = DateTime.now().millisecondsSinceEpoch;
    final result = end - start;
    print('Benchmark for ($_name): $result ms');
  }

  int run(Function() action) {
    final start = DateTime.now().millisecondsSinceEpoch;
    action.call();
    final end = DateTime.now().millisecondsSinceEpoch;
    final result = end - start;
    print('Benchmark for ($_name): $result ms');
    return result;
  }

  BenchmarkTimer(this._name);
}
