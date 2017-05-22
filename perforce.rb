require 'AutoIntegrateProperties'
require 'AutoIntegrateNotification'
require 'WikiUpdater'
require 'logger'
require 'time'
require 'crypto'

# Description:
#
# A collection of perforce related scripts that query and parse info retrieved
# from p4.
#
# Version: $Id: //e3/tools/ImplicitIntegration/live/perforce.rb#22 $
#
class Perforce
  attr_accessor :log, :p4username, :p4password, :p4server, :p4port, :p4rootdir, :p4client, :p4command

  def initialize(p4server, p4port, p4rootdir, p4username=nil, p4password=nil)
    @start_time = Time.now

    @log = AUTO_INTEGRATOR_LOGGER

    @p4username = ""
    @p4password = ""
    if p4username == nil
      @p4username = P4_USERNAME
      @p4password = decrypt_password
    else
      @p4username = p4username
      @p4password = p4password
    end

    @p4server = p4server
    @p4port = p4port
    @p4rootdir = p4rootdir

    @hostname = `hostname`
    @hostname.downcase!
    @hostname.chomp!

    @p4client = P4_CLIENT_PATTERN
    @p4client.gsub!("!!!HOSTNAME!!!", @hostname)
    @p4client.gsub!("!!!P4PORT!!!", @p4port)

    @p4command = P4_COMMAND
    @p4command.gsub!("!!!P4USERNAME!!!", @p4username)
    @p4command.gsub!("!!!P4SERVER!!!", @p4server)
    @p4command.gsub!("!!!P4PORT!!!", @p4port)
    @p4command.gsub!("!!!P4CLIENT!!!", @p4client)

    login = p4_login
    if (!login)
      log_and_print "\nQuitting!\n"
      exit 1
    end

    prep_client = p4_client_prepare
    if (!prep_client)
      log_and_print "\nError creating client. Quitting!\n"
      exit 1
    end
  end

  # Summary:
  # Returns elapsed time since this p4 object was instantiated
  def elapsed_time
    return "Elapsed time since start: " + ((Time.now - @start_time) * 1000).to_i.to_s + " milliseconds"
  end

  # Summary:
  # Prints provided message, if debug logging is enabled in global options
  def log_debug(message)
    puts message if PRINT_DEBUG_MESSAGES
  end

  # Summary:
  # Log and print the text supplied with a 'Perforce' prefix for easy
  # identification in the logs.  For now the logger logs an error if
  # the text contains 'fail'.
  def log_and_print(text)
    puts text
    if AUTO_INTEGRATOR_LOG_ENABLED
      if text.downcase.include?"fail"
        @log.error "Perforce: " + text.gsub("\n", "|")
      else
        @log.info "Perforce: " + text.gsub("\n", "|")
      end
    end
  end

  # Summary:
  # Decrypts the password hash specified in the global properties
  def decrypt_password
    decoded_hash = Crypto.decode(P4_ENCRYPTED_PASSWORD)
    Crypto.decrypt(P4_ENCRYPTED_PASSWORD_KEY, decoded_hash)
  end

  # Summary:
  # Executes provided perforce command, prints output if debugging is enabled and returns command output
  def p4_execute_command(p4command_args, log_p4_command = true, log_p4_response = true)
    caller[0]=~/`(.*?)'/  # gets name of calling method
    log_debug "Calling method: #{$1}"
    log_debug elapsed_time
    if log_p4_command
      log_debug "Issued p4 command:\n\t#{@p4command} #{p4command_args}"
    else
      log_debug "Issued p4 command: --Not logged--\n"
    end
    p4_result = `#{@p4command} #{p4command_args} 2>&1`
    log_debug elapsed_time
    if log_p4_response
      log_debug "Received p4 response:\n#{p4_result}"
    else
      log_debug "Received p4 response: --Not logged--\n"
    end
    log_debug elapsed_time
    return p4_result
  end

  # Summary:
  # Logs in to perforce
  def p4_login
    tries = 0
    begin
      log_debug "In method: p4_login"
      log_debug "Issued p4 command:\n\techo xxxxxxxxxxxx|#{p4command} login"
      login = `echo #{@p4password}|#{p4command} login 2>&1`
      log_debug "Received p4 response:\n\t#{login}"

      raise if login.match(/User.*logged in/) == nil
      log_and_print "Perforce login successful"
      return true
    rescue
      log_and_print "Failed to login in to Perforce"
      tries += 1
      if tries < 3
        log_and_print "Sleeping 60 seconds then retrying..."
        sleep(60)
        retry
      end
      return false
    end
  end

  # Summary:
  # Creates client if it doesn't exist. If the client exists, verifies that the client root matches the current root directory preference. If it doesn't, delete client and recreate it.
  def p4_client_prepare
    log_and_print "\nChecking if p4 client exists..."
    if p4_client_exists
      log_and_print "Client #{p4client} exists."
      log_and_print "Verifying client root..."
      if p4_client_get_root == p4rootdir
        log_and_print "Client root unchanged: #{p4rootdir}\n"
          return true
      else
        log_and_print "Client root changed. Deleting and re-creating client..."
        p4_client_delete
      end
    end

    result = p4_client_create
    if (result)
      log_and_print "Client #{p4client} successfully created.\n"
      return true
    else
      log_and_print "Unable to create client.\n"
      return false
    end
  end

  # Summary:
  # Creates the client.
  def p4_client_create
    tries = 0
    begin
      p4_client_result = p4_execute_command("client -o")
      p4_client_result.sub!(p4_client_get_root, p4rootdir)
    rescue
      log_and_print "Did not receive info from Perforce. Failed to create Perforce client!"
      tries += 1
      if tries < 3
        log_and_print "Sleeping 60 seconds then retrying..."
        sleep(60)
        retry
      end
      return false
    end

    IO.popen("#{p4command} client -i", "w") {|f|
      f.puts p4_client_result
      f.close
    }

    return $?
  end

  # Summary:
  # Deletes the client.
  def p4_client_delete
    p4_result = p4_execute_command("client -d #{p4client}")
  end

  # Summary:
  # Checks if the client exists.
  def p4_client_exists
    tries = 0
    begin
      p4_client_result = p4_execute_command("client -o")
      raise if (p4_client_result == nil) || (p4_client_result.match(/Owner:\t#{@p4username}/) == nil)
    rescue
      log_and_print "Did not receive info from Perforce. Failed to determine if Perforce client exists!"
      tries += 1
      if tries < 3
        log_and_print "Sleeping 60 seconds then retrying..."
        sleep(60)
        retry
      end
      return false
    end
    result = p4_client_result.scan(/^Access:/)  #the access line only exists if the client exists
    !result.empty?
  end

  # Summary:
  # Returns the root of the client
  def p4_client_get_root
    tries = 0
    begin
      p4_client_result = p4_execute_command("client -o")
      raise if (p4_client_result == nil) || (p4_client_result.match(/Owner:\t#{@p4username}/) == nil)
    rescue
      log_and_print "Did not receive info from Perforce. Failed to get Perforce client root!"
      tries += 1
      if tries < 3
        log_and_print "Sleeping 60 seconds then retrying..."
        sleep(60)
        retry
      end
      return false
    end

    root = p4_client_result.scan(/^Root:.*/)
    root[0].sub!(/Root:/, "").strip!
  end

  # Summary:
  # Gets branch spec names that match the supplied pattern
  def p4_get_branch_specs(branch_spec_pattern)
    p4_result = p4_execute_command("branches -e #{branch_spec_pattern}")
  end

  # Summary:
  # Determine if the supplied Branch Spec is valid.
  def p4_branch_spec_exists(branch_spec_name)
    branches = p4_execute_command("branches")

    return true if(branches.include?branch_spec_name)

    log_and_print "\nError: Branch name '" + branch_spec_name +
      "' not found among the following possible branches\n" + branches
    return false
  end

  # Summary:
  # Return an array of all p4 interchanges for the supplied Branch Spec.
  def p4_fetch_interchanges(branch_spec_name)
    tries = 0
    cl_array = []
    begin
      changes = p4_execute_command("interchanges -b #{branch_spec_name}")
      raise if changes.include?("Operation took too long")

      return if changes.include?("All revision(s) already integrated.")

      changes.each do |change|
        field = []; description = []; user = [];
        field = change.split(" ")
        description = change.split("'")
        user = field[5].split("@")

        cl = []     # cl, date, user, description
        cl.push(field[1], field[3], user[0], description[1])
        cl_array.push(cl)
      end

    rescue
      log_and_print "Perforce operation timed out!"
      tries += 1
      if tries < 3
        log_and_print "Sleeping 60 seconds then retrying..."
        sleep(60)
        retry
      else
        raise
      end
    end
    return cl_array
  end

  # Summary:
  # Pretty print the array of interchanges for inspection purposes.
  def p4_print_interchanges(cl_array)
    log_and_print "CL\tDate\t\tUser\t\tDescription"
    cl_array.each do |field|
      log_and_print field[0] + "\t" + field[1] + "\t" + field[2] + "\t\t" + field[3]
    end
  end

  # Summary:
  # Create a new change in p4 using the supplied description and return the CL
  # number.
  def p4_create_new_change(change_description)
    cl = []

    IO.popen("#{p4command} change -i", "r+") {|f|
      f.puts("Change: new\nDescription: #{change_description}\n");
      f.close_write
      cl = f.gets.split(" ")
      f.close
    }

    log_and_print "Created new CL " + cl[1]

    return cl[1]
  end

  # Summary:
  # Retrieve the full description for the supplied change, since this is
  # otherwise truncated using other methods.
  def p4_get_change_description_only(change)
    p4_description = p4_execute_command("describe -s #{change}")

    fields = p4_description.split("\n", 2) # split off first line in the p4 description

    if(fields[1].include?"Jobs fixed ...") # split on 'Jobs...' if it exists,
      fields = fields[1].split("Jobs fixed ...", 2)
    else                                              # else split on 'Affected...'; by default
      fields = fields[1].split("Affected files ...", 2)
    end

    return fields[0].strip
  end

  # Summary:
  # Return the entire contents of "p4 describe -s" for the provided changelist.
  def p4_get_change_description(change)
    p4_execute_command("describe -s #{change}")
  end

  # Summary:
  # Determine if the supplied Branch Spec is enabled by looking in its
  # description and seeing if it contains the expected text as specified in
  # the BRANCH_SPEC_ENABLED_TAG .
  def p4_branch_spec_is_enabled(branch_spec_name)
    p4_result = p4_execute_command("branch -o #{branch_spec_name}")
    return p4_result.include?(BRANCH_SPEC_ENABLED_TAG)
  end

  # Summary:
  # Delete the change specified.  Usually used when backing out a created CL
  # due to an integration failure.
  def p4_delete_change(change)
    log_and_print "\nBacking out Cl #{change}"
    p4_execute_command("change -d #{change}")
  end

  # Summary:
  # Do the prerequisite revert of all files contained in the specified CL
  # before deleting it.
  def p4_revert_all_files_and_delete_change(change)
    log_and_print "\nReverting all files in CL #{change}."
    p4_execute_command("revert -c #{change} //#{@p4client}/...")
    p4_delete_change(change)
  end

  # Summary:
  # Parse out lines of the p4 info text, using predefined tags in the properties
  # file, such as P4_INFO_CLIENT_NAME_TAG.
  def p4_get_client_info(tag)
    p4_client_result = p4_execute_command("info")

    p4_client_result.each do |line|
      if line.include? tag
        return line.sub!(/#{tag}/, "").strip!
      end
    end
  end

  # Summary:
  # Parse out lines of the p4 user text, using predefined tags in the properties
  # file, such as P4_USER_EMAIL_TAG.
  def p4_get_user_info(tag)
    return p4_get_user_info_for_user(tag, nil)
  end

  # Summary:
  # For a specified user, parse out lines of the p4 user text, using predefined
  # tags in the properties file, such as P4_USER_EMAIL_TAG.
  def p4_get_user_info_for_user(tag, user)
    if user == nil
      p4_user_result = p4_execute_command("user -o")
      log_and_print "Looking up tag '#{tag}' in p4 user info for current user.\n"
    else
      p4_user_result = p4_execute_command("user -o #{user}")
      log_and_print "Looking up tag '#{tag}' in p4 user info for user '#{user}'.\n"
    end

    p4_user_result.each do |line|
      if line.include? tag and !line.include? "#" #ignore the hashed line with same tag
        return line.sub!(/#{tag}/, "").strip!
      end
    end
    
    log_and_print("Tag '#{tag}' not found!\n")
    return "#{tag} not found."
  end

  # Summary:
  # Perform a p4 auto resolve on a specific branch and parse the response
  # looking for 'resolve skipped' to determine success.
  def p4_auto_resolve_successful(branch)
    log_and_print "\nSetting p4 resolve to automatic.  Trying to auto resolve..."

    p4_resolve_result = p4_execute_command("resolve -am #{branch}")
    if p4_resolve_result.include?'resolve skipped'
      log_and_print p4_resolve_result
      log_and_print "\nFailure to auto resolve implicit integrate on branch " +
        "'#{branch}'... \nNext Step:\nPlease manually resolve your change."
      return false
    end

    return true
  end

  # Summary:
  # Fetch all Branch Spec View destination branches in the specified Branch
  # Spec.
  def p4_get_branch_spec_view_destinations(branch_spec_name)
    log_and_print "\nLooking up Branch Spec view destinations in p4 for " + 
      "branch '#{branch_spec_name}'..."
    p4_result = p4_execute_command("branch -o #{branch_spec_name}")
    # grep destination branches using a " //*" pattern
    branches = p4_result.scan(/\ \/\/.*/)

    #strip out extraneous chars in each branch
    (0..branches.length-1).each do |i|
      branches[i].strip!
    end

    log_and_print("Found the following destination branches in Branch " +
      "Spec '#{branch_spec_name}':\n")
    branches.each do |branch|
      log_and_print("'#{branch}'\n")
    end

    return branches
  end

  # Summary:
  # Determine the owner of the specified branch spec by looking at the
  # 'Owner:' field in the p4 branch query response.
  def p4_get_branch_spec_owner(branch_spec_name)
    log_and_print "Looking up owner of Branch Spec '#{branch_spec_name}'..."
    p4_result = p4_execute_command("branch -o #{branch_spec_name}")
    # clear 'Owner' in comment so we parse the correct line below
    p4_result.gsub!("#  Owner:", "") 
    p4_result.each do |line|
      if line.include?("Owner:")
        line.gsub!("Owner:", "").strip!
        log_and_print "Owner of '#{branch_spec_name}' is '#{line}'."
        return line
      end
    end

    log_and_print "Owner of '#{branch_spec_name}' could not be determined."
    return ""
  end
  
  # Summary:
  # Look into the BS description to see if any additional email recipients are
  # specified.  Only email recipients matching the default email domain will be
  # accepted.
  #
  # If all goes well an array of recipients is returned; else nil.
  def p4_get_email_recipients_from_branch_spec_and_validate(branch_spec_name)
    log_and_print "Looking to see if any addition email recipients are specified " +
      "in the Branch Spec '#{branch_spec_name}'..."

    p4_result = p4_execute_command("branch -o #{branch_spec_name}")
    if(p4_result.scan(/email_notification=\[(.*)\]/).to_s.length == 0)
      log_and_print "No addition email recipients found for branch spec '#{branch_spec_name}'."
      return nil
    end

    bs_email_recipients = $1.split(",")
    validated_bs_email_recipients = []
    log_and_print "Found the following email recipients in branch spec '#{branch_spec_name}'."
    bs_email_recipients.each do | recipient |
      #Only add email address if it is in the DEFAULT_EMAIL_DOMAIN.
      recipient.scan(/.*(\@.*)/)
      if($1.strip == DEFAULT_EMAIL_DOMAIN)
        log_and_print("'#{recipient.strip}' email recipient accepted.")
        validated_bs_email_recipients.push(recipient.strip)
      else
        log_and_print("'#{recipient.strip}' email recipient rejected.")
      end
    end

    #Return nil if no additional recipients were added and validated.
    if(validated_bs_email_recipients.length < 1)
      return nil
    end
    
    return validated_bs_email_recipients
  end

  # Summary:
  # Print out the files opened as informational.
  def p4_opened
    log_and_print "\nFiles affected:"
    p4_opened_result = p4_execute_command("opened")
    log_and_print p4_opened_result
  end

  # Summary:
  # p4 submit a change and parse the response to determine success.
  #
  # Returns:
  # nil = successful submit
  # renamed text = change was renamed; new change is returned
  # failure text = failed to submit, details within the text returned
  def p4_submit(new_change)
    log_and_print "\nInitiating p4 submit:"
    p4_submit_result = p4_execute_command("submit -c #{new_change}")
    if p4_submit_result.include?'submitted.'
      log_and_print "\nP4 submit successful.\n" + p4_submit_result
      renamed_change = p4_submit_get_renamed_change(p4_submit_result)
      if renamed_change == nil #change was not renamed
        log_and_print("P4 did not rename change #{new_change}.")
        return nil
      else #change was renamed; new different CL
        new_change_message = "P4 renamed change to #{renamed_change}."
        log_and_print(new_change_message)
        return new_change_message
      end
    else
      log_and_print "\nP4 submit failed.\n" + p4_submit_result
      #fail_integrate
      return p4_submit_result
    end
  end

  # Summary:
  # From the p4 submit output determine if the change was renamed and if so
  # return the new CL.
  #
  # Returns:
  # nil = change was not renamed
  # CL text = change was renamed; CL returned
  def p4_submit_get_renamed_change(p4_submit_result)
    # try to grep new CL using p4 text message match and grab new CL.
    p4_submit_result =~ /.*Change (\d+) renamed change (\d+) and submitted\..*/
    return $2  #$2 is nil if pattern match fails above
  end

  # Summary:
  # Performing a revert of all files in the provided branch
  def p4_revert(branch)
    log_and_print "\nReverting all files in #{branch}"
    p4_execute_command("revert #{branch}")
  end

  # Summary:
  # p4 sync a branch.
  def p4_sync(branch)
    p4_revert(branch)
    log_and_print "\nDoing a p4 sync on #{branch}"
    p4_execute_command("sync #{branch}")
  end

  # Summary:
  # Iterate through all branches in the view of the supplied branch spec and
  # do a p4 sync on them.
  def p4_sync_branches_in_branch_spec_view(branch_spec_name)
    log_and_print "\nExecuting p4 sync on views in branch '#{branch_spec_name}'."
    p4_result = p4_execute_command("branch -o #{branch_spec_name}")
    # grep source branches using "//* " and sync.
    p4_result.scan(/(\/\/.*\ )/) do |branch|
      p4_sync(branch.to_s.strip)
    end
    # grep destination branches using " //*" and sync.
    p4_result.scan(/\ \/\/.*/) do |branch|
      p4_sync(branch.to_s.strip)
    end
  end

  # Summary:
  # Query p4 to determine if the supplied branch contains any files.  The p4
  # query result will be an empty string if this is the case and return true.
  def p4_destination_branch_is_empty(branch)
    branch.strip!
    branch.gsub!("...", "*")
    p4_files_result = p4_execute_command("files #{branch}", true, true)
    p4_dirs_result = p4_execute_command("dirs #{branch}", true, true)

    # No files in branch.
    if p4_files_result.length <= 0 && p4_dirs_result.length <= 0
      return true
    else
      return false
    end
  end

  # Summary:
  # Executes "p4 integrate <parameters>" and returns the result.
  def p4_integrate(parameters)
    p4_execute_command("integrate #{parameters}")
  end

  # Summary:
  # Executes "p4 resolve -n" and returns the result.
  def p4_resolve_preview
    p4_execute_command("resolve -n")
  end

  # Summary:
  # Returns the branch specification for the provided branch spec name
  def p4_get_branch_specification(branchspec)
    p4_execute_command("branch -o #{branchspec}")
  end
end

