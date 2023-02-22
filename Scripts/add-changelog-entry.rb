require_relative 'common'

# Adds a new changelog entry using its current podspec version.
# Assumes that the partner SDK is the last dependency in the podspec file.

# Obtain the adapter version, partner SDK name, and partner version, from the podspec
adapter_version = podspec_version()
partner_sdk, partner_version = podspec_partner_sdk_name_and_version()

# Read the changelog file
changelog = read_changelog()

if changelog.include? "### #{adapter_version}"
  # Skip if entry already exists
  puts "skipped"
else
  # Otherwise add the new entry right before the last one
  changelog = changelog.sub("###", "### #{adapter_version}\n- This version of the adapters has been certified with #{partner_sdk} #{partner_version}.\n\n###")
  write_changelog(changelog)
  puts "added"
end
