require 'AutoIntegrateProperties'
require 'AutoIntegrateBranchSpec'
require 'WikiUpdater'
require 'logger'
require 'perforce'
require 'trollop'

# Script Version
AUTO_INTEGRATE_ALL_BRANCH_SPECS_VERSION='$Id: //e3/tools/ImplicitIntegration/live/AutoIntegrateAllBranchSpecs.rb#8 $'

# Description:
#
# This routine is responsible for iterating through all Branch Specs that are
# included via the specified BS pattern.  Some basic checks are performed on
# each BS matching the supplied pattern, such as checking if the BS is enabled.
# 
class AutoIntegrateAllBranchSpecs
  attr_accessor :log, :email_notification_enabled, :wiki_updater, :p4

  def initialize(options)
    @options = options
    @log = AUTO_INTEGRATOR_LOGGER
    @p4 = Perforce.new(@options.p4server, @options.p4port, @options.p4rootdir, @options.p4username, @options.p4password)
    @wiki_updater = WikiUpdater.new
    @wiki_updater.delete_intermediate_wiki_text_file
  end

  # Summary:
  # Log and print the text supplied.
  def log_and_print(text)
    puts text
    @log.info "IntegrateAllBranchSpecs: " + text.gsub("\n", "|") if AUTO_INTEGRATOR_LOG_ENABLED
  end

  # Summary:
  # Return and array of Branch Spec names that match the supplied pattern by
  # querying p4.
  def get_branch_specs(pattern)
    branch_spec_results = p4.p4_get_branch_specs(pattern)
    branch_names = []

    branch_spec_result = []
    branch_spec_results.each do |result|
      branch_spec_result = result.split(" ")
      if p4.p4_branch_spec_is_enabled(branch_spec_result[1])
        branch_names.push(branch_spec_result[1])
      else
        log_and_print "Branch Spec '#{branch_spec_result[1]}' matches the supplied " +
          "pattern, but is not enabled... skipping it."
      end
    end

    return branch_names
  end

  # Summary:
  # Main execution loop iterating through Branch Specs determined to be valid
  # and matching the supplied pattern.
  def process_branch_specs(branch_spec_pattern)
    exitcode = 0

    branch_spec_names = get_branch_specs(branch_spec_pattern)

    if branch_spec_names.length < 1
      log_and_print "\nSupplied pattern '#{branch_spec_pattern}' did not produce " +
        "any branch specs... exiting."
      exit exitcode
    end

    log_and_print "\nProcessing the following branch specs:"
    branch_spec_names.each do |branch_spec_name|
      log_and_print branch_spec_name
    end

    @wiki_updater.append_to_intermediate_wiki_text_file("|| Branch Spec Name || Status ||")

    failed_branch_specs = []
    branch_spec_names.each do |branch_spec_name|
      @wiki_updater.append_to_intermediate_wiki_text_file("\n| " + branch_spec_name + " | ")
      log_and_print "\nNow processing branch spec '#{branch_spec_name}'.\n\n"

      # AutoIntegrateBranchSpec class does the actual integration work; it 
      # raises and exception if there is an issue with the integration
      begin
        bs_processor = AutoIntegrateBranchSpec.new(@p4)
        bs_processor.integrate(branch_spec_name)
      rescue Exception => e
        # if the trunk is broken, 
        if e.message == "Trunk broken!"
          log_and_print "\n\n*** Integration is blocked because trunk is broken ***\n"
          exitcode = 2
        else
          failed_branch_specs.push(branch_spec_name)
          exitcode = 1
        end
      end
    end

    if !failed_branch_specs.empty?
        log_and_print "\n\nFailure exit code executing AutoIntegrateBranchSpec on the following branch specs:"
        branch_spec_names.each do |spec_name|
            log_and_print "   #{spec_name}"
        end
    end

    puts "exitcode: #{exitcode}"
    exit exitcode if exitcode > 0

    # Write Intermediate status file to wiki if set and delete it.
    if CONFLUENCE_UPDATES_ENABLED == true
      @wiki_updater.write_intermediate_text_file_to_wiki_page
    else
      log_and_print "\nConfluence updates disabled, skipping wiki status update.\n"
    end
    @wiki_updater.delete_intermediate_wiki_text_file
  end
end

class Options
    attr_accessor :p4username, :p4password, :p4server, :p4port, :p4rootdir, :branchspec

    # Summary:
    # Gets options from the command line
    def get_options
        opts = Trollop::options do
            banner <<-EOS
Performs Perforce implicit integrations using the provided branch spec pattern.

Usage:
    AutoIntegrateAllBranchSpecs --p4server <server> --p4port <port> --p4rootdir <dir> [--p4username <username> --p4password <password>] <BranchSpecPattern>

The required parameters are:
 
EOS
            opt :p4server, "Perforce FQDN name (e.g. perforce.sea.corp.expecn.com)",
                :short => "s",
                :type => String
            opt :p4port, "Perforce port (e.g. 1953)",
                :short => "p",
                :type => String
            opt :p4rootdir, "Directory that will be the parent of the Perforce workspace root (e.g. ~/iip4depots or e:\\iip4depots)",
                :type => String

            banner <<-ENDOPT

Optional parameters are:
 
ENDOPT
            opt :p4username, "Perforce username (defaults to svc.ewe.implicit_integrator)",
                :short => "u",
                :type => String
            opt :p4password, "Perforce user password",
                :short => "d",
                :type => String
  
            banner <<-EOM

Example: 
    AutoIntegrateAllBranchSpecs --p4server perforce.sea.corp.expecn.com --p4port 1953 --p4rootdir ~/iip4depots _imp_*_2_*

User Guide Available at: \n#{AUTO_INTEGRATOR_USER_GUIDE_URL}
 
EOM
        end

        Trollop::die "Branch spec not provided" if ARGV.empty?
        Trollop::die :p4server, "is required" if opts[:p4server] == nil
        Trollop::die :p4port, "is required" if opts[:p4port] == nil
        Trollop::die :p4rootdir, "is required" if opts[:p4rootdir] == nil

        @p4username = opts[:p4username]
        @p4password = opts[:p4password]
        @p4server = opts[:p4server]
        @p4port = opts[:p4port]
        @p4rootdir = opts[:p4rootdir]
        @branchspec = ARGV[0]
    end
end

# Auto Integrate All Branch Specs - Main
begin
  puts "\nAutoIntegrateAllBranchSpecs Version: " +
    AUTO_INTEGRATE_ALL_BRANCH_SPECS_VERSION + "\n\n"

  options = Options.new
  options.get_options
  
  aiabs = AutoIntegrateAllBranchSpecs.new(options)
  aiabs.process_branch_specs(options.branchspec)
end
# Auto Integrate All Branch Specs - Main - End
