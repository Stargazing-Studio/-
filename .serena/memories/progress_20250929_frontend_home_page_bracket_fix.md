时间：2025-09-29 00:10Z
任务：修复 home_page.dart 尾部括号/方括号残留导致的 Dart 语法错误（Expected a declaration, got ']' 等）。
触发：正则插入后在 _ErrorPane 结束处遗留了 UI 结构收尾片段（], ), ), ), ); } }），污染到顶层作用域。
变更文件：
- app/lib/src/features/home/presentation/home_page.dart
变更摘要：
- 删除 _ErrorPane 类后的多余 token 片段，保留正确的类闭合与后续 _CommandBar 定义。
验证：
- 语法结构检查通过（本地静态检查受限于无 Dart SDK；建议在工程环境跑 `flutter analyze`）。
回滚：
- 如需回滚，可恢复上述文件到变更前版本；但会重新出现同类语法错误。