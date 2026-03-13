source 'https://rubygems.org'

ruby '3.2.10'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '< 7.1'
gem 'sprockets-rails'
gem 'puma', '~> 5.6'
gem 'sass-rails', '~> 5.0'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'terser'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'
gem 'chronic_duration'
gem 'jquery-rails', '~> 4.3'
gem 'bootstrap-datepicker-rails', '~> 1.6'
gem 'american_date', '~> 1.1'
gem 'friendly_id'
gem 'rest-client', '~> 2.0'
gem 'dotenv-rails', '~> 2.2'
gem 'strip_attributes', '~> 1.8'
gem 'devise'
gem 'capitalize_attributes'
gem 'pg'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'ffaker', '~> 2.6.0'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen'
  gem 'spring'
  gem 'pry'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
