package ir.ac.sharif.ce.cinetrack

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * FR-02's biometric clause needs this to be a **FragmentActivity**.
 *
 * `local_auth` shows Android's `BiometricPrompt`, which is a fragment and can
 * only be attached to a `FragmentActivity`. Under the default `FlutterActivity`
 * the plugin throws `no_fragment_activity` and the fingerprint prompt never
 * appears — the toggle would save a preference that could never be acted on.
 */
class MainActivity : FlutterFragmentActivity()
