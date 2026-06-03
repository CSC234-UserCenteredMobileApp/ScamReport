import 'package:integration_test/integration_test_driver.dart';

// Standard shim so `flutter drive --driver=test_driver/integration_test.dart`
// can run the integration_test/ suite on web (chromedriver) and devices.
Future<void> main() => integrationDriver();
