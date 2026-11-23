#!/bin/bash
# Prints the UDID of an iPhone simulator on the newest installed iOS runtime, creating one if
# the runner image has none. Used by CI so the workflow doesn't hard-code a device name that a
# given runner image may not ship.
set -euo pipefail

find_udid() {
  xcrun simctl list devices available -j | python3 -c '
import json, sys

def version_key(runtime):
    digits = runtime.rsplit("iOS-", 1)[-1].split("-")
    return tuple(int(d) for d in digits if d.isdigit())

devices = json.load(sys.stdin)["devices"]
for runtime in sorted((r for r in devices if ".iOS-" in r), key=version_key, reverse=True):
    for device in devices[runtime]:
        if device["name"].startswith("iPhone") and device.get("isAvailable", True):
            print(device["udid"])
            sys.exit(0)
sys.exit(1)
'
}

if udid=$(find_udid); then
  echo "$udid"
  exit 0
fi

echo "No available iPhone simulator found; creating one." >&2
runtime=$(xcrun simctl list runtimes available -j | python3 -c '
import json, sys

def version_key(runtime):
    return tuple(int(p) for p in runtime["version"].split(".") if p.isdigit())

runtimes = [r for r in json.load(sys.stdin)["runtimes"] if r["identifier"].split(".")[-1].startswith("iOS-")]
if not runtimes:
    sys.exit(1)
print(max(runtimes, key=version_key)["identifier"])
') || { echo "No iOS simulator runtime installed on this runner." >&2; xcrun simctl list runtimes >&2; exit 1; }

xcrun simctl create "CI iPhone" "com.apple.CoreSimulator.SimDeviceType.iPhone-16" "$runtime"
