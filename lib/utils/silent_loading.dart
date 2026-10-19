/// Silent loading: show cached content immediately, refresh in background.
class SilentLoading {
  /// True only when a full-page blocking spinner should show.
  static bool blockUi({required bool isLoading, required bool hasContent}) =>
      isLoading && !hasContent;
}
