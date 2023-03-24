# Updates the main PartnerAdapter class by replacing the adapter version string.

require_relative 'common'

# Parse the new version string from the arguments
abort "Missing argument. Requires: version string." unless ARGV.count == 1
new_version = ARGV[0]

# Read the main adapter class file
adapter_class = read_adapter_class()

# Replace the partner adapter version string (capture group 2), keeping everything else the same (capture groups 1 and 3)
adapter_class = adapter_class.sub(ADAPTER_CLASS_VERSION_REGEX, "\\1#{new_version}\\3")

# Write the changes
write_adapter_class(adapter_class)
