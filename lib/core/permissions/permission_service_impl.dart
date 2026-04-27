import 'package:permission_handler/permission_handler.dart';
import 'package:prijavko/core/permissions/permission_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_service_impl.g.dart';

class PermissionServiceImpl implements PermissionService {
  @override
  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  Future<bool> isCameraGranted() async => Permission.camera.isGranted;

  @override
  Future<bool> isCameraPermanentlyDenied() async =>
      Permission.camera.isPermanentlyDenied;

  @override
  Future<void> openSettings() async => openAppSettings();
}

// Tests override with FakePermissionService (test/fakes/fake_permission_service.dart).
@riverpod
PermissionService permissionService(Ref ref) => PermissionServiceImpl();
