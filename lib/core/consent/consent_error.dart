import 'package:prijavko/core/consent/consent_state.dart';

// WHY: ConsentError is a standalone sealed type in core/consent/ rather than
// a variant of AppError. AppError is the cross-feature vocabulary for
// repository/data calls; consent errors live entirely inside core/consent/
// and never bubble to repositories. Keeping them separate avoids polluting
// the shared sealed hierarchy. JIT.
sealed class ConsentError {
  const ConsentError();
}

final class ConsentFormError extends ConsentError {
  const ConsentFormError(this.reason);

  final ConsentFailureReason reason;
}
