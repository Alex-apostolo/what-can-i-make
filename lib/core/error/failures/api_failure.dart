import 'failure.dart';

/// Failure related to API limits
class ApiLimitFailure extends Failure {
  const ApiLimitFailure(super.message, [super.error]);
}
