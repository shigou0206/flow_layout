/// 用于安全更新节点或边属性的工具函数
class SafeGraphUpdate {
  /// 安全设置节点或边属性值
  /// 此函数会尝试保持原始值的类型，避免类型转换错误
  static void setProperty(Map<String, dynamic> properties, String key, dynamic value) {
    // 如果key不存在，直接设置
    if (!properties.containsKey(key)) {
      properties[key] = value;
      return;
    }
    
    // 获取当前值及其类型
    final currentValue = properties[key];
    
    // 如果当前值和新值类型相同，直接设置
    if (currentValue == null || value == null || currentValue.runtimeType == value.runtimeType) {
      properties[key] = value;
      return;
    }
    
    // 根据当前值的类型进行转换
    if (currentValue is int) {
      properties[key] = value is double ? value.toInt() : value;
    } else if (currentValue is double) {
      properties[key] = value is int ? value.toDouble() : value;
    } else if (currentValue is String) {
      properties[key] = value.toString();
    } else if (currentValue is bool) {
      // 布尔值转换
      if (value is String) {
        properties[key] = value.toLowerCase() == 'true';
      } else if (value is num) {
        properties[key] = value != 0;
      } else {
        properties[key] = value == true;
      }
    } else if (currentValue is List) {
      // 列表处理
      if (value is List) {
        properties[key] = value;
      }
    } else if (currentValue is Map) {
      // Map处理
      if (value is Map) {
        properties[key] = value;
      }
    } else {
      // 默认情况下直接设置值
      properties[key] = value;
    }
  }
  
  /// 安全获取数值属性，确保返回指定类型
  static double getDouble(Map<String, dynamic> properties, String key, [double defaultValue = 0.0]) {
    final value = properties[key];
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return defaultValue;
      }
    }
    return defaultValue;
  }
  
  /// 安全获取整数属性
  static int getInt(Map<String, dynamic> properties, String key, [int defaultValue = 0]) {
    final value = properties[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return defaultValue;
      }
    }
    return defaultValue;
  }
  
  /// 安全获取布尔属性
  static bool getBool(Map<String, dynamic> properties, String key, [bool defaultValue = false]) {
    final value = properties[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return defaultValue;
  }
  
  /// 安全获取字符串属性
  static String getString(Map<String, dynamic> properties, String key, [String defaultValue = '']) {
    final value = properties[key];
    if (value == null) return defaultValue;
    return value.toString();
  }
} 