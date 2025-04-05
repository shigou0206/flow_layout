/// 简单的双向链表实现
class ListNode<T> {
  T value;
  ListNode<T>? prev;
  ListNode<T>? next;

  ListNode(this.value);
}

/// 简单的列表队列实现，用于greedyFAS算法
class ListQueue<T> {
  ListNode<T>? _head;
  ListNode<T>? _tail;
  int _length = 0;

  ListQueue();

  /// 获取列表长度
  int get length => _length;

  /// 检查列表是否为空
  bool get isEmpty => _length == 0;

  /// 将元素添加到队列末尾
  void enqueue(T value) {
    final node = ListNode<T>(value);
    if (_head == null) {
      _head = node;
      _tail = node;
    } else {
      node.prev = _tail;
      _tail!.next = node;
      _tail = node;
    }
    _length++;
  }

  /// 从队列头部移除并返回元素
  T? dequeue() {
    if (_head == null) return null;
    
    final value = _head!.value;
    _head = _head!.next;
    
    if (_head == null) {
      _tail = null;
    } else {
      _head!.prev = null;
    }
    
    _length--;
    return value;
  }
} 