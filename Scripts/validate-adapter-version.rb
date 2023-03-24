require_relative 'common'

# Exit with match result (0 = success, 1 = failure)
exit podspec_version == adapter_class_version ? 0 : 1
