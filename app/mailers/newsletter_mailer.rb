class NewsletterMailer < ActionMailer::Base
  default from: "#{$CONFIG[:from]}@#{$CONFIG[:email_domain]}"

  def newsletter_email(u, subject, email_body)
    mail(to: "#{u[:name]} <#{u[:email]}>",
         body: email_body,
         content_type: "text/html",
         subject: subject)
  end
end
