# added to track emails 9/10/26
# config/initializers/email_logger.rb
ActiveSupport.on_load(:action_mailer) do
  class EmailLogObserver
    def self.delivered_email(message)
      # You can output structured logs or save this data to a custom DB table
      Rails.logger.info("EMAIL_SENT_LOG: To: #{message.to} | Subject: #{message.subject}")
    end
  end
  ActionMailer::Base.register_observer(EmailLogObserver)
end
