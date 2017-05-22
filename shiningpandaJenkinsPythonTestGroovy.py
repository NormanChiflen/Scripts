def download = """curl -skLO http://xrl.us/pythonbrewinstall"""
def download_proc = download.execute()
def install = """bash pythonbrewinstall"""
def install_proc = install.execute()

download_proc.waitFor()

println "return code: ${download_proc.exitValue()}"
println "stderr: ${download_proc.err.text}"
println "stdout: ${download_proc.in.text}"

install_proc.waitFor()

println "return code: ${install_proc.exitValue()}"
println "stderr: ${install_proc.err.text}"
println "stdout: ${install_proc.in.text}"

# http://ampledata.org/python_version_testing_with_jenkins.html