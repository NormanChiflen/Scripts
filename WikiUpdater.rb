require 'confluence_rpc'
require 'AutoIntegrateProperties'
require 'logger'

# Description:
#
# A collection of wiki update methods to facilitate the creation and updating
# of Implicit Integration status wiki.  We use an intermediate text file where
# we temporarily create the new wiki, which we then compare to the current
# wiki and only write it out if there are differences.  (This is to minimize
# writes to confluence.)
#
# Version: $Id: //e3/tools/ImplicitIntegration/live/WikiUpdater.rb#4 $
#
class WikiUpdater
  attr_accessor :page_text, :log

  def initialize
    @log = AUTO_INTEGRATOR_LOGGER
  end

  # Summary:
  # Log and print the text supplied with a 'Wiki Update' prefix for easy
  # identification.  For now the logger logs an error if the text
  # contains 'fail'.
  def log_and_print(text)
    puts text
    if AUTO_INTEGRATOR_LOG_ENABLED
        if text.downcase.include?"fail"
          @log.error "Wiki Update: " + text.gsub("\n", "|")
        else
          @log.info "Wiki Update: " + text.gsub("\n", "|")
        end
    end
  end

  # Summary:
  # Log and print the wiki page details for informational purposes.
  def log_and_print_page(page)
    log_and_print "\n"
    log_and_print "space: " + page['space']
    log_and_print "title: " + page['title']
    log_and_print "content: " + page['content']
    log_and_print "parentId: " + page['parentId']
    log_and_print "\n"
  end

  # Summary:
  # Append the text supplied to the intermediate text file.
  def append_to_intermediate_wiki_text_file(text)
    File.open(INTERMEDIATE_CONFLUENCE_TEXT_FILE, 'a') do |f|
      f.write(text)
      f.close
    end
  end

  # Summary:
  # Delete the intermediate text file if it exists.
  def delete_intermediate_wiki_text_file()
    if File.exist?(INTERMEDIATE_CONFLUENCE_TEXT_FILE)
      File.delete(INTERMEDIATE_CONFLUENCE_TEXT_FILE)
    end
  end

  # Summary:
  # Read in the file specified in filename and return it's contents in a
  # string.
  def get_file_as_string(filename)
    data = ''

    f = File.open(filename, "r")
    f.each_line do |line|
      data += line
    end
    f.close

    return data
  end
  
  # Summary:
  # Read the current wiki status page and return it's contents as a string.
  def read_current_wiki_status_page_contents
    server = Confluence::RPC.new(CONFLUENCE_URL)
    server.login(CONFLUENCE_CREDENTIALS_USER, CONFLUENCE_CREDENTIALS_PASSWORD)
    page = server.getPage(CONFLUENCE_PAGE_SPACE, CONFLUENCE_PAGE_NAME)
    server.logout()
    return page['content']
  end

  # Summary:
  # Compare the intermediate text file with the current status wiki and return
  # a boolean indicating if they are different.  If the 2 are the same we
  # return true.
  def current_wiki_is_same_as_proposed_changes
    wiki_text = read_current_wiki_status_page_contents
    proposed_text = get_file_as_string(INTERMEDIATE_CONFLUENCE_TEXT_FILE)
    return true if wiki_text.include?proposed_text
    return false
  end
  
  # Summary:
  # Write the intermediate generated text file's contents out to the wiki.
  def write_intermediate_text_file_to_wiki_page
    unless File.readable?(INTERMEDIATE_CONFLUENCE_TEXT_FILE)
      log_and_print "Failure: Intermediate wiki file " +
        "'#{INTERMEDIATE_CONFLUENCE_TEXT_FILE}' not readable..."
      return nil
    end

    if current_wiki_is_same_as_proposed_changes
      log_and_print "Proposed wiki changes are the same as existing page, skipping update."
      return nil
    end

    text = get_file_as_string(INTERMEDIATE_CONFLUENCE_TEXT_FILE)
    server = Confluence::RPC.new(CONFLUENCE_URL)
    server.login(CONFLUENCE_CREDENTIALS_USER, CONFLUENCE_CREDENTIALS_PASSWORD)

    page = server.getPage(CONFLUENCE_PAGE_SPACE, CONFLUENCE_PAGE_NAME)
    log_and_print "Previous Status Page:"
    log_and_print_page(page)

    page['content'] = text
    log_and_print "New Status Page:"
    log_and_print_page(page)

    server.storePage(page)
    server.logout()
  end
end
