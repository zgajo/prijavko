import 'dart:typed_data';

import 'package:prijavko/core/security/aes_gcm_helper.dart';
import 'package:prijavko/core/security/security_service.dart';

// Fixed 32-byte key so unit tests never touch flutter_secure_storage.
final _fakeKey = Uint8List.fromList(List.filled(32, 0x42));

class FakeSecurityService extends SecurityService {
  FakeSecurityService() : super();

  final AesGcmHelper _fakeHelper = AesGcmHelper(_fakeKey);

  @override
  Future<void> init() async {
    // No-op — avoids Keystore / platform channel access in unit tests.
  }

  @override
  AesGcmHelper get encryptionHelper => _fakeHelper;
}
