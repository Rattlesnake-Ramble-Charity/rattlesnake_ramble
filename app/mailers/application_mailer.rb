class ApplicationMailer < ActionMailer::Base
  # Default sender comes from env; falls back to Gmail username, then a placeholder.
  default from: ENV.fetch('GMAIL_DEFAULT_FROM', ENV['GMAIL_USERNAME'] || 'no-reply@example.com')
  layout 'mailer'
end
