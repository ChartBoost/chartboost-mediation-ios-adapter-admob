# Validates a partner version string checking it is well-formed.

require_relative 'common'

PARTNER_VERSION_REGEX = /^(?>~> )?[0-9]+(?>\.[0-9]+){1,}$/

# Parse the version string from the arguments
abort "Missing argument. Requires: version string." unless ARGV.count == 1
version = ARGV[0]

# Fail if the version is not a semantic version with an optional CocoaPods optimistic operator.
abort "Validation failed: #{version} is not well-formed." unless version.match?(PARTNER_VERSION_REGEX)
