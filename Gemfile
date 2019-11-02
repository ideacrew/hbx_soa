source 'https://rubygems.org'

# Distribute your app as a gem
# gemspec

# Server requirements
# gem 'thin' # or mongrel
# gem 'trinidad', :platform => 'jruby'

# Optional JSON codec (faster performance)
# gem 'oj'

# Project requirements
gem 'rake'

# Component requirements
gem 'ohm', '2.0.1'
gem 'hiredis', '0.6.0'
gem 'haml', '5.0.0'

# Test requirements
gem 'rspec', :group => 'test'
gem 'rack', '1.5.2'
gem 'rack-test', :require => 'rack/test', :group => 'test'

# Padrino Stable Gem
gem 'padrino', '0.12.4'
gem 'json', '1.8.3'
gem 'bunny', '2.2.0'
gem 'forkr', '0.1.7'
gem 'activesupport', '4.1.8'
gem 'nokogiri', '1.6.6.2'
gem 'virtus', '1.0.5'
gem 'pony', '1.11'

# Or Padrino Edge
# gem 'padrino', :github => 'padrino/padrino-framework'

# Or Individual Gems
# %w(core support gen helpers cache mailer admin).each do |g|
#   gem 'padrino-' + g, '0.12.4'
# end

group :production do
  gem 'unicorn', '4.9.0'
  gem 'eye', '0.7'
  gem 'nio4r', '1.1.1'
end

group :development do
  gem 'capistrano', '3.2.1'
  gem 'capistrano-scm-gitcopy', '0.0.7'
  gem 'capistrano-bundler'
end
