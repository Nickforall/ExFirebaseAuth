# Changelog

## 0.4.1

- Add config value to prevent KeyStore from crashing (@lucasavila00 #19)

## 0.4.0

- Support Elixir 1.10
- Added a pluggable KeySource for testing of library
- Added more comprehensive errors for invalid tokens
- Added tests

## 0.3.1

- Fixed an issue where token store was never refreshed

## 0.2.1

- Tweaked the refresh interval of fetching private keys from Google

## 0.2.0

- Improve performance of fetching public keys by storing them in an ETS table
- Added `ExFirebaseAuth.Mock` for writing integration tests with ID tokens

## 0.1.0 Initial Release

- 🔥
