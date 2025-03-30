
import 'package:file/file.dart';

extension FileSystemEntityX on FileSystemEntity {

  String get libPath {
    if (!path.contains('/lib')) {
      return path;
    }
    return path.substring(path.indexOf('/lib') + 1);
  }
}
