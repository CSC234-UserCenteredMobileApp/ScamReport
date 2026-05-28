// Global test config. Runs before every `flutter test` invocation in this
// package.
//
// - Disables GoogleFonts' runtime HTTP fetch. CI is sandboxed and has no
//   network access; without this the font loader throws on every test that
//   pumps the app theme. With it disabled the loader falls back to the
//   ambient font, which is what the golden tests render against.
import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
