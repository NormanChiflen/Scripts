require 'logger'

# Configured Parameters - Start
# Email Notification
EMAIL_NOTIFICATIONS_ENABLED       = true
EXPEDIA_MAIL_SERVER               = "chelsmtp01.karmalab.net" #"exp-shost-01"
DEFAULT_ADMIN_EMAIL_RECIPIENTS    = []
BLACK_LISTED_EMAIL_RECIPIENTS     = ["svc.ewe.implicit_integrator@expedia.com",
                                     "relman@chelmakewe01_implicitIntegration_try2",
                                     ]
DEFAULT_EMAIL_DOMAIN              = "@expedia.com"
EMAIL_AUTOMATED_RESPONSE_NOTICE   = nil
# Branch Spec
BRANCH_SPEC_ENABLED_TAG           = "branch_spec_enabled=true"
# Confluence Notification
CONFLUENCE_UPDATES_ENABLED        = false
CONFLUENCE_URL                    = "http://confluence.sea.corp.expecn.com"
CONFLUENCE_CREDENTIALS_USER       = "EWEImplicitIntegrator"
CONFLUENCE_CREDENTIALS_PASSWORD   = "44Nok11D"
CONFLUENCE_PAGE_SPACE             = "POS"
CONFLUENCE_PAGE_NAME              = "Implicit Integration Run Results"
# Auto Integrator logging settings
AUTO_INTEGRATOR_LOG_ENABLED       = false
AUTO_INTEGRATOR_LOG               = Dir.getwd + "/AutoIntegrator.log"
AUTO_INTEGRATOR_LOG_SHIFTS        = 20
AUTO_INTEGRATOR_LOG_MAX_SIZE      = 10*1024*1024
AUTO_INTEGRATOR_LOGGER            = Logger.new(AUTO_INTEGRATOR_LOG, AUTO_INTEGRATOR_LOG_SHIFTS, AUTO_INTEGRATOR_LOG_MAX_SIZE)
# set logging level lower ("INFO" or "DEBUG") for more verbose logging
#AUTO_INTEGRATOR_LOG_LEVEL         = Logger::WARN
AUTO_INTEGRATOR_LOG_LEVEL         = Logger::DEBUG
# whether to print debug messages or not
PRINT_DEBUG_MESSAGES              = true
AUTO_INTEGRATOR_USER_GUIDE_URL    = "http://confluence.sea.corp.expecn.com/display/POS/P05923+Publish+-+Implicit+Integration+Tools"
# Configured Parameters - End

# Deduced globals - Do not Edit
# Wiki
INTERMEDIATE_CONFLUENCE_TEXT_FILE = Dir.getwd + "/wiki.txt"
# P4
P4_USERNAME                       = "svc.ewe.implicit_integrator"
## the encrypted password below is generated using the password_encrypter.rb script
P4_ENCRYPTED_PASSWORD             = "jQH1eU8gA35KADYua+qKEA=="
P4_ENCRYPTED_PASSWORD_KEY         = "just_a_random_string"
P4_CHARSET                        = "utf8"
P4_COMMANDCHARSET                 = "utf8"
P4_CLIENT_PATTERN                 = "implicit_integrator_!!!HOSTNAME!!!_!!!P4PORT!!!"
P4_COMMAND                        = "p4 -zmaxScanRows=20000000 -u !!!P4USERNAME!!! -C #{P4_CHARSET} -Q #{P4_COMMANDCHARSET} -p !!!P4SERVER!!!:!!!P4PORT!!! -c !!!P4CLIENT!!!"
P4_USER_NAME_TAG                  = "User name:"
P4_USER_EMAIL_TAG                 = "Email:"
# Email Notification
IMP_INT_EMAIL_SUBJECT_FAILURE     = "Implicit integration FAILURE encountered"
IMP_INT_EMAIL_SUBJECT_SUCCESS     = "Implicit integration success"
# Deduced globals - End

# Script Version - Do not Edit
TOOLS_VERSION='$Id: //e3/tools/ImplicitIntegration/live/AutoIntegrateProperties.rb#25 $'
# Script Version - End

# Miscellaneous Configs - Do not Edit
EMAIL_MESSAGE_NOTIFICATION_TEMPLATE =
<<MESSAGE_END
From: !!!SENDER!!!
To: !!!RECIPIENTS!!!
Cc: !!!CCRECIPIENTS!!!
Subject: !!!SUBJECT!!!

!!!MESSAGE BODY!!!
MESSAGE_END

# Miscellaneous Configs - End

puts "AutoIntegrateTools Version: " + TOOLS_VERSION
puts "Reading global properties..."

# set logging level
AUTO_INTEGRATOR_LOGGER.level = AUTO_INTEGRATOR_LOG_LEVEL

