enum CapturePreference {
  // User granted camera; Epic 4 defaults to MRZ-first capture.
  live,
  // User denied/skipped camera; Epic 4 surfaces manual entry as primary path.
  manualOnly,
}
