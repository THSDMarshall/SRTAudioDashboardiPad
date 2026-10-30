# SRT Audio Dashboard — Native iPad Prototype

This is a **native SwiftUI/AVAudioEngine hardware test**, not the finished sleigh dashboard. It is separate from the existing browser dashboard.

## What this build tests
- iPadOS AVAudioSession `.playAndRecord` route, showing physical input and output names.
- 440 Hz test tone through the **current iPadOS audio output**.
- Microphone permission and a live input level meter.
- No software microphone monitoring; use UMC22 Direct Monitor if desired.

The app does **not** force USB routing; it shows what iPadOS selects. If the route says built-in speaker despite the connected UMC22, we will need to investigate native audio-session configuration before proceeding.

## Building without a Mac
1. Create a **new** GitHub repository, e.g. `SRT-Audio-Dashboard-iPad` (do not replace the web repo).
2. Upload **all files including the hidden `.github/workflows/build.yml`** while preserving the directory layout. GitHub's web interface can create hidden folders, or upload a Git repository from another machine.
3. GitHub Actions → **Build native iPad prototype** → Run workflow. The workflow uses a hosted Mac to install XcodeGen, generate the `.xcodeproj`, and compile an **unsigned iPad Simulator build**.
4. A successful green build validates the project compiles; **it cannot be installed on a physical iPad**.

## Signing and installing later
Apple Developer Program approval is only one step. For a real device build, we must configure an App ID, an Apple Distribution certificate, a provisioning profile, and an App Store Connect app record. We can then extend GitHub Actions to produce a **signed `.ipa`**, upload it to App Store Connect, and install via TestFlight. App Store Connect/TestFlight setup and any Apple review requirements still apply. Do **not** upload signing secrets to the repository; use GitHub Actions encrypted secrets.

## Hardware test procedure
1. Connect the UMC22 to the iPad using your existing adapter. Connect its outputs to the amplifier at low volume.
2. Launch the native app, press **Start audio engine**, grant mic permission.
3. Check that the route lists `USB Audio CODEC` (or the equivalent USB device) as **output** and ideally **input**.
4. Press **Play test tone** and verify sound physically comes from UMC22 outputs, not the iPad speaker.
5. Speak into the mic on input 1 and check the input meter responds. If it doesn't, note the input route.
6. Send us the route text and results. Only then implement music queue, pads, auto-ducking and Sleigh Stop.

## Notes
- Minimum deployment target: iPadOS 16.
- Bundle ID in `project.yml` is a placeholder (`uk.co.stocktonroundtable.SRTAudioDashboard`); confirm ownership/uniqueness when registering the App ID.
- The first GitHub Actions job builds for **Simulator only**, because developer signing credentials are not yet available.
- Apple Developer nonprofit fee waiver and organisation enrolment remain subject to Apple's approval.
