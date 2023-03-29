require_relative 'common'

# Fail if versions in podpsec and in the main adapter class don't match
abort "Validation failed: #{podspec_version} != #{adapter_class_version}." unless podspec_version == adapter_class_version
