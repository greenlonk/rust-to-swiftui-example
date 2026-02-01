# rust-to-swiftui-example
A minimal example showing how to call native Rust code from a SwiftUI iOS app using UniFFI.

The goal is not architecture perfection, but to demonstrate:
- how Rust is compiled into an iOS-compatible library
- how UniFFI generates Swift bindings
- how SwiftUI can synchronously call into Rust for CPU-heavy work

This repo intentionally keeps things simple and single-threaded.

## Structure

- `src/`  
  Rust library (`lib.rs`) with UniFFI exports

- `build.sh`  
  Builds Rust for iOS + simulator, generates Swift bindings, creates an `XCFramework`

- `uniffi-test/`  
  SwiftUI iOS app that links against the generated Rust framework

## Requirements

- Xcode (iOS SDK + simulator)
- Rust toolchain with iOS targets:
  - `aarch64-apple-ios`
  - `aarch64-apple-ios-sim`

## Build

Run from repo root:

```bash
bash build.sh
```

This generates:
- uniffi-test/Mobile.swift
- uniffi-test/Mobile.xcframework

Then open the Xcode project in uniffi-test/ and run the app.

## Notes
- Rust code is compiled natively and runs on the device.
- Calls are synchronous and run on the main thread.
- No async, no threading, no performance tricks.
- Do not expect magic. This is just FFI with nicer bindings.
