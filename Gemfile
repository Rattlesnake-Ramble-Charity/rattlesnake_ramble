source 'https://rubygems.org'

ruby '3.4.11'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 8.1.0'
gem 'sprockets-rails'
gem 'puma', '~> 7.2'
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
gem 'dotenv-rails', '~> 3.2'
gem 'strip_attributes', '~> 2.0'
gem 'devise'
gem 'capitalize_attributes'
gem 'pg'
# json 3 removed the create_additions option that sprockets 3 still passes when
# reading its manifest. Drop this pin once the app is off sprockets 3.
gem 'json', '< 3'

group :development, :test do
  gem 'byebug', platforms: [:mri, :windows]
  gem 'capybara', '~> 3.40'
  gem 'selenium-webdriver'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'ffaker', '~> 2.25'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen'
  gem 'pry'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:windows, :jruby]
