import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs the app with debug logging disabled in release builds.
void runWithReleaseConfig(void Function() body) {
  if (kReleaseMode) {
    debugPrint = (_, {int? wrapWidth}) {};
    runZoned(
      body,
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, ____) {},
      ),
    );
    return;
  }
  body();
}
