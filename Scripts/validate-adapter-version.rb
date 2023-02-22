require_relative 'common'

ADAPTER_VERSION_REGEX = /^\s*let adapterVersion\s*=\s*"([^"]+)".*$/

# Obtain the partner name
partner_name = podspec_name().delete_prefix "ChartboostMediationAdapter"

# Obtain the Adapter file path
file = Dir.glob("./Source/#{partner_name}Adapter.swift").first
fail unless !file.nil?

# Obtain the adapter version from the Adapter file
text = File.read(file)
adapter_version = text.match(ADAPTER_VERSION_REGEX).captures.first
fail unless !adapter_version.nil?

# Output match result to console
puts podspec_version == adapter_version
