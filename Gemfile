source "https://rubygems.org"
gemspec
gem "rspec", "~> 3.13"
gem "rake", "~> 13.0"
gem "standard", "~> 1.0"
gem "bundler-audit", "~> 0.9"
# Exercise the optional Rails adapter through a real controller. The glibc 2.28
# Linux build skips this group: Nokogiri's Linux binaries need glibc 2.29+.
group :rails do
  gem "actionpack", ">= 8.0", "< 9"
end
