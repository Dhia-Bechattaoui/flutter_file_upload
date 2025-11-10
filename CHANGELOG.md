# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-11-10

### Added
- Added `skipFinalRequest` parameter to allow skipping the final verification request
- Enhanced example app with platform-agnostic file handling (works on web and native)
- Added comprehensive error messages explaining expected behavior

### Changed
- Web implementation now properly waits for all chunk uploads using `Future.wait()`
- Changed final verification request from HEAD to GET for consistency across platforms
- Example app now uses `httpbin.org/anything` for better testing compatibility

### Fixed
- Fixed web implementation race condition where final request fired before all chunks completed
- Fixed progress callback to prevent multiple 0-100% cycles when chunks complete out of order
- Improved error handling with user-friendly messages for network errors

## [0.0.1] - 2025-08-22

### Added
- Initial release: cross-platform uploader API with progress, chunking, and resume hook
- Supports iOS, Android, Web, Windows, macOS, Linux
- WASM compatible design

[Unreleased]: https://github.com/Dhia-Bechattaoui/flutter_file_upload/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Dhia-Bechattaoui/flutter_file_upload/releases/tag/v0.1.0
[0.0.1]: https://github.com/Dhia-Bechattaoui/flutter_file_upload/releases/tag/v0.0.1
