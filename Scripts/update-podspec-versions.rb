# Updates the podspec by replacing the adapter and partner versions.

require_relative 'common'

# Parse the version strings from the arguments
abort "Missing argument. Requires: adapter version string, partner version string." unless ARGV.count == 2
adapter_version = ARGV[0]
partner_version = ARGV[1]

# Obtain the partner SDK name from the podspec
partner_sdk_name = podspec_partner_sdk_name()

# Read the podspec file
podspec = read_podspec()

# Replace the adapter version string in the podspec (capture group 2), keeping everything else the same (capture groups 1 and 3)
podspec = podspec.sub(PODSPEC_VERSION_REGEX, "\\1#{adapter_version}\\3")

# Replace the partner SDK version string in the podspec
partner_sdk_version_regex = /(spec\.dependency\s*'#{partner_sdk_name}').*$/
podspec = podspec.sub(partner_sdk_version_regex, "\\1, '#{partner_version}'")

# Write the changes
write_podspec(podspec)
