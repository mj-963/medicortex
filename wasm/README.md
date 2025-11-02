# MediCortex WASM Files

This repository hosts WebAssembly files for the [MediCortex](https://github.com/mj-963/medicortex) application.

## Purpose

These files are required for the Drift database to work on web platforms. They are hosted separately because:

- **Appwrite Sites** (where the main app is deployed) doesn't support custom HTTP headers
- **WASM files require** `Content-Type: application/wasm` MIME type
- **GitHub Pages** automatically serves WASM files with correct MIME types

## Files

- **sqlite3.wasm** (690 KB) - SQLite3 WebAssembly binary used by Drift
- **drift_worker.js** (347 KB) - Drift web worker for database operations
- **index.html** - Simple index page listing available files

## Usage

These files are loaded by the MediCortex app via:

```dart
web: DriftWebOptions(
  sqlite3Wasm: Uri.parse('https://flutterfanatic.github.io/medicortex-wasm-files/sqlite3.wasm'),
  driftWorker: Uri.parse('https://flutterfanatic.github.io/medicortex-wasm-files/drift_worker.js'),
)
```

## Deployment

This repo is deployed to GitHub Pages at:
- https://flutterfanatic.github.io/medicortex-wasm-files/

The WASM files are publicly accessible and served with proper CORS headers and MIME types.

## Technical Details

**Required Headers:**
- `Content-Type: application/wasm` (for .wasm files)
- `Content-Type: application/javascript` (for .js files)
- CORS enabled for cross-origin requests

GitHub Pages handles these automatically.

## License

These files are part of the MediCortex project. See the main repository for license information.
