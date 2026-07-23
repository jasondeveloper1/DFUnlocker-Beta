/// How the toolkit resolves an attached handset.
enum DeviceLinkStrategy {
  /// Poll the host USB subsystem (libimobiledevice, adb, IORegistry, PnP).
  hardware,

  /// Use a provisioned session when no physical link is available.
  session,
}
