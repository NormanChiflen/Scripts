require 'AutoIntegrateProperties'
require 'net/smtp'

# Description:
#
# A collection of email notification related methods to facilitate
# constructing and sending off email.
#
# Version: $Id: //e3/tools/ImplicitIntegration/live/AutoIntegrateNotification.rb#14 $
#
class EmailNotification
  attr_accessor :log, :cc_recipients, :recipients, :subject, :message_body, :email, :sender, :sender_name

  def initialize
    @log = AUTO_INTEGRATOR_LOGGER
    @recipients = []
    @cc_recipients = []
    @subject = ""
    @message_body = ""
    @email = ""
    @sender = ""
    @sender_name = ""
  end

  # Summary:
  # Log and print the text supplied.  For now the logger logs an error if
  # the text contains 'fail'.
  def log_and_print(text)
    puts text
    if AUTO_INTEGRATOR_LOG_ENABLED
        if text.downcase.include?"fail"
          @log.error "Notification: " + text.gsub("\n", "|")
        else
          @log.info "Notification: " + text.gsub("\n", "|")
        end
    end
  end

  # Summary:
  # Set a subject for the email to be sent.
  def add_subject(text)
    @subject = text
  end

  # Summary:
  # Appends text to the email message body.
  def append_to_message_body(text)
    @message_body += text
  end

  # Summary:
  # Clears out the email subject.
  def clear_subject
    @subject = ""
  end

  # Summary:
  # Clears out the email message body accumulated so far.
  def clear_message_body
    @message_body = ""
  end

  # Summary:
  # Clears out any old recipients and adds back all default recipients.
  def reset_recipients
    # Clear out any old recipients in 'To' and 'Cc'.
    @recipients = []
    @cc_recipients = []

    #Add any default recipients to the email.
    DEFAULT_ADMIN_EMAIL_RECIPIENTS.each do |default_recipient|
      add_cc_recipient(default_recipient)
    end
  end

  # Summary:
  # Adds a recipient to the email.
  def add_recipient(recipient)
    @recipients.push(recipient)
  end

  # Summary:
  # Adds a cc recipient to the email.
  def add_cc_recipient(cc_recipient)
    @cc_recipients.push(cc_recipient)
  end

  # Summary:
  # Removes any black listed email recipients specified in black_listed_recipients
  # from the recipients array.
  def remove_black_listed_email_recipients(recipients, black_listed_recipients)
    recipient_type = ""
    if(recipients == @recipients)
      recipient_type = "'To'"
    end
    if(recipients == @cc_recipients)
      recipient_type = "'Cc'"
    end
    log_and_print "Looking to see if any #{recipient_type} addresses are black " +
      "listed in the properties..."

    black_listed_recipients.each do |black_listed_recipient|
      if(recipients.delete(black_listed_recipient) == nil)
        log_and_print "'#{black_listed_recipient}' specified, but not found in email."
      else
        log_and_print "'#{black_listed_recipient}' removed from email."
      end
    end

    if(black_listed_recipients.length < 1)
      log_and_print "No black listed recipients specified in properties."
    end
  end

  # Summary:
  # Process email recipient array, removing any duplicates and concatenating
  # all recipients into a space separated list.  Remove and black listed email
  # recipients.
  def process_email_recipients(recipients)
    recipients_string = ""
    recipients.uniq!

    # Remove any blacklisted email recipients in BLACK_LISTED_EMAIL_RECIPIENTS property.
    remove_black_listed_email_recipients(recipients, BLACK_LISTED_EMAIL_RECIPIENTS)

    return "" if recipients.length < 1

    return recipients[0] if recipients.length == 1

    recipients.each do |address|
      recipients_string += address + " "
    end

    return recipients_string.gsub(/\s/, ", ").chop.chop
  end

  # Summary:
  # Construct the email to be sent form a template, substituting the recipients,
  # subject and message body into the template.
  def construct_email
    @email = EMAIL_MESSAGE_NOTIFICATION_TEMPLATE
    @email = @email.sub(/!!!SENDER!!!/, @sender_name + " <" + @sender + ">")
    @email = @email.sub(/!!!RECIPIENTS!!!/, process_email_recipients(@recipients))
    @email = @email.sub(/!!!CCRECIPIENTS!!!/, process_email_recipients(@cc_recipients))
    @email = @email.sub(/!!!SUBJECT!!!/, @subject)
    @email = @email.sub(/!!!MESSAGE BODY!!!/, @message_body)
  end

  def discard_all_accumulated_email_settings
    # Clear all email fields for re-use.
    clear_subject
    clear_message_body
    reset_recipients
  end

  # Summary:
  # Send the constructed email off to the mail server specified in the
  # properties files and clear fields for reuse.
  def send_email
    construct_email
    
    log_and_print "\n\n********************************************************************************"
    log_and_print "** Email message sent: \n\n#{@email}\n"
    log_and_print "********************************************************************************"

    begin
      Net::SMTP.start(EXPEDIA_MAIL_SERVER) do |smtp|
        smtp.sendmail(@email, @sender, @recipients+@cc_recipients)
      end
    rescue Exception => e
      log_and_print "Error sending email!!\n\n"
      log_and_print "Error message:\n#{e.message}"
      log_and_print "Backtrace:\n"
      e.backtrace.each do |line|
        log_and_print line
      end
    end

    # Clear all email fields for re-use.
    discard_all_accumulated_email_settings
  end
end

