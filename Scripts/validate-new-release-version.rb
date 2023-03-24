# Validates an adapter version string, checking it is well-formed and that it hasn't been released yet.

require_relative 'common'

ADAPTER_VERSION_REGEX = /^[0-9]+(?>\.[0-9]+){4,5}$/

# Parse the new version string from the arguments
abort "Missing argument. Requires: version string." unless ARGV.count == 1
new_version = ARGV[0]

# Check that the version is 5 or 6 digits separated by dots.
exit 1 unless new_version.match?(ADAPTER_VERSION_REGEX)

# Check if a tag for that version already exists in the remote
# This command:
# 1. Fetches all tags from origin
# 2. Lists all tags that match the new version string
# 3. Returns the new version string if the corresponding tag was found, empty string otherwise
version_tag_check = %x( git fetch origin --tags --prune --prune-tags --force && git tag -l "#{new_version}" | head -1)

# Exit with result: 0 (success) if tag not found, 1 (failure) otherwise.
exit version_tag_check.empty? ? 0 : 1
