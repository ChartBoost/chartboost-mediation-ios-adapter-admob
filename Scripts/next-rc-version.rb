PODSPEC_PATH_PATTERN = "*.podspec"
PODSPEC_VERSION_REGEX = /^\s*spec\.version\s*=\s*'([0-9]+.[0-9]+.[0-9]+.[0-9]+.[0-9]+(?>.[0-9]+)?)'\s*$/

# Obtain the podspec file path
file = Dir.glob(PODSPEC_PATH_PATTERN).first
fail unless !file.nil?

# Obtain the adapter version from the podspec
text = File.read(file)
version = text.match(PODSPEC_VERSION_REGEX).captures.first
fail unless !version.nil?

# Generate the filter pattern
filter_pattern = "#{version}-rc."

# Obtain the current release candidate build number of this branch.
# This command:
# 1. Fetch all tags from origin
# 2. Lists all tags in reverse version order
# 3. Chooses the first tag
# 4. Removes the filter pattern prefix, leaving only the current build number.
current_build_string = %x( git fetch origin --tags --prune --prune-tags --force && git tag -l --sort=-v:refname '#{filter_pattern}*' | head -1 | sed "s/^#{filter_pattern}//" )

# In the event that there were no tags for this branch, default to 0.
current_build_string = "0" if current_build_string.nil? || current_build_string.empty?

# Increment the build number.
build_number = current_build_string.to_i + 1

# Output to console
puts "#{filter_pattern}#{build_number}"
