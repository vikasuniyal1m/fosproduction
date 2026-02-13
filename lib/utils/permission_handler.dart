import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.storage,
    Permission.location,
    Permission.notification,
  ].request();

  statuses.forEach((permission, status) {
    print('$permission : $status');
  });
}
