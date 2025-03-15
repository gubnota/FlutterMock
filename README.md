## Usage
Modify your existing Flutter plugins with the following code:
```swift
#if canImport(FlutterMock)
import FlutterMock
#else
import Flutter
#endif
```
Now you can log messages from your plugins, put breakpoints in your code, profile your code, do whatever you do in a native environment.

This way you can debug your plugins in Xcode without need to run Flutter which is way more faster.