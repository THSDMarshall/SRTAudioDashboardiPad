# TestFlight release workflow (prepare now, activate after Apple approval)

The existing `.github/workflows/build.yml` validates every commit to `main`. The new `.github/workflows/testflight.yml` runs **only when manually triggered** under Actions > Release to TestFlight > Run workflow. A successful GitHub build is not an automatic TestFlight release.

## Apple setup after approval

1. In Apple Developer, confirm the team ID and register explicit App ID `uk.co.stocktonroundtable.SRTAudioDashboard`. If Apple requires another bundle identifier, change both `project.yml` and the ExportOptions plist in the workflow.
2. Create an **Apple Distribution** certificate and export the certificate **with its private key** as a password-protected `.p12` file. This usually requires a Mac or a carefully managed remote Mac/CI signing setup. Membership alone does not create the private key. Do not commit it.
3. Create an **App Store Connect distribution provisioning profile** for that bundle ID and certificate; download `.mobileprovision`.
4. In App Store Connect, create the iPad app with the same bundle ID, provide required app metadata and complete compliance details. Generate an App Store Connect API key with permission to upload builds (App Manager or appropriate role); save the `.p8` once, along with its key ID and issuer ID.
5. In GitHub repository Settings > Environments, create `testflight` (optionally require approval). In Settings > Secrets and variables > Actions, add these **repository secrets** (or environment secrets attached to `testflight`):
   - `APPLE_TEAM_ID`: 10-character Apple team identifier.
   - `APPLE_CERTIFICATE_P12_BASE64`: Base64-encoded binary `.p12` certificate including private key.
   - `APPLE_CERTIFICATE_PASSWORD`: password for the `.p12`.
   - `APPLE_PROVISIONING_PROFILE_BASE64`: Base64-encoded `.mobileprovision`.
   - `APP_STORE_CONNECT_API_KEY_ID`: API key ID.
   - `APP_STORE_CONNECT_ISSUER_ID`: API issuer ID.
   - `APP_STORE_CONNECT_API_KEY_P8_BASE64`: Base64-encoded `.p8` API private key.

Encode *file contents* (not filenames) as Base64. Do not paste certificate or API private keys into ChatGPT, GitHub source files, issues or logs. Secrets are injected only at runtime.

6. Run Actions > Release to TestFlight > Run workflow. The workflow increments build number using `github.run_number`, archives, exports an IPA and uploads it to App Store Connect. Apple must process the upload before the build appears in TestFlight. Configure internal testers; external testers may require Beta App Review. TestFlight builds expire after 90 days.

## Known constraints

- This is a **starter** workflow. It has not been executed against a real Apple Developer account. Apple/Xcode signing, keychain import and export options may need adjustment during the first signed run.
- The native prototype is only a UMC22 hardware diagnostic, **not** the full music dashboard yet.
- A GitHub Actions macOS runner can compile the app without a local Mac, but generating/exporting an Apple Distribution private key and initial signing credentials may still require temporary access to a Mac or a managed cloud signing service.
- Releasing every commit is possible later by changing the trigger, but manual releases are safer for live Santa Sleigh use.
