# 代码风格与约定
- Flutter：`analysis_options.yaml` 继承 `flutter_lints`，强制 `prefer_single_quotes` 与 `always_use_package_imports`；使用 Riverpod 状态管理 + GoRouter，Widget 以中文命名文本，注意保持暗色主题一致。
- 数据模型使用 Freezed/json_serializable（依赖已在 pubspec，尚未生成代码），命名遵循小驼式（变量/函数）与大驼式（类）。
- 后端：FastAPI + Pydantic v2，使用类型注解与 `Field` 约束；路由函数简单返回数据模块常量，遵守 PEP8；测试采用 pytest + `fastapi.testclient`。
- 文档与注释需要中文描述，遵循仓库指南。