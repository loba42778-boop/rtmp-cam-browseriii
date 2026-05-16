# RTMP Cam Browser

A custom Android browser with a built-in **virtual webcam** fed from an RTMP stream.
The injected JavaScript overrides `navigator.mediaDevices.getUserMedia` inside the
WebView so any website that asks for a camera receives the decoded RTMP video as
a real `MediaStream`.

---

## Get an APK without installing Android Studio

This repo ships with a GitHub Actions workflow that builds **debug and release
APKs on every push** and attaches them to a Release whenever you push a tag.

### One-time setup

1. Create a new empty GitHub repo (public or private).
2. From this folder:
   ```bash
   git init && git add . && git commit -m "initial import"
   git branch -M main
   git remote add origin git@github.com:<you>/<repo>.git
   git push -u origin main
   ```
3. Open the **Actions** tab on GitHub — the **Build APK** workflow runs automatically.

### Download the APK

- **From any build:** Actions → latest run → *Artifacts* → `RtmpCamBrowser-debug`.
- **From a tagged release:**
  ```bash
  git tag v1.0.0 && git push origin v1.0.0
  ```
  GitHub publishes a Release with both `app-debug.apk` and `app-release-unsigned.apk` attached.
- **Manually trigger a build:** Actions → *Build APK* → *Run workflow*.

### Install on your phone

1. Transfer the `.apk` to the device (USB, Drive, email).
2. Enable *Install unknown apps* for your file manager.
3. Tap the APK to install.

> The debug APK is signed with the standard Android debug key, so it installs as-is.
> The release APK is **unsigned** — sign it with `apksigner` or your own keystore
> before publishing to the Play Store.

---

## Build locally (optional, if you do install Android Studio)

1. Android Studio Hedgehog or newer (AGP 8.5+, JDK 17).
2. `File → Open…` this folder, let Gradle sync (JitPack pulls RootEncoder).
3. Plug in an Android 7.0+ device with USB debugging and press Run ▶.

Or from the command line:
```bash
./gradlew :app:assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

---

## How it works

```
RTMP server ──► RtmpService (RootEncoder, H.264/AAC decode)
                    │
                    ▼
              SurfaceTexture
                    │ glReadPixels → JPEG (~15 fps)
                    ▼
           LocalBridgeServer (127.0.0.1)
                    │ MJPEG over HTTP
                    ▼
              WebView page ──► inject.js
                    │
                    ▼  canvas.captureStream()
       getUserMedia({video:true}) resolves with the fake stream
```

## Features

- Mobile dark UI, URL bar, back/fwd/reload, progress, fullscreen video.
- RTMP URL input with start/stop, status dot, recent-streams history (persisted).
- Toggle between **RTMP virtual camera** and **real device camera**.
- `getUserMedia` / `enumerateDevices` / legacy `webkitGetUserMedia` override.
- Microphone passthrough.
- Custom User-Agent (menu → "Set custom User-Agent"); realistic mobile Chrome UA by default.
- Script injection at **document start** via `WebViewCompat.addDocumentStartJavaScript`, plus fallbacks at `onPageStarted`/`onPageFinished`.
- Cookies + third-party cookies enabled for WebRTC sites.
- Foreground service keeps RTMP alive when the screen is off.
- Anti-fingerprinting: realistic `getSettings()`/`getCapabilities()`, plausible label, frame-time jitter.

## Honest limitations

- **Canvas-based virtual cameras are detectable.** OmeTV/Omegle routinely fingerprint MediaStreams; expect to iterate.
- **`FrameGrabber` uses `glReadPixels`** — simple but CPU-heavy. Port to `ImageReader`/HardwareBuffer for 30 fps@1080p.
- **RootEncoder API drifts between minor versions.** If Gradle pulls a newer release with different `ConnectChecker` signatures, update `RtmpService.kt`.
- **HTTPS pages with strict CSP** may block the `http://127.0.0.1` MJPEG endpoint. Loopback is a secure context in Chromium so it usually works; `usesCleartextTraffic=true` is set.
- **RTMP audio is stubbed** — mic is passed through. Wire AAC → WebSocket PCM → AudioContext if you need RTMP audio.

## Quick test

1. Push a stream to any RTMP server (OBS → `rtmp://your.server/live/key`).
2. Open the app, paste the playback URL, tap **Start stream**.
3. Browse to `https://webrtc.github.io/samples/src/content/getusermedia/gum/` → *Open camera*.
4. You should see your RTMP feed instead of the device camera.
