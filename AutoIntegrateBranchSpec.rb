require 'AutoIntegrateProperties'
require 'AutoIntegrateNotification'
require 'WikiUpdater'
require 'logger'
require 'perforce'
require 'trollop'

# Script Version
AUTO_INTEGRATE_BRANCH_SPEC_VERSION='$Id: //e3/tools/ImplicitIntegration/live/AutoIntegrateBranchSpec.rb#26 $'

# Description:
#
# Give the use the ability to auto integrate a views from one to the other as
# specified in the supplied Branch Spec.  Each view is processed in turn and
# all CLs previously submitted are integrated via newly created CLs.  The
# exception is a new branch, for which a one time single integrations is
# performed.  All future integrations on that branch however, will follow the
# scheme previously outlined.
#
class AutoIntegrateBranchSpec
  attr_accessor :log, :email_notification, :wiki_updater, :p4,
    :current_branch_spec_name, :renamed_change_value

  def initialize(p4)

  log_and_print "\nAutoIntegrateBranchSpec Version: " + AUTO_INTEGRATE_BRANCH_SPEC_VERSION

    @log = AUTO_INTEGRATOR_LOGGER

    @p4 = p4

    @email_notification = EmailNotification.new
    if EMAIL_AUTOMATED_RESPONSE_NOTICE != nil
      @email_notification.append_to_message_body(EMAIL_AUTOMATED_RESPONSE_NOTICE + "\n\n")
    end
    @email_notification.append_to_message_body("Server: " + p4.p4server + "\n")

    # set sender's name
    @email_notification.sender_name = p4.p4_get_client_info(P4_USER_NAME_TAG)

    # set sender's email address
    @email_notification.sender = p4.p4_get_user_info(P4_USER_EMAIL_TAG) 

    #Add any default recipients to the email.
    DEFAULT_ADMIN_EMAIL_RECIPIENTS.each do |default_recipient|
      @email_notification.add_cc_recipient(default_recipient)
    end

    @wiki_updater = WikiUpdater.new

    @renamed_change_value = nil
  end

  # Summary:
  # Add a branch spec field to the email for ease of identification by the
  # email recipient.
  def add_branch_spec_specifics_to_email(branch_spec_name)
    @email_notification.append_to_message_body("Branch Spec: " +
      branch_spec_name + "\n")
  end

  # Summary:
  # Log and print the text supplied.  For now the logger logs an error if
  # the text contains 'fail'.
  def log_and_print(text)
    puts text
    if AUTO_INTEGRATOR_LOG_ENABLED
        if text.downcase.include?"fail"
          @log.error "IntegrateBranchSpec: " + text.gsub("\n", "|")
        else
          @log.info "IntegrateBranchSpec: " + text.gsub("\n", "|")
        end
    end
  end

  # Summary:
  # Log and capture the text supplied for the email body.
  def log_to_email(text)
    log_and_print("Email Construction: " + text)
    @email_notification.append_to_message_body(text + "\n")
  end

  # Summary:
  # Send and email using the supplied subject, which will usually be one of the
  # supplied 'failure' or 'success' subjects.
  def send_email(subject)
    if EMAIL_NOTIFICATIONS_ENABLED
      @email_notification.add_subject(subject)
      puts "\nSending notification email with subject '#{subject}'..."
      @email_notification.send_email
    end
  end

  # Summary:
  # Create and send out a 'cleaner' success email by clearing out any
  # accumulated email message body text, which is really just important if
  # something were to fail, and just using a p4 describe for a change.
  def send_success_email(change)
    if EMAIL_NOTIFICATIONS_ENABLED
      # Use the renamed change if it was renamed and clear value/flag.
      unless @renamed_change_value == nil
        change = @renamed_change_value
        @renamed_change_value = nil #reset/clear this just in case
      end

      subject = "CL:#{change}, BS:#{@current_branch_spec_name}: " +
        IMP_INT_EMAIL_SUBJECT_SUCCESS
      @email_notification.add_subject(subject)
      puts "\nSending notification email with subject '#{subject}'..."
      @email_notification.clear_message_body
      @email_notification.append_to_message_body("Server: " + 
        p4.p4server + "\n")
      @email_notification.append_to_message_body("Branch Spec: " +
        @current_branch_spec_name + "\n\n")
      change_description = p4.p4_get_change_description(change)
      append_email_recipients_from_p4_description(change_description)
      @email_notification.append_to_message_body(change_description)

      # Send email only if we get back a valid description for the CL.
      # (This should never happen but just in case, we log it too to keep tabs.)
      if(change_description.length <= 0)
        #Capture intended email recipients so we can log these.
        recipients_string = ""
        @email_notification.recipients.uniq.each do |address|
          recipients_string += address + " "
        end
        log_and_print "Unable to determine change description for " +
          "CL #{change}.  Skipping email notification for the following " +
          "intended email recipients: #{recipients_string}."
        @email_notification.discard_all_accumulated_email_settings
      else
        @email_notification.send_email
      end
    end
  end

  # Summary:
  # Do a p4 lookup of a user and try to determine their email address.  Do a
  # basic check to verify the address is in the default email domain to minimize
  # erroneous recipients.
  def append_email_recipients_from_p4_description(description)
    log_and_print("Looking up email addresses for users found in p4 change description.")
    # users from implicit integration submissions
    users = description.scan(/U\:.+,/)
    users.each do |user|
      user.sub!("U:", "").sub!(",", "").strip!
      email = p4.p4_get_user_info_for_user(P4_USER_EMAIL_TAG, user)
      # Add address only if it is in the email domain.
      if (email.include? DEFAULT_EMAIL_DOMAIN)
        @email_notification.add_recipient(email)
        log_and_print("#{email} address appended to email recipients.\n")
      else
        log_and_print("Email address for user #{user} could not be determined.\n")
      end
    end
    # users from CPT submissions
    users = description.scan(/user\: .+/)
    users.each do |user|
      user.sub!("user: ", "").strip!
      email = p4.p4_get_user_info_for_user(P4_USER_EMAIL_TAG, user)
      # Add address only if it is in the email domain.
      if (email.include? DEFAULT_EMAIL_DOMAIN)
        @email_notification.add_recipient(email)
        log_and_print("#{email} address appended to email recipients.\n")
      else
        log_and_print("Email address for user #{user} could not be determined.\n")
      end
    end
  end

  # Summary:
  # As the name implies the integrate has failed.  Updates the wiki and
  # sends the email indicating as such.
  def fail_integrate(branch_spec_name)
    # Update Wiki with failure details sent in email.
    @wiki_updater.append_to_intermediate_wiki_text_file("(-) Failure |")
    send_email(branch_spec_name + " " + IMP_INT_EMAIL_SUBJECT_FAILURE)
    raise "Integration failed!"
  end

  # Summary:
  # Fails integrate but does not send an email
  def fail_integrate_due_to_broken_trunk
    raise "Trunk broken!"
  end

  # Summary:
  # As the name indicates this routine integrates a previous change under a
  # new CL into a destination as specified in the Branch Spec View.  This
  # includes 'integrates', 'branch/sync' and 'deletes', for which error
  # conditions are checked and reported.
  def p4_integrate_old_change_under_new_change(branch_spec_name, cl)
    new_change = p4.p4_create_new_change(branch_spec_name +
      ", U:" + cl[2] +
      ", CL:" + cl[0] +
      " \n " + p4.p4_get_change_description_only(cl[0]))

    p4_integrate_result =
      p4.p4_integrate("-i -c #{new_change} -t -b #{branch_spec_name} -Di -Ds -s //...@#{cl[0]},@#{cl[0]} 2>&1")

    if p4_integrate_result.include?'branch/sync from' or
       p4_integrate_result.include?'integrate from' or
       p4_integrate_result.include?'delete from'

      log_and_print "\nP4 Integrate:\n" + p4_integrate_result
  
      p4_files_to_resolve = p4.p4_resolve_preview
      log_to_email "\nFiles in conflict:\n#{p4_files_to_resolve}"
      log_to_email "\nIntegrate of original CL#{cl[0]} by #{cl[2]}, under new " +
        "CL#{new_change}.\nP4 log as follows:\n" + p4_integrate_result
    elsif p4_integrate_result.include?'all revision(s) already integrated'
      p4.p4_delete_change(new_change)
      new_change = nil
      log_and_print "All revisions already integrated. Nothing to do."
    else
      # Hook this up to error and success reporting eventually...
      log_and_print "\nFailed to p4 integrate:\n" + p4_integrate_result
      log_to_email "\nIntegrate of original CL#{cl[0]} by #{cl[2]}, under new " +
        "CL#{new_change} FAILED.  (Reverted and deleted new CL#{new_change}.)\n\n" +
        "P4 log as follows:\n" + p4_integrate_result
      #Append any upstream submitters to the failure e-mail. Note that for success mails, this is handled
      #by the send_success_email method.
      change_description = p4.p4_get_change_description(new_change)
      append_email_recipients_from_p4_description(change_description)
      p4.p4_delete_change(new_change)
      fail_integrate(branch_spec_name)
    end

    return new_change
  end

  # Summary:
  # Attempts a p4 submit of the new change.  If a failure is detected, we log it,
  # update the email body, revert all the files and delete the change.
  def p4_submit_and_revert_change_on_failure(branch_spec_name, new_change)
    p4_submission_details = p4.p4_submit(new_change)

    # Try to grep renamed CL from "Renamed change to 12345.".
    p4_submission_details =~ /\AP4 renamed change to (\d+)\.\Z/
    renamed_change = $1

    # if the cl was renamed, capture the new CL and clear the submission details
    if renamed_change != nil
      @renamed_change_value = renamed_change
      p4_submission_details = nil #Clear this since it contained change rename info.
    end

    # if we still have submission details at this point, something went wrong with the submission
    if p4_submission_details != nil
      log_and_print("\nUnable to submit p4 change #{new_change}, " +
        "p4 details as follows:\n#{p4_submission_details}\n")

      if p4_submission_details.include? "No files to submit."
        @email_notification.append_to_message_body("UNSUCCESSFUL.\n" +
          "\n(NOTE: This usually indicates that there are unsubmitted changes that " +
          "have a lock on some/all of these files.  In some instances it may " +
          "indicate a maxscanrows issue, which was logged.)\n\n")
      end

      # revert submission and delete change if the trunk build is broken, but don't
      # exit with a failure, and don't send an email
      if p4_submission_details.include? "The trunk build is broken!"
        @email_notification.reset_recipients
        @email_notification.clear_message_body

        p4.p4_revert_all_files_and_delete_change(new_change)
        fail_integrate_due_to_broken_trunk

      else # some other error blocked the submission; report it
        @email_notification.append_to_message_body("P4 details as follows:\n" +
          "#{p4_submission_details}\n")

        #Append any upstream submitters to the failure e-mail. Note that for 
        #success mails, this is handled by the send_success_email method.
        change_description = p4.p4_get_change_description(new_change)
        append_email_recipients_from_p4_description(change_description)

        p4.p4_revert_all_files_and_delete_change(new_change)
        fail_integrate(branch_spec_name)
      end
    end
  end
  
  # Summary:
  # This routine scans the views supplied in the Branch Spec to determine if
  # any of the destinations are empty or do not exist.  If this is the case an
  # initial integrate/copy of all files from the view source to its destination
  # is performed.
  def p4_pre_process_any_new_empty_destination_branches(branch_spec_name)
    log_and_print "\nPreprocessing branch spec '#{branch_spec_name}'."
    log_and_print "Determining if any branches require a sync..."

    p4_result = p4.p4_get_branch_specification(branch_spec_name)
    # match all source branches matching the following pattern "//*... " or "-//*..."
    branch_src = p4_result.scan(/\-*\/\/.*\.\.\.\ /)
    # match all destination branches matching the following patterns " //*...\n"
    branch_dest = p4_result.scan(/\ \/\/.*\.\.\.\n/)

    (0..branch_src.length-1).each do |i|
      if branch_src[i].include? "-//" #skip and disabled mappings
        log_and_print "Skipping disabled mapping " + branch_src[i] +
          " -> " + branch_dest[i] + " ... "
      else
        log_and_print "Checking " + branch_src[i] + " -> " + branch_dest[i] + " ... "
        if p4.p4_destination_branch_is_empty(branch_dest[i])
          log_and_print "integrating."
          new_change = p4.p4_create_new_change(
            "New branch creation via branch spec '#{branch_spec_name}'")

          #grab owner of the branch spec and add to email recipients
          @email_notification.add_recipient(
            p4.p4_get_branch_spec_owner(branch_spec_name) + DEFAULT_EMAIL_DOMAIN)
          # Add recipients specified in the bs to email.
          add_email_recipients_specified_in_branch_spec(branch_spec_name)

          log_to_email "\nIntegrating branch '#{branch_src[i]}' to new branch " +
            "'#{branch_dest[i]}', as specified in branch spec '#{branch_spec_name}', " +
            "under CL#{new_change}, was "
          log_and_print "Integrating..."
          p4.p4_integrate("-c #{new_change} -t -b #{branch_spec_name} #{branch_dest[i]}")

          #fail_integrate unless p4_auto_resolve_successful == true
          if p4.p4_auto_resolve_successful(branch_dest[i]) == false
            log_to_email "a FAILURE.\n"
            #Append any upstream submitters to the failure e-mail. Note that for success mails, this is handled
            #by the send_success_email method.
            change_description = p4.p4_get_change_description(new_change)
            append_email_recipients_from_p4_description(change_description)
            send_email(IMP_INT_EMAIL_SUBJECT_FAILURE)
            p4.p4_revert_all_files_and_delete_change(new_change)
            fail_integrate(branch_spec_name)
          end

          p4.p4_opened
          p4_submit_and_revert_change_on_failure(branch_spec_name, new_change)

          @wiki_updater.append_to_intermediate_wiki_text_file("(+) New |")
          log_to_email "successful.\n"
          send_success_email(new_change)
        else
          log_and_print "skipped."
        end
      end
    end
  end

  # Summary:
  # Process all p4 interchanges/CLs applied on the Branch Spec view's source
  # and integrate them in turn to the view's destination.  Any newly created
  # CLs are reverted if a failure is detected.
  def process_p4_interchanges(cl_array, branch_spec_name)
    log_and_print "\nProcessing the following interchanges:\n"
    p4.p4_print_interchanges(cl_array)

    cl_array.each do |cl|
      log_and_print "\n\nProcessing CL #{cl[0]}..."

      # Add recipients specified in the bs to email.
      add_email_recipients_specified_in_branch_spec(branch_spec_name)

      new_change = p4_integrate_old_change_under_new_change(branch_spec_name, cl)
      next if new_change == nil

      @email_notification.add_recipient(cl[2] + DEFAULT_EMAIL_DOMAIN)

      # Updated to delete CLs created that fail... revert if re-specified...
      #fail_integrate unless p4_auto_resolve_successful == true
      p4.p4_get_branch_spec_view_destinations(branch_spec_name).each do |branch|
        if p4.p4_auto_resolve_successful(branch) == false

          #Append any upstream submitters to the failure e-mail. Note that for 
          #success mails, this is handled by the send_success_email method.
          change_description = p4.p4_get_change_description(new_change)
          append_email_recipients_from_p4_description(change_description)
  
          p4.p4_revert_all_files_and_delete_change(new_change)
          @email_notification.append_to_message_body "FAILURE to auto resolve changes.  " +
            "CL#{new_change} reverted and deleted.\n"
          fail_integrate(branch_spec_name)
        end
      end

      p4.p4_opened
      p4_submit_and_revert_change_on_failure(branch_spec_name, new_change)
      send_success_email(new_change)
    end

    @wiki_updater.append_to_intermediate_wiki_text_file("(/) Success |")
  end

  # Summary:
  # Determine if the supplied CL array contains any CLs needing processing.
  def changes_require_processing(cl_array)
    if cl_array.size < 1
      log_and_print "\nNo CLs to process... exiting."
      @wiki_updater.append_to_intermediate_wiki_text_file("(/) Success |")
      return false
    end

    return true
  end

  # Summary:
  # Adds any email recipients specified in the BS to the email.  Email addresses
  # are validated against the default domain downstream.
  def add_email_recipients_specified_in_branch_spec(branch_spec_name)
    bs_recipients =
      p4.p4_get_email_recipients_from_branch_spec_and_validate(branch_spec_name)

    if(bs_recipients == nil)
      return
    end

    bs_recipients.each do | recipient |
      @email_notification.add_recipient(recipient)
    end
  end

  # Summary:
  # Main integration logic executed on the supplied Branch Spec.  Check
  # validity and existence of the supplied BS.  Then check for new branches
  # needing creation and any interchanges needing updates.
  def integrate(branch_spec_name)
    @current_branch_spec_name = branch_spec_name

    add_branch_spec_specifics_to_email(@current_branch_spec_name)
    
    # Look up and add branch spec owner's to email address to list of recipients.
    bs_owner = p4.p4_get_branch_spec_owner(@current_branch_spec_name)
    bs_owner_email = p4.p4_get_user_info_for_user(P4_USER_EMAIL_TAG, bs_owner)
    @email_notification.add_recipient(bs_owner_email)

    fail_integrate(branch_spec_name) unless p4.p4_branch_spec_exists(branch_spec_name) == true
    fail_integrate (branch_spec_name) unless p4.p4_branch_spec_is_enabled(branch_spec_name) == true
    p4.p4_sync_branches_in_branch_spec_view(branch_spec_name)
    p4_pre_process_any_new_empty_destination_branches(branch_spec_name)

    cl_array = nil
    begin
      cl_array = p4.p4_fetch_interchanges(branch_spec_name)
    rescue
      # an exception here means the perforce interchanges command failed (likely due to a timeout)
      @email_notification.append_to_message_body "\nFAILURE to get outstanding changes! Perforce interchanges operation timed out.\n"
      fail_integrate(branch_spec_name)
    end
    return if cl_array == nil
    return unless changes_require_processing(cl_array)
    process_p4_interchanges(cl_array, branch_spec_name)
  end
end

