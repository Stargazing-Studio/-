// Platform-conditional export: use SharedPreferences on IO platforms, localStorage on Web.
export 'local_cache_web.dart' if (dart.library.io) 'local_cache_prefs.dart';
