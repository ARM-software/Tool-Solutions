# Changelog
All significant changes to the TensorFlow container builds in
docker/tensorflow-lite-aarch64 will be noted in this log.

## 2023-05-31

### Added
- TensorFlow Lite builds with external delegate and telemetry support

### Changed
- Updates Compute Library to 23.05.
- Updates ArmNN to 23.05
- Updates Tensorflow Lite to 2.12
- Updates Flatbuffers to 2.0.7

### Removed
- Removed spin wait scheduler from Compute Library
- Removed broken links in README.md file

### Fixed
- Correct invocation to ExecuteNetwork
