# Validates that an adapter and partner version strings match.

# Parse the version strings from the arguments
abort "Missing argument. Requires: adapter version string, partner version string." unless ARGV.count == 2
adapter_version = ARGV[0]
partner_version = ARGV[1]

# Strip the Chartboost Mediation SDK digit and the adapter build digits
partner_digits_in_adapter_version = adapter_version.split('.')[1...-1].join('.')

# Strip the cocoapods optimistic operation from the partner version if it exists
partner_version = partner_version.delete_prefix('~> ')

# Fail if versions don't match
abort "Validation failed: #{partner_digits_in_adapter_version} != #{partner_version}." unless partner_digits_in_adapter_version == partner_version
