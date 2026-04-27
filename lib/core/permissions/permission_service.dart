// WHY interface seam: permission_handler uses static methods backed by platform
// channels. Direct widget calls make unit/widget tests impossible without a
// real device. This mirrors ConsentService / SecurityService from Stories
// 1.3–1.4. Tests override permissionServiceProvider with FakePermissionService.
abstract class PermissionService {
  Future<bool> requestCamera();
  Future<bool> isCameraGranted();
  Future<bool> isCameraPermanentlyDenied();
  Future<void> openSettings();
}
