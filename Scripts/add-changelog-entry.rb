# Adds a new changelog entry using its current podspec version.
# Assumes that the partner SDK is the last dependency in the podspec file.

require_relative 'common'

# Parse the version strings from the arguments
abort "Missing argument. Requires: adapter version string, partner version string." unless ARGV.count == 2
adapter_version = ARGV[0]
partner_version = ARGV[1]

# Strip the cocoapods optimistic operation from the partner version if it exists
partner_version = partner_version.delete_prefix('~> ')

# Obtain the partner SDK name from the podspec
partner_sdk_name = podspec_partner_sdk_name()

# Read the changelog file
changelog = read_changelog()

# Add the new entry right before the last one, if the entry does not already exist for this version
if !changelog.include? "### #{adapter_version}"
  changelog = changelog.sub("###", "### #{adapter_version}\n- This version of the adapters has been certified with #{partner_sdk_name} #{partner_version}.\n\n###")
  write_changelog(changelog)
end
