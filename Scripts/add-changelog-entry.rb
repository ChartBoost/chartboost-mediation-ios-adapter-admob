PODSPEC_PATH_PATTERN = "*.podspec"
PODSPEC_VERSION_REGEX = /^\s*spec\.version\s*=\s*'([0-9]+.[0-9]+.[0-9]+.[0-9]+.[0-9]+(?>.[0-9]+)?)'\s*$/
PODSPEC_PARTNER_AND_VERSION_REGEX = /spec\.dependency\s*'([^']+)',\s*'([\.0-9]+)'\s*$/
CHANGELOG_PATH = "CHANGELOG.md"

# Adds a new changelog entry using its current podspec version.
# Assumes that the partner SDK is the last dependency in the podspec file.

# Obtain the podspec file path
file = Dir.glob(PODSPEC_PATH_PATTERN).first
fail unless !file.nil?

# Obtain the adapter version, partner SDK name, and partner version, from the podspec
text = File.read(file)
adapter_version = text.match(PODSPEC_VERSION_REGEX).captures.first
partner_sdk, partner_version = text.scan(PODSPEC_PARTNER_AND_VERSION_REGEX).last
fail unless !adapter_version.nil? && !partner_sdk.nil? && !partner_version.nil?

# Read the changelog file
changelog = File.read(CHANGELOG_PATH)
fail unless !changelog.nil?

if changelog.include? "### #{adapter_version}"
  # Skip if entry already exists
  puts "skipped"
else
  # Otherwise add the new entry right before the last one
  changelog = changelog.sub("###", "### #{adapter_version}\n- This version of the adapters has been certified with #{partner_sdk} #{partner_version}.\n\n###")
  File.open(CHANGELOG_PATH, "w") { |file| file.puts changelog }
  puts "added"
end
