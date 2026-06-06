# libRangeMap Java Wrapper

This directory contains the first-party Java wrapper over the shared C ABI.

The wrapper depends only on the JDK and the native `librangemap_java.dll` built from the project sources.

## Local validation

```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
.\build.cmd
.\test.cmd
```

The build script uses the repository-owned Zig launcher to compile the JNI bridge.
The test script adds both native DLL directories to `PATH` so the JVM can load the JNI bridge and the shared C core on Windows.
