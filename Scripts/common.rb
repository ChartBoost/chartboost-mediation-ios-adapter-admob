# Common definitions used by other scripts.

PODSPEC_PATH_PATTERN = "*.podspec"
PODSPEC_VERSION_REGEX = /^\s*spec\.version\s*=\s*'([0-9]+.[0-9]+.[0-9]+.[0-9]+.[0-9]+(?>.[0-9]+)?)'\s*$/
PODSPEC_NAME_REGEX = /^\s*spec\.name\s*=\s*'([^']+)'\s*$/
PODSPEC_PARTNER_AND_VERSION_REGEX = /spec\.dependency\s*'([^']+)',\s*'([\.0-9]+)'\s*$/
CHANGELOG_PATH = "CHANGELOG.md"

# Returns the podspec contents as a string.
def read_podspec
  # Obtain the podspec file path
  file = Dir.glob(PODSPEC_PATH_PATTERN).first
  fail unless !file.nil?

  # Read the contents
  text = File.read(file)

  # Return value
  text
end

# Returns the podspec version value.
def podspec_version
  # Obtain the podspec
  text = read_podspec()

  # Obtain the adapter version from the podspec
  version = text.match(PODSPEC_VERSION_REGEX).captures.first
  fail unless !version.nil?

  # Return value
  version
end

# Returns the podspec version value.
def podspec_name
  # Obtain the podspec
  text = read_podspec()

  # Obtain the name from the podspec
  name = text.match(PODSPEC_NAME_REGEX).captures.first
  fail unless !name.nil?

  # Return value
  name
end

# Returns the podspec partner SDK name and partner version values.
def podspec_partner_sdk_name_and_version
  # Obtain the podspec
  text = read_podspec()

  # Obtain the partner SDK name and partner version from the podspec
  partner_sdk, partner_version = text.scan(PODSPEC_PARTNER_AND_VERSION_REGEX).last
  fail unless !partner_sdk.nil? && !partner_version.nil?

  # Return values
  return partner_sdk, partner_version
end

# Returns the changelog contents as a string.
def read_changelog
  # Read the changelog contents
  text = File.read(CHANGELOG_PATH)
  fail unless !text.nil?

  # Return value
  text
end

# Writes a string to the changelog file.
def write_changelog(text)
  File.open(CHANGELOG_PATH, "w") { |file| file.puts text }
end
