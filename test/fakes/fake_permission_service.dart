import 'package:prijavko/core/permissions/permission_service.dart';

// WHY: permission_handler uses static platform-channel methods — untestable
// without a device. This fake follows FakeConsentService / FakeSecurityService
// patterns: scripted return values + call tracking for "was requestCamera
// called?" assertions.
class FakePermissionService implements PermissionService {
  FakePermissionService({
    required bool grantCamera,
    bool permanentlyDenied = false,
  }) : _grantCamera = grantCamera,
       _permanentlyDenied = permanentlyDenied;

  final bool _grantCamera;
  final bool _permanentlyDenied;

  var requestCameraCallCount = 0;

  @override
  Future<bool> requestCamera() async {
    requestCameraCallCount++;
    return _grantCamera;
  }

  @override
  Future<bool> isCameraGranted() async => _grantCamera;

  @override
  Future<bool> isCameraPermanentlyDenied() async => _permanentlyDenied;

  @override
  Future<void> openSettings() async {}
}
