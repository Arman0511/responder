import 'package:flutter_test/flutter_test.dart';
import 'package:responder/app/app.locator.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('AdminSignupViewModel Tests -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());
  });
}
