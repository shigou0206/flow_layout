class Entry {
  List<String> vs;
  int i;
  double? barycenter;
  double? weight;

  Entry({required this.vs, required this.i, this.barycenter, this.weight});

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
        vs: List<String>.from(json['vs']),
        i: json['i'] as int,
        barycenter: (json['barycenter'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'vs': vs,
        'i': i,
        if (barycenter != null) 'barycenter': barycenter,
        if (weight != null) 'weight': weight,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entry &&
          runtimeType == other.runtimeType &&
          vs.equals(other.vs) &&
          i == other.i &&
          barycenter == other.barycenter &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(vs.hashCode, i, barycenter, weight);

  @override
  String toString() =>
      'Entry(vs: $vs, i: $i, barycenter: $barycenter, weight: $weight)';
}

class SortResult {
  final List<String> vs;
  final double? barycenter;
  final double? weight;

  SortResult({required this.vs, this.barycenter, this.weight});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortResult &&
          runtimeType == other.runtimeType &&
          vs.equals(other.vs) &&
          barycenter == other.barycenter &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(vs.hashCode, barycenter, weight);

  @override
  String toString() =>
      'SortResult(vs: $vs, barycenter: $barycenter, weight: $weight)';
}

SortResult sort(List<Entry> entries, bool biasRight) {
  final (:matched, :unmatched) = entries.partition((e) => e.barycenter != null);

  final sortable = matched;
  final unsortable = unmatched..sort((a, b) => b.i - a.i);

  final vs = <List<String>>[];
  double sum = 0;
  double weight = 0;
  int vsIndex = 0;

  sortable.sort(_compareWithBias(biasRight));

  vsIndex = _consumeUnsortable(vs, unsortable, vsIndex);

  for (var entry in sortable) {
    vsIndex += entry.vs.length;
    vs.add(entry.vs);
    sum += entry.barycenter! * entry.weight!;
    weight += entry.weight!;
    vsIndex = _consumeUnsortable(vs, unsortable, vsIndex);
  }

  final result = SortResult(vs: vs.flattened.toList());

  if (weight > 0) {
    return SortResult(
      vs: result.vs,
      barycenter: sum / weight,
      weight: weight,
    );
  }

  return result;
}

int _consumeUnsortable(
    List<List<String>> vs, List<Entry> unsortable, int index) {
  while (unsortable.isNotEmpty && unsortable.last.i <= index) {
    vs.add(unsortable.removeLast().vs);
    index++;
  }
  return index;
}

Comparator<Entry> _compareWithBias(bool bias) {
  return (Entry entryV, Entry entryW) {
    if (entryV.barycenter! < entryW.barycenter!) return -1;
    if (entryV.barycenter! > entryW.barycenter!) return 1;
    return bias ? entryW.i - entryV.i : entryV.i - entryW.i;
  };
}

extension FlattenList<T> on List<List<T>> {
  Iterable<T> get flattened => expand((x) => x);
}

extension PartitionExtension<T> on List<T> {
  ({List<T> matched, List<T> unmatched}) partition(bool Function(T) predicate) {
    final matched = <T>[];
    final unmatched = <T>[];

    for (var item in this) {
      (predicate(item) ? matched : unmatched).add(item);
    }

    return (matched: matched, unmatched: unmatched);
  }
}

extension ListEquality<T> on List<T> {
  bool equals(List<T> other) {
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }
}
