# Validates a partner version string checking it is well-formed.

require_relative 'common'

PARTNER_VERSION_REGEX = /^(?>~> )?[0-9]+(?>\.[0-9]+){1,}$/

# Parse the version string from the arguments
abort "Missing argument. Requires: version string." unless ARGV.count == 1
version = ARGV[0]

# Check that the version is a semantic version with an optional CocoaPods optimistic operator.
exit 1 unless version.match?(PARTNER_VERSION_REGEX)
