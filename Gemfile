source "https://rubygems.org"

gemspec

group :development do
  gem 'pry'
  if ENV.include? 'USE_PRY_DEBUGGER'
    gem 'pry-debugger'
  end
end

group :test do
  gem 'rake'
  gem 'test-unit'
  gem 'rspec', '~> 2.11.0'
end
