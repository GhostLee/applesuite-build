#!/bin/bash
set -euo pipefail
umask 077
output="$RUNNER_TEMP/private-output"
cd "$RUNNER_TEMP/private-source"
xcodebuild -version > "$output/toolchain.txt" 2>&1
swift --version >> "$output/toolchain.txt" 2>&1
if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen > "$output/xcodegen-install.log" 2>&1
fi
swift test > "$output/swift-test.log" 2>&1
xcodegen generate --spec project.yml > "$output/xcodegen.log" 2>&1
xcodebuild \
  -project PCSuite.xcodeproj \
  -scheme PCSuite \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$PWD/build/PCSuite.xcarchive" \
  -derivedDataPath "$PWD/build/DerivedData" \
  -resultBundlePath "$PWD/build/Archive.xcresult" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  archive > "$output/xcodebuild.log" 2>&1
mkdir -p build/ipa/Payload
ditto build/PCSuite.xcarchive/Products/Applications/PCSuite.app build/ipa/Payload/PCSuite.app
cd build/ipa
ditto -c -k --keepParent Payload "$output/AppleSuite-unsigned.ipa"
cd "$output"
shasum -a 256 AppleSuite-unsigned.ipa > IPA-SHA256SUMS
unzip -t AppleSuite-unsigned.ipa > ipa-integrity.log 2>&1
printf 'Tests and unsigned archive succeeded.\n' > result.txt
