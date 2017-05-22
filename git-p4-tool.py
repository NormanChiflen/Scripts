#!/usr/bin/env python
#http://stevehanov.ca/blog/git-p4.py.txt
# git-p4.py -- A tool for bidirectional operation between a Perforce depot and git.
#
# Author: Simon Hausmann <simon@lst.de>
# Copyright: 2007 Simon Hausmann <simon@lst.de>
#            2007 Trolltech ASA
# License: MIT <http://www.opensource.org/licenses/mit-license.php>
#

import optparse, sys, os, marshal, subprocess, shelve
import tempfile, getopt, sha, os.path, time, platform
import re
import cStringIO

from sets import Set;

verbose = False

class LargeFileWriter:
    """Wrapper for a file, to get around a windows bug when writing large amounts of data.
    
    When writing to the wrapped file object, writes are broken up so that only 10MB are written at
    a time. Otherwise, there is IO exception on Windows.
    """
    def __init__(self, filedesc):
        self.read = filedesc.read
        self.flush = filedesc.flush
        self.close = filedesc.close
        self.filedesc = filedesc

    def write(self, bytes):
        chunk = 10*1024*1024 # I don't know how high we can go before the bug is triggered, so we
        #only write 10MB at a time.
        while len(bytes) > chunk:
            self.filedesc.write(bytes[:chunk])
            self.filedesc.flush()
            bytes = bytes[chunk:]

        if len(bytes):    
            self.filedesc.write(bytes[:chunk])
            self.filedesc.flush()

def p4_build_cmd(cmd):
    """Build a suitable p4 command line.

    This consolidates building and returning a p4 command line into one
    location. It means that hooking into the environment, or other configuration
    can be done more easily.
    """
    real_cmd = "%s " % "p4"

    user = gitConfig("git-p4.user")
    if len(user) > 0:
        real_cmd += "-u %s " % user

    password = gitConfig("git-p4.password")
    if len(password) > 0:
        real_cmd += "-P %s " % password

    port = gitConfig("git-p4.port")
    if len(port) > 0:
        real_cmd += "-p %s " % port

    host = gitConfig("git-p4.host")
    if len(host) > 0:
        real_cmd += "-h %s " % host

    client = gitConfig("git-p4.client")
    if len(client) > 0:
        real_cmd += "-c %s " % client

    real_cmd += "%s" % (cmd)
    if verbose:
        print real_cmd
    return real_cmd

def chdir(dir):
    if os.name == 'nt':
        os.environ['PWD']=dir
    os.chdir(dir)

def die(msg):
    if verbose:
        raise Exception(msg)
    else:
        sys.stderr.write(msg + "\n")
        sys.exit(1)

def write_pipe(c, str):
    if verbose:
        sys.stderr.write('Writing pipe: %s\n' % c)

    pipe = os.popen(c, 'w')
    val = pipe.write(str)
    if pipe.close():
        die('Command failed: %s' % c)

    return val

def p4_write_pipe(c, str):
    real_cmd = p4_build_cmd(c)
    return write_pipe(real_cmd, str)

def read_pipe(c, ignore_error=False):
    if verbose:
        sys.stderr.write('Reading pipe: %s\n' % c)

    pipe = os.popen(c, 'rb')
    val = pipe.read()
    if pipe.close() and not ignore_error:
        die('Command failed: %s' % c)

    return val

def p4_read_pipe(c, ignore_error=False):
    real_cmd = p4_build_cmd(c)
    return read_pipe(real_cmd, ignore_error)

def read_pipe_lines(c):
    if verbose:
        sys.stderr.write('Reading pipe: %s\n' % c)
    ## todo: check return status
    pipe = os.popen(c, 'rb')
    val = pipe.readlines()
    if pipe.close():
        die('Command failed: %s' % c)

    return val

def p4_read_pipe_lines(c):
    """Specifically invoke p4 on the command supplied. """
    real_cmd = p4_build_cmd(c)
    return read_pipe_lines(real_cmd)

def system(cmd):
    if verbose:
        sys.stderr.write("executing %s\n" % cmd)
    if os.system(cmd) != 0:
        die("command failed: %s" % cmd)

def p4_system(cmd):
    """Specifically invoke p4 as the system command. """
    real_cmd = p4_build_cmd(cmd)
    return system(real_cmd)

def isP4Exec(kind):
    """Determine if a Perforce 'kind' should have execute permission

    'p4 help filetypes' gives a list of the types.  If it starts with 'x',
    or x follows one of a few letters.  Otherwise, if there is an 'x' after
    a plus sign, it is also executable"""
    return (re.search(r"(^[cku]?x)|\+.*x", kind) != None)

def setP4ExecBit(file, mode):
    # Reopens an already open file and changes the execute bit to match
    # the execute bit setting in the passed in mode.

    p4Type = "+x"

    if not isModeExec(mode):
        p4Type = getP4OpenedType(file)
        p4Type = re.sub('^([cku]?)x(.*)', '\\1\\2', p4Type)
        p4Type = re.sub('(.*?\+.*?)x(.*?)', '\\1\\2', p4Type)
        if p4Type[-1] == "+":
            p4Type = p4Type[0:-1]

    p4_system("reopen -t %s %s" % (p4Type, file))

def getP4OpenedType(file):
    # Returns the perforce file type for the given file.

    result = p4_read_pipe("opened %s" % file)
    match = re.match(".*\((.+)\)\r?$", result)
    if match:
        return match.group(1)
    else:
        die("Could not determine file type for %s (result: '%s')" % (file, result))

def diffTreePattern():
    # This is a simple generator for the diff tree regex pattern. This could be
    # a class variable if this and parseDiffTreeEntry were a part of a class.
    pattern = re.compile(':(\d+) (\d+) (\w+) (\w+) ([A-Z])(\d+)?\t(.*?)((\t(.*))|$)')
    while True:
        yield pattern

def parseDiffTreeEntry(entry):
    """Parses a single diff tree entry into its component elements.

    See git-diff-tree(1) manpage for details about the format of the diff
    output. This method returns a dictionary with the following elements:

    src_mode - The mode of the source file
    dst_mode - The mode of the destination file
    src_sha1 - The sha1 for the source file
    dst_sha1 - The sha1 fr the destination file
    status - The one letter status of the diff (i.e. 'A', 'M', 'D', etc)
    status_score - The score for the status (applicable for 'C' and 'R'
                   statuses). This is None if there is no score.
    src - The path for the source file.
    dst - The path for the destination file. This is only present for
          copy or renames. If it is not present, this is None.

    If the pattern is not matched, None is returned."""

    match = diffTreePattern().next().match(entry)
    if match:
        return {
            'src_mode': match.group(1),
            'dst_mode': match.group(2),
            'src_sha1': match.group(3),
            'dst_sha1': match.group(4),
            'status': match.group(5),
            'status_score': match.group(6),
            'src': match.group(7),
            'dst': match.group(10)
        }
    return None

def isModeExec(mode):
    # Returns True if the given git mode represents an executable file,
    # otherwise False.
    return mode[-3:] == "755"

def isModeExecChanged(src_mode, dst_mode):
    return isModeExec(src_mode) != isModeExec(dst_mode)

# Some commands (eg. p4 print the entire repository) can result in gigabytes of
# data. In order to handle this without running out of memory, we have to
# process these items in batches of maybe 100 at a time. The P4CmdReader class
# handles this chunking of data.
class P4CmdReader:
    def __init__(self, cmd, stdin):
        self.MAX_CHUNKS = 100
        self.p4 = p4CmdListOpen(cmd, stdin)

    def __iter__(self):
        return self

    def next(self):
        try:
            return marshal.load(self.p4.stdout)
        except IOError, e:
            print "IOError while reading marshaller: %s" % repr(e)
            print e.strerror
            raise
        except EOFError:
            raise StopIteration

def p4CmdListOpen(cmd, stdin=None, stdin_mode='w+b'):    
    cmd = p4_build_cmd("-G %s" % (cmd))
    if verbose:
        sys.stderr.write("Opening pipe: %s\n" % cmd)

    # Use a temporary file to avoid deadlocks without
    # subprocess.communicate(), which would put another copy
    # of stdout into memory.
    stdin_file = None
    if stdin is not None:
        stdin_file = tempfile.TemporaryFile(prefix='p4-stdin', mode=stdin_mode)
        stdin_file.write(stdin)
        stdin_file.flush()
        stdin_file.seek(0)

    return subprocess.Popen(cmd, shell=True,
                          stdin=stdin_file,
                          stdout=subprocess.PIPE)
                          

def p4CmdList(cmd, stdin=None, stdin_mode='w+b'):

    p4 = p4CmdListOpen(cmd, stdin, stdin_mode)

    result = []
    try:
        while True:
            entry = marshal.load(p4.stdout)
            result.append(entry)
    except EOFError:
        pass
    exitCode = p4.wait()
    if exitCode != 0:
        entry = {}
        entry["p4ExitCode"] = exitCode
        result.append(entry)

    return result

def p4Cmd(cmd):
    list = p4CmdList(cmd)
    result = {}
    for entry in list:
        result.update(entry)
    return result;

def p4Where(depotPath):
    if not depotPath.endswith("/"):
        depotPath += "/"
    depotPath = depotPath + "..."
    outputList = p4CmdList("where %s" % depotPath)
    output = None
    for entry in outputList:
        print repr(entry)
        print "depotPath:" + depotPath
        if "depotFile" in entry:
            if entry["depotFile"] == depotPath:
                output = entry
                print "found1"
                break
        elif "data" in entry:
            data = entry.get("data")
            space = data.find(" ")
            if data[:space] == depotPath:
                output = entry
                print "found2"
                break
    else:
        print "not found"
    if output == None:
        return ""
    if output["code"] == "error":
        return ""
    clientPath = ""
    if "path" in output:
        clientPath = output.get("path")
    elif "data" in output:
        data = output.get("data")
        lastSpace = data.rfind(" ")
        clientPath = data[lastSpace + 1:]

    if clientPath.endswith("..."):
        clientPath = clientPath[:-3]
    return clientPath

def currentGitBranch():
    return read_pipe("git.cmd name-rev HEAD").split(" ")[1].strip()

def isValidGitDir(path):
    if (os.path.exists(path + "/HEAD")
        and os.path.exists(path + "/refs") and os.path.exists(path + "/objects")):
        return True;
    return False

def parseRevision(ref):
    return read_pipe("git.cmd rev-parse %s" % ref).strip()

def extractLogMessageFromGitCommit(commit):
    logMessage = ""

    ## fixme: title is first line of commit, not 1st paragraph.
    foundTitle = False
    for log in read_pipe_lines("git.cmd cat-file commit %s" % commit):
       if not foundTitle:
           if len(log) == 1:
               foundTitle = True
           continue

       logMessage += log
    return logMessage

def extractSettingsGitLog(log):
    values = {}
    for line in log.split("\n"):
        line = line.strip()
        m = re.search (r"^ *\[git-p4: (.*)\]$", line)
        if not m:
            continue

        assignments = m.group(1).split (':')
        for a in assignments:
            vals = a.split ('=')
            key = vals[0].strip()
            val = ('='.join (vals[1:])).strip()
            if val.endswith ('\"') and val.startswith('"'):
                val = val[1:-1]

            values[key] = val

    paths = values.get("depot-paths")
    if not paths:
        paths = values.get("depot-path")
    if paths:
        values['depot-paths'] = paths.split(',')
    return values

def gitBranchExists(branch):
    proc = subprocess.Popen(["git.cmd", "rev-parse", branch],
                            stderr=subprocess.PIPE, stdout=subprocess.PIPE);
    return proc.wait() == 0;

_gitConfig = {}
def gitConfig(key):
    if not _gitConfig.has_key(key):
        _gitConfig[key] = read_pipe("git.cmd config %s" % key, ignore_error=True).strip()
    return _gitConfig[key]

def p4BranchesInGit(branchesAreInRemotes = True):
    branches = {}

    cmdline = "git.cmd rev-parse --symbolic "
    if branchesAreInRemotes:
        cmdline += " --remotes"
    else:
        cmdline += " --branches"

    for line in read_pipe_lines(cmdline):
        line = line.strip()

        ## only import to p4/
        if not line.startswith('p4/') or line == "p4/HEAD":
            continue
        branch = line

        # strip off p4
        branch = re.sub ("^p4/", "", line)

        branches[branch] = parseRevision(line)
    return branches

def findUpstreamBranchPoint(head = "HEAD"):
    branches = p4BranchesInGit()
    # map from depot-path to branch name
    branchByDepotPath = {}
    for branch in branches.keys():
        tip = branches[branch]
        log = extractLogMessageFromGitCommit(tip)
        settings = extractSettingsGitLog(log)
        if settings.has_key("depot-paths"):
            paths = ",".join(settings["depot-paths"])
            branchByDepotPath[paths] = "remotes/p4/" + branch

    settings = None
    parent = 0
    while parent < 65535:
        commit = head + "~%s" % parent
        log = extractLogMessageFromGitCommit(commit)
        settings = extractSettingsGitLog(log)
        if settings.has_key("depot-paths"):
            paths = ",".join(settings["depot-paths"])
            if branchByDepotPath.has_key(paths):
                return [branchByDepotPath[paths], settings]

        parent = parent + 1

    return ["", settings]

def createOrUpdateBranchesFromOrigin(localRefPrefix = "refs/remotes/p4/", silent=True):
    if not silent:
        print ("Creating/updating branch(es) in %s based on origin branch(es)"
               % localRefPrefix)

    originPrefix = "origin/p4/"

    for line in read_pipe_lines("git.cmd rev-parse --symbolic --remotes"):
        line = line.strip()
        if (not line.startswith(originPrefix)) or line.endswith("HEAD"):
            continue

        headName = line[len(originPrefix):]
        remoteHead = localRefPrefix + headName
        originHead = line

        original = extractSettingsGitLog(extractLogMessageFromGitCommit(originHead))
        if (not original.has_key('depot-paths')
            or not original.has_key('change')):
            continue

        update = False
        if not gitBranchExists(remoteHead):
            if verbose:
                print "creating %s" % remoteHead
            update = True
        else:
            settings = extractSettingsGitLog(extractLogMessageFromGitCommit(remoteHead))
            if settings.has_key('change') > 0:
                if settings['depot-paths'] == original['depot-paths']:
                    originP4Change = int(original['change'])
                    p4Change = int(settings['change'])
                    if originP4Change > p4Change:
                        print ("%s (%s) is newer than %s (%s). "
                               "Updating p4 branch from origin."
                               % (originHead, originP4Change,
                                  remoteHead, p4Change))
                        update = True
                else:
                    print ("Ignoring: %s was imported from %s while "
                           "%s was imported from %s"
                           % (originHead, ','.join(original['depot-paths']),
                              remoteHead, ','.join(settings['depot-paths'])))

        if update:
            system("git.cmd update-ref %s %s" % (remoteHead, originHead))

def originP4BranchesExist():
        return gitBranchExists("origin") or gitBranchExists("origin/p4") or gitBranchExists("origin/p4/master")

def p4ChangesForPaths(depotPaths, changeRange):
    assert depotPaths
    output = p4_read_pipe_lines("changes " + ' '.join (["%s...%s" % (p, changeRange)
                                                        for p in depotPaths]))

    changes = []
    for line in output:
        changeNum = line.split(" ")[1]
        changes.append(int(changeNum))

    changes.sort()
    return changes

class Command:
    def __init__(self):
        self.usage = "usage: %prog [options]"
        self.needsGit = True

class P4Debug(Command):
    def __init__(self):
        Command.__init__(self)
        self.options = [
            optparse.make_option("--verbose", dest="verbose", action="store_true",
                                 default=False),
            ]
        self.description = "A tool to debug the output of p4 -G."
        self.needsGit = False
        self.verbose = False

    def run(self, args):
        j = 0
        for output in p4CmdList(" ".join(args)):
            print 'Element: %d' % j
            j += 1
            print output
        return True

class P4RollBack(Command):
    def __init__(self):
        Command.__init__(self)
        self.options = [
            optparse.make_option("--verbose", dest="verbose", action="store_true"),
            optparse.make_option("--local", dest="rollbackLocalBranches", action="store_true")
        ]
        self.description = "A tool to debug the multi-branch import. Don't use :)"
        self.verbose = False
        self.rollbackLocalBranches = False

    def run(self, args):
        if len(args) != 1:
            return False
        maxChange = int(args[0])

        if "p4ExitCode" in p4Cmd("changes -m 1"):
            die("Problems executing p4");

        if self.rollbackLocalBranches:
            refPrefix = "refs/heads/"
            lines = read_pipe_lines("git.cmd rev-parse --symbolic --branches")
        else:
            refPrefix = "refs/remotes/"
            lines = read_pipe_lines("git.cmd rev-parse --symbolic --remotes")

        for line in lines:
            if self.rollbackLocalBranches or (line.startswith("p4/") and line != "p4/HEAD\n"):
                line = line.strip()
                ref = refPrefix + line
                log = extractLogMessageFromGitCommit(ref)
                settings = extractSettingsGitLog(log)

                depotPaths = settings['depot-paths']
                change = settings['change']

                changed = False

                if len(p4Cmd("changes -m 1 "  + ' '.join (['%s...@%s' % (p, maxChange)
                                                           for p in depotPaths]))) == 0:
                    print "Branch %s did not exist at change %s, deleting." % (ref, maxChange)
                    system("git.cmd update-ref -d %s `git rev-parse %s`" % (ref, ref))
                    continue

                while change and int(change) > maxChange:
                    changed = True
                    if self.verbose:
                        print "%s is at %s ; rewinding towards %s" % (ref, change, maxChange)
                    system("git.cmd update-ref %s \"%s^\"" % (ref, ref))
                    log = extractLogMessageFromGitCommit(ref)
                    settings =  extractSettingsGitLog(log)


                    depotPaths = settings['depot-paths']
                    change = settings['change']

                if changed:
                    print "%s rewound to %s" % (ref, change)

        return True

class P4FileReader:
    Bytes = 0
    LastFile = ''
    LastBytes = 0
    def __init__(self, files, clientSpecDirs):
        # Initialize P4FileReader object with a list of files to read. This
        # takes into account the clientSpecDirs passed in.
        # Each element of files is a dictionary with the following
        # elements:
        #
        # path: The complete path to the file in the depot, starting from "//"
        # action: The action to take. Eg: 'delete' 'purge'

        # list of files to commit.
        self.filesForCommit = []

        # list of files to read, filtered according to the client spec.
        self.filesToRead = []

        # mapping from path to file record.
        self.pathMap = {}

        self.filesRead = 0

        self.filterClientSpec( files, clientSpecDirs )

        self.reader = P4CmdReader('-x - print',
                             stdin='\n'.join(['%s#%s' % (f['path'], f['rev'])
                                              for f in self.filesToRead]) )

        # leftover record from previous time next() was called.
        self.leftover = None                                      

    def filterClientSpec( self, files, clientSpecDirs ):
        # sets filesForCommit and filesToRead, filtered according to the client spec.
        for f in files:
            includeFile = False
            excludeFile = False
            if len(clientSpecDirs):
                for val in clientSpecDirs:
                    if f['path'].startswith(val[0]):
                        if val[1] > 0:
                            includeFile = True
                        else:
                            excludeFile = True
            else:
                includeFile = True

            if includeFile and not excludeFile:
                self.filesForCommit.append(f)
                self.pathMap[f['path']] = f
                if f['action'] not in ('delete', 'purge'):
                    self.filesToRead.append(f)

    def printStatus(self, filename):
        if filename == self.LastFile and self.Bytes - self.LastBytes < 100*1024: return
        self.LastFile = filename
        self.LastBytes = self.Bytes
        if len(filename) <= 60:
            line = filename + " " * (63-len(filename))
        else:
            line = "..." + filename[len(filename)-60:]

        print "%s | %.1f MB (%d/%d files)\r" % (line,
            float(self.Bytes) / (1024*1024), self.filesRead + 1,
            len(self.filesToRead)),

    def __iter__(self):
        return self

    def next(self):
        # Return a record containing a file to commit. 
        #
        # Perforce outputs a number of records for each file. The first one
        # contains basic information such as the change list and filename. This
        # is followed by a number of records containing only "code" and "data"
        # fields, which are the file data broken apart.

        # while perforce keeps giving us files we didn't ask for,
        # (Shouldn't ever happen, but handle it anyway)
        while 1:
            textBuffer = cStringIO.StringIO()

            if self.leftover:
                header = self.leftover
                self.leftover = None
            else:    
                try:
                    header = self.reader.next()
                except StopIteration:    
                    print "" # newline for status information
                    raise

            # now we have the header record.
            if not header.has_key('depotFile'):
                die("p4 print fails with: %s\n" % repr(header))

            self.printStatus(header['depotFile'])

            for record in self.reader:
                if record['code'] in ( 'text', 'unicode', 'binary' ):   
                    # encountered subsequent data chunk. Append to file data.
                    textBuffer.write( record['data'] )
                    self.Bytes += len(record['data'])
                    del record['data']
                    self.printStatus(header['depotFile'])
                else:
                    # encountered the next header.
                    # store for processing next time.
                    self.leftover = record
                    break

            text = textBuffer.getvalue()
            textBuffer.close()

            if header['type'] in ('text+ko', 'unicode+ko', 'binary+ko'):
                text = re.sub(r'(?i)\$(Id|Header):[^$]*\$',r'$\1$', text)
            elif header['type'] in ('text+k', 'ktext', 'kxtext', 'unicode+k', 'binary+k'):
                text = re.sub(r'\$(Id|Header|Author|Date|DateTime|Change|File|Revision):[^$\n]*\$',r'$\1$', text)

            file = None
            filePath = header['depotFile']
            if filePath in self.pathMap:
                file = self.pathMap[filePath]
                file['data'] = text
                self.filesRead += 1
                return file
            else:
                # perforce gave us something we didn't ask for?
                print "Bad path: %s" % filePath
                continue
            

class P4Submit(Command):
    def __init__(self):
        Command.__init__(self)
        self.options = [
                optparse.make_option("--verbose", dest="verbose", action="store_true"),
                optparse.make_option("--origin", dest="origin"),
                optparse.make_option("-M", dest="detectRename", action="store_true"),
        ]
        self.description = "Submit changes from git to the perforce depot."
        self.usage += " [name of git branch to submit into perforce depot]"
        self.interactive = True
        self.origin = ""
        self.detectRename = False
        self.verbose = False
        self.isWindows = (platform.system() == "Windows")

    def check(self):
        if len(p4CmdList("opened ...")) > 0:
            die("You have files opened with perforce! Close them before starting the sync.")

    # replaces everything between 'Description:' and the next P4 submit template field with the
    # commit message
    def prepareLogMessage(self, template, message):
        result = ""

        inDescriptionSection = False

        for line in template.split("\n"):
            if line.startswith("#"):
                result += line + "\n"
                continue

            if inDescriptionSection:
                if line.startswith("Files:"):
                    inDescriptionSection = False
                else:
                    continue
            else:
                if line.startswith("Description:"):
                    inDescriptionSection = True
                    line += "\n"
                    for messageLine in message.split("\n"):
                        line += "\t" + messageLine + "\n"

            result += line + "\n"

        return result

    def prepareSubmitTemplate(self):
        # remove lines in the Files section that show changes to files outside the depot path we're committing into
        template = ""
        inFilesSection = False
        for line in p4_read_pipe_lines("change -o"):
            if line.endswith("\r\n"):
                line = line[:-2] + "\n"
            if inFilesSection:
                if line.startswith("\t"):
                    # path starts and ends with a tab
                    path = line[1:]
                    lastTab = path.rfind("\t")
                    if lastTab != -1:
                        path = path[:lastTab]
                        if not path.startswith(self.depotPath):
                            continue
                else:
                    inFilesSection = False
            else:
                if line.startswith("Files:"):
                    inFilesSection = True

            template += line

        return template

    def applyCommit(self, id):
        print "Applying %s" % (read_pipe("git.cmd log --max-count=1 --pretty=oneline %s" % id))
        diffOpts = ("", "-M")[self.detectRename]
        diff = read_pipe_lines("git.cmd diff-tree -r %s \"%s^\" \"%s\"" % (diffOpts, id, id))
        filesToAdd = set()
        filesToDelete = set()
        editedFiles = set()
        filesToChangeExecBit = {}
        for line in diff:
            diff = parseDiffTreeEntry(line)
            modifier = diff['status']
            path = diff['src']
            if modifier == "M":
                p4_system("edit \"%s\"" % path)
                if isModeExecChanged(diff['src_mode'], diff['dst_mode']):
                    filesToChangeExecBit[path] = diff['dst_mode']
                editedFiles.add(path)
            elif modifier == "A":
                filesToAdd.add(path)
                filesToChangeExecBit[path] = diff['dst_mode']
                if path in filesToDelete:
                    filesToDelete.remove(path)
            elif modifier == "D":
                filesToDelete.add(path)
                if path in filesToAdd:
                    filesToAdd.remove(path)
            elif modifier == "R":
                src, dest = diff['src'], diff['dst']
                p4_system("integrate -Dt \"%s\" \"%s\"" % (src, dest))
                p4_system("edit \"%s\"" % (dest))
                if isModeExecChanged(diff['src_mode'], diff['dst_mode']):
                    filesToChangeExecBit[dest] = diff['dst_mode']
                os.unlink(dest)
                editedFiles.add(dest)
                filesToDelete.add(src)
            else:
                die("unknown modifier %s for %s" % (modifier, path))

        diffcmd = "git.cmd format-patch -k --stdout \"%s^\"..\"%s\"" % (id, id)
        patchcmd = diffcmd + " | git apply "
        tryPatchCmd = patchcmd + "--check -"
        applyPatchCmd = patchcmd + "--check --apply -"

        if os.system(tryPatchCmd) != 0:
            print "Unfortunately applying the change failed!"
            print "What do you want to do?"
            response = "x"
            while response != "s" and response != "a" and response != "w":
                response = raw_input("[s]kip this patch / [a]pply the patch forcibly "
                                     "and with .rej files / [w]rite the patch to a file (patch.txt) ")
            if response == "s":
                print "Skipping! Good luck with the next patches..."
                for f in editedFiles:
                    p4_system("revert \"%s\"" % f);
                for f in filesToAdd:
                    system("rm %s" %f)
                return
            elif response == "a":
                os.system(applyPatchCmd)
                if len(filesToAdd) > 0:
                    print "You may also want to call p4 add on the following files:"
                    print " ".join(filesToAdd)
                if len(filesToDelete):
                    print "The following files should be scheduled for deletion with p4 delete:"
                    print " ".join(filesToDelete)
                die("Please resolve and submit the conflict manually and "
                    + "continue afterwards with git-p4 submit --continue")
            elif response == "w":
                system(diffcmd + " > patch.txt")
                print "Patch saved to patch.txt in %s !" % self.clientPath
                die("Please resolve and submit the conflict manually and "
                    "continue afterwards with git-p4 submit --continue")

        system(applyPatchCmd)

        for f in filesToAdd:
            p4_system("add \"%s\"" % f)
        for f in filesToDelete:
            p4_system("revert \"%s\"" % f)
            p4_system("delete \"%s\"" % f)

        # Set/clear executable bits
        for f in filesToChangeExecBit.keys():
            mode = filesToChangeExecBit[f]
            setP4ExecBit(f, mode)

        logMessage = extractLogMessageFromGitCommit(id)
        logMessage = logMessage.strip()

        template = self.prepareSubmitTemplate()

        if self.interactive:
            submitTemplate = self.prepareLogMessage(template, logMessage)
            if os.environ.has_key("P4DIFF"):
                del(os.environ["P4DIFF"])
            diff = p4_read_pipe("diff -du ...")

            newdiff = ""
            for newFile in filesToAdd:
                newdiff += "==== new file ====\n"
                newdiff += "--- /dev/null\n"
                newdiff += "+++ %s\n" % newFile
                f = open(newFile, "r")
                for line in f.readlines():
                    newdiff += "+" + line
                f.close()

            separatorLine = "######## everything below this line is just the diff #######\n"

            [handle, fileName] = tempfile.mkstemp()
            tmpFile = os.fdopen(handle, "w+")
            if self.isWindows:
                submitTemplate = submitTemplate.replace("\n", "\r\n")
                separatorLine = separatorLine.replace("\n", "\r\n")
                newdiff = newdiff.replace("\n", "\r\n")
            tmpFile.write(submitTemplate + separatorLine + diff + newdiff)
            tmpFile.close()
            mtime = os.stat(fileName).st_mtime
            defaultEditor = "vi"
            if platform.system() == "Windows":
                defaultEditor = "notepad"
            if os.environ.has_key("P4EDITOR"):
                editor = os.environ.get("P4EDITOR")
            else:
                editor = os.environ.get("EDITOR", defaultEditor);
            system(editor + " " + fileName)

            response = "y"
            if os.stat(fileName).st_mtime <= mtime:
                response = "x"
                while response != "y" and response != "n":
                    response = raw_input("Submit template unchanged. Submit anyway? [y]es, [n]o (skip this patch) ")

            if response == "y":
                tmpFile = open(fileName, "rb")
                message = tmpFile.read()
                tmpFile.close()
                submitTemplate = message[:message.index(separatorLine)]
                if self.isWindows:
                    submitTemplate = submitTemplate.replace("\r\n", "\n")
                p4_write_pipe("submit -i", submitTemplate)
            else:
                for f in editedFiles:
                    p4_system("revert \"%s\"" % f);
                for f in filesToAdd:
                    p4_system("revert \"%s\"" % f);
                    system("rm %s" %f)

            os.remove(fileName)
        else:
            fileName = "submit.txt"
            file = open(fileName, "w+")
            file.write(self.prepareLogMessage(template, logMessage))
            file.close()
            print ("Perforce submit template written as %s. "
                   + "Please review/edit and then use p4 submit -i < %s to submit directly!"
                   % (fileName, fileName))

    def run(self, args):
        if len(args) == 0:
            self.master = currentGitBranch()
            if len(self.master) == 0 or not gitBranchExists("refs/heads/%s" % self.master):
                die("Detecting current git branch failed!")
        elif len(args) == 1:
            self.master = args[0]
        else:
            return False

        allowSubmit = gitConfig("git-p4.allowSubmit")
        if len(allowSubmit) > 0 and not self.master in allowSubmit.split(","):
            die("%s is not in git-p4.allowSubmit" % self.master)

        [upstream, settings] = findUpstreamBranchPoint()
        self.depotPath = settings['depot-paths'][0]
        if len(self.origin) == 0:
            self.origin = upstream

        if self.verbose:
            print "Origin branch is " + self.origin

        if len(self.depotPath) == 0:
            print "Internal error: cannot locate perforce depot path from existing branches"
            sys.exit(128)

        self.clientPath = p4Where(self.depotPath)

        if len(self.clientPath) == 0:
            print "Error: Cannot locate perforce checkout of %s in client view" % self.depotPath
            sys.exit(128)

        print "Perforce checkout for depot path %s located at %s" % (self.depotPath, self.clientPath)
        self.oldWorkingDirectory = os.getcwd()

        chdir(self.clientPath)
        print "Syncronizing p4 checkout..."
        p4_system("sync ...")

        self.check()

        commits = []
        for line in read_pipe_lines("git.cmd rev-list --no-merges %s..%s" % (self.origin, self.master)):
            commits.append(line.strip())
        commits.reverse()

        while len(commits) > 0:
            commit = commits[0]
            commits = commits[1:]
            self.applyCommit(commit)
            if not self.interactive:
                break

        if len(commits) == 0:
            print "All changes applied!"
            chdir(self.oldWorkingDirectory)

            sync = P4Sync()
            sync.run([])

            rebase = P4Rebase()
            rebase.rebase()

        return True

class P4Sync(Command):
    def __init__(self):
        Command.__init__(self)
        self.options = [
                optparse.make_option("--branch", dest="branch"),
                optparse.make_option("--detect-branches", dest="detectBranches", action="store_true"),
                optparse.make_option("--changesfile", dest="changesFile"),
                optparse.make_option("--silent", dest="silent", action="store_true"),
                optparse.make_option("--detect-labels", dest="detectLabels", action="store_true"),
                optparse.make_option("--verbose", dest="verbose", action="store_true"),
                optparse.make_option("--import-local", dest="importIntoRemotes", action="store_false",
                                     help="Import into refs/heads/ , not refs/remotes"),
                optparse.make_option("--max-changes", dest="maxChanges"),
                optparse.make_option("--keep-path", dest="keepRepoPath", action='store_true',
                                     help="Keep entire BRANCH/DIR/SUBDIR prefix during import"),
                optparse.make_option("--use-client-spec", dest="useClientSpec", action='store_true',
                                     help="Only sync files that are included in the Perforce Client Spec")
        ]
        self.description = """Imports from Perforce into a git repository.\n
    example:
    //depot/my/project/ -- to import the current head
    //depot/my/project/@all -- to import everything
    //depot/my/project/@1,6 -- to import only from revision 1 to 6

    (a ... is not needed in the path p4 specification, it's added implicitly)"""

        self.usage += " //depot/path[@revRange]"
        self.silent = False
        self.createdBranches = Set()
        self.committedChanges = Set()
        self.branch = ""
        self.detectBranches = False
        self.detectLabels = False
        self.changesFile = ""
        self.syncWithOrigin = True
        self.verbose = False
        self.importIntoRemotes = True
        self.maxChanges = ""
        self.isWindows = (platform.system() == "Windows")
        self.keepRepoPath = False
        self.depotPaths = None
        self.p4BranchesInGit = []
        self.cloneExclude = []
        self.useClientSpec = False
        self.clientSpecDirs = []

        if gitConfig("git-p4.syncFromOrigin") == "false":
            self.syncWithOrigin = False

    def extractFilesFromCommit(self, commit):
        self.cloneExclude = [re.sub(r"\.\.\.$", "", path)
                             for path in self.cloneExclude]
        files = []
        fnum = 0
        while commit.has_key("depotFile%s" % fnum):
            path =  commit["depotFile%s" % fnum]

            if [p for p in self.cloneExclude
                if path.startswith (p)]:
                found = False
            else:
                found = [p for p in self.depotPaths
                         if path.startswith (p)]
            if not found:
                fnum = fnum + 1
                continue

            file = {}
            file["path"] = path
            file["rev"] = commit["rev%s" % fnum]
            file["action"] = commit["action%s" % fnum]
            file["type"] = commit["type%s" % fnum]
            files.append(file)
            fnum = fnum + 1
        return files

    def stripRepoPath(self, path, prefixes):
        if self.keepRepoPath:
            prefixes = [re.sub("^(//[^/]+/).*", r'\1', prefixes[0])]

        for p in prefixes:
            if path.startswith(p):
                path = path[len(p):]

        return path

    def splitFilesIntoBranches(self, commit):
        branches = {}
        fnum = 0
        while commit.has_key("depotFile%s" % fnum):
            path =  commit["depotFile%s" % fnum]
            found = [p for p in self.depotPaths
                     if path.startswith (p)]
            if not found:
                fnum = fnum + 1
                continue

            file = {}
            file["path"] = path
            file["rev"] = commit["rev%s" % fnum]
            file["action"] = commit["action%s" % fnum]
            file["type"] = commit["type%s" % fnum]
            fnum = fnum + 1

            relPath = self.stripRepoPath(path, self.depotPaths)

            for branch in self.knownBranches.keys():

                # add a trailing slash so that a commit into qt/4.2foo doesn't end up in qt/4.2
                if relPath.startswith(branch + "/"):
                    if branch not in branches:
                        branches[branch] = []
                    branches[branch].append(file)
                    break

        return branches

    def readP4Files(self, files):
        filesForCommit = []
        filesToRead = []

        # filter files by clientspec. Also, don't get the contents of files
        # which we are to delete or purge.
        for f in files:
            includeFile = False
            excludeFile = False
            for val in self.clientSpecDirs:
                if f['path'].startswith(val[0]):
                    if val[1] > 0:
                        includeFile = True
                    else:
                        excludeFile = True

            if includeFile and not excludeFile:
                filesForCommit.append(f)
                if f['action'] not in ('delete', 'purge'):
                    filesToRead.append(f)

        filedata = []
        if len(filesToRead) > 0:
            filedata = p4CmdList('-x - print',
                                 stdin='\n'.join(['%s#%s' % (f['path'], f['rev'])
                                                  for f in filesToRead]),
                                 stdin_mode='w+')

            if "p4ExitCode" in filedata[0]:
                die("Problems executing p4. Error: [%d]."
                    % (filedata[0]['p4ExitCode']));

        # Perforce outputs a number of records for each file. The first one
        # contains basic information such as the change list and filename. This
        # is followed by a number of records containing only "code" and "data"
        # fields, which are the file data broken apart.
        j = 0;
        contents = {}
        # for each file,
        while j < len(filedata):
            stat = filedata[j]
            j += 1
            text = ''
            # if it's not the last file and it's code type is text, unicode, or
            # binary,
            while j < len(filedata) and filedata[j]['code'] in ('text', 'unicode', 'binary'):
                # add the contents of the file to text.
                # repeat for all other files.
                text += filedata[j]['data']
                del filedata[j]['data']
                j += 1

            if not stat.has_key('depotFile'):
                sys.stderr.write("p4 print fails with: %s\n" % repr(stat))
                continue

            if stat['type'] in ('text+ko', 'unicode+ko', 'binary+ko'):
                text = re.sub(r'(?i)\$(Id|Header):[^$]*\$',r'$\1$', text)
            elif stat['type'] in ('text+k', 'ktext', 'kxtext', 'unicode+k', 'binary+k'):
                text = re.sub(r'\$(Id|Header|Author|Date|DateTime|Change|File|Revision):[^$\n]*\$',r'$\1$', text)

            contents[stat['depotFile']] = text

        for f in filesForCommit:
            path = f['path']
            if contents.has_key(path):
                f['data'] = contents[path]

        return filesForCommit

    def commit(self, details, files, branch, branchPrefixes, parent = ""):
        epoch = details["time"]
        author = details["user"]

        if self.verbose:
            print "commit into %s" % branch

        # start with reading files; if that fails, we should not
        # create a commit.
        new_files = []
        for f in files:
            if [p for p in branchPrefixes if f['path'].startswith(p)]:
                new_files.append (f)
            else:
                sys.stderr.write("Ignoring file outside of prefix: %s\n" % path)

        #files = self.readP4Files(new_files)

        self.gitStream.write("commit %s\n" % branch)
#        gitStream.write("mark :%s\n" % details["change"])
        self.committedChanges.add(int(details["change"]))
        committer = ""
        if author not in self.users:
            self.getUserMapFromPerforceServer()
        if author in self.users:
            committer = "%s %s %s" % (self.users[author], epoch, self.tz)
        else:
            committer = "%s <a@b> %s %s" % (author, epoch, self.tz)

        self.gitStream.write("committer %s\n" % committer)

        self.gitStream.write("data <<EOT\n")
        self.gitStream.write(details["desc"])
        self.gitStream.write("\n[git-p4: depot-paths = \"%s\": change = %s"
                             % (','.join (branchPrefixes), details["change"]))
        if len(details['options']) > 0:
            self.gitStream.write(": options = %s" % details['options'])
        self.gitStream.write("]\nEOT\n\n")

        if len(parent) > 0:
            if self.verbose:
                print "parent %s" % parent
            self.gitStream.write("from %s\n" % parent)

        for file in P4FileReader( new_files, self.clientSpecDirs ):
            if file["type"] == "apple":
                print "\nfile %s is a strange apple file that forks. Ignoring!" % file['path']
                continue

            relPath = self.stripRepoPath(file['path'], branchPrefixes)
            if file["action"] in ("delete", "purge"):
                self.gitStream.write("D %s\n" % relPath)
            else:
                data = file['data']
                del file['data']

                mode = "644"
                if isP4Exec(file["type"]):
                    mode = "755"
                elif file["type"] == "symlink":
                    mode = "120000"
                    # p4 print on a symlink contains "target\n", so strip it off
                    data = data[:-1]

                if self.isWindows and file["type"].endswith("text"):
                    data = data.replace("\r\n", "\n")

                self.gitStream.write("M %s inline %s\n" % (mode, relPath))
                self.gitStream.write("data %s\n" % len(data))
                self.gitStream.write(data)
                self.gitStream.write("\n")

        self.gitStream.write("\n")

        change = int(details["change"])

        if self.labels.has_key(change):
            label = self.labels[change]
            labelDetails = label[0]
            labelRevisions = label[1]
            if self.verbose:
                print "Change %s is labelled %s" % (change, labelDetails)

            files = p4CmdList("files " + ' '.join (["%s...@%s" % (p, change)
                                                    for p in branchPrefixes]))

            if len(files) == len(labelRevisions):

                cleanedFiles = {}
                for info in files:
                    if info["action"] in ("delete", "purge"):
                        continue
                    cleanedFiles[info["depotFile"]] = info["rev"]

                if cleanedFiles == labelRevisions:
                    self.gitStream.write("tag tag_%s\n" % labelDetails["label"])
                    self.gitStream.write("from %s\n" % branch)

                    owner = labelDetails["Owner"]
                    tagger = ""
                    if author in self.users:
                        tagger = "%s %s %s" % (self.users[owner], epoch, self.tz)
                    else:
                        tagger = "%s <a@b> %s %s" % (owner, epoch, self.tz)
                    self.gitStream.write("tagger %s\n" % tagger)
                    self.gitStream.write("data <<EOT\n")
                    self.gitStream.write(labelDetails["Description"])
                    self.gitStream.write("EOT\n\n")

                else:
                    if not self.silent:
                        print ("Tag %s does not match with change %s: files do not match."
                               % (labelDetails["label"], change))

            else:
                if not self.silent:
                    print ("Tag %s does not match with change %s: file count is different."
                           % (labelDetails["label"], change))

    def getUserCacheFilename(self):
        home = os.environ.get("HOME", os.environ.get("USERPROFILE"))
        return home + "/.gitp4-usercache.txt"

    def getUserMapFromPerforceServer(self):
        if self.userMapFromPerforceServer:
            return
        self.users = {}

        for output in p4CmdList("users"):
            if not output.has_key("User"):
                continue
            self.users[output["User"]] = output["FullName"] + " <" + output["Email"] + ">"


        s = ''
        for (key, val) in self.users.items():
            s += "%s\t%s\n" % (key, val)

        open(self.getUserCacheFilename(), "wb").write(s)
        self.userMapFromPerforceServer = True

    def loadUserMapFromCache(self):
        self.users = {}
        self.userMapFromPerforceServer = False
        try:
            cache = open(self.getUserCacheFilename(), "rb")
            lines = cache.readlines()
            cache.close()
            for line in lines:
                entry = line.strip().split("\t")
                self.users[entry[0]] = entry[1]
        except IOError:
            self.getUserMapFromPerforceServer()

    def getLabels(self):
        self.labels = {}

        l = p4CmdList("labels %s..." % ' '.join (self.depotPaths))
        if len(l) > 0 and not self.silent:
            print "Finding files belonging to labels in %s" % `self.depotPaths`

        for output in l:
            label = output["label"]
            revisions = {}
            newestChange = 0
            if self.verbose:
                print "Querying files for label %s" % label
            for file in p4CmdList("files "
                                  +  ' '.join (["%s...@%s" % (p, label)
                                                for p in self.depotPaths])):
                revisions[file["depotFile"]] = file["rev"]
                change = int(file["change"])
                if change > newestChange:
                    newestChange = change

            self.labels[newestChange] = [output, revisions]

        if self.verbose:
            print "Label changes: %s" % self.labels.keys()

    def guessProjectName(self):
        for p in self.depotPaths:
            if p.endswith("/"):
                p = p[:-1]
            p = p[p.strip().rfind("/") + 1:]
            if not p.endswith("/"):
               p += "/"
            return p

    def getBranchMapping(self):
        lostAndFoundBranches = set()

        for info in p4CmdList("branches"):
            details = p4Cmd("branch -o %s" % info["branch"])
            viewIdx = 0
            while details.has_key("View%s" % viewIdx):
                paths = details["View%s" % viewIdx].split(" ")
                viewIdx = viewIdx + 1
                # require standard //depot/foo/... //depot/bar/... mapping
                if len(paths) != 2 or not paths[0].endswith("/...") or not paths[1].endswith("/..."):
                    continue
                source = paths[0]
                destination = paths[1]
                ## HACK
                if source.startswith(self.depotPaths[0]) and destination.startswith(self.depotPaths[0]):
                    source = source[len(self.depotPaths[0]):-4]
                    destination = destination[len(self.depotPaths[0]):-4]

                    if destination in self.knownBranches:
                        if not self.silent:
                            print "p4 branch %s defines a mapping from %s to %s" % (info["branch"], source, destination)
                            print "but there exists another mapping from %s to %s already!" % (self.knownBranches[destination], destination)
                        continue

                    self.knownBranches[destination] = source

                    lostAndFoundBranches.discard(destination)

                    if source not in self.knownBranches:
                        lostAndFoundBranches.add(source)


        for branch in lostAndFoundBranches:
            self.knownBranches[branch] = branch

    def getBranchMappingFromGitBranches(self):
        branches = p4BranchesInGit(self.importIntoRemotes)
        for branch in branches.keys():
            if branch == "master":
                branch = "main"
            else:
                branch = branch[len(self.projectName):]
            self.knownBranches[branch] = branch

    def listExistingP4GitBranches(self):
        # branches holds mapping from name to commit
        branches = p4BranchesInGit(self.importIntoRemotes)
        self.p4BranchesInGit = branches.keys()
        for branch in branches.keys():
            self.initialParents[self.refPrefix + branch] = branches[branch]

    def updateOptionDict(self, d):
        option_keys = {}
        if self.keepRepoPath:
            option_keys['keepRepoPath'] = 1

        d["options"] = ' '.join(sorted(option_keys.keys()))

    def readOptions(self, d):
        self.keepRepoPath = (d.has_key('options')
                             and ('keepRepoPath' in d['options']))

    def gitRefForBranch(self, branch):
        if branch == "main":
            return self.refPrefix + "master"

        if len(branch) <= 0:
            return branch

        return self.refPrefix + self.projectName + branch

    def gitCommitByP4Change(self, ref, change):
        if self.verbose:
            print "looking in ref " + ref + " for change %s using bisect..." % change

        earliestCommit = ""
        latestCommit = parseRevision(ref)

        while True:
            if self.verbose:
                print "trying: earliest %s latest %s" % (earliestCommit, latestCommit)
            next = read_pipe("git.cmd rev-list --bisect %s %s" % (latestCommit, earliestCommit)).strip()
            if len(next) == 0:
                if self.verbose:
                    print "argh"
                return ""
            log = extractLogMessageFromGitCommit(next)
            settings = extractSettingsGitLog(log)
            currentChange = int(settings['change'])
            if self.verbose:
                print "current change %s" % currentChange

            if currentChange == change:
                if self.verbose:
                    print "found %s" % next
                return next

            if currentChange < change:
                earliestCommit = "^%s" % next
            else:
                latestCommit = "%s" % next

        return ""

    def importNewBranch(self, branch, maxChange):
        # make fast-import flush all changes to disk and update the refs using the checkpoint
        # command so that we can try to find the branch parent in the git history
        self.gitStream.write("checkpoint\n\n");
        self.gitStream.flush();
        branchPrefix = self.depotPaths[0] + branch + "/"
        range = "@1,%s" % maxChange
        #print "prefix" + branchPrefix
        changes = p4ChangesForPaths([branchPrefix], range)
        if len(changes) <= 0:
            return False
        firstChange = changes[0]
        #print "first change in branch: %s" % firstChange
        sourceBranch = self.knownBranches[branch]
        sourceDepotPath = self.depotPaths[0] + sourceBranch
        sourceRef = self.gitRefForBranch(sourceBranch)
        #print "source " + sourceBranch

        branchParentChange = int(p4Cmd("changes -m 1 %s...@1,%s" % (sourceDepotPath, firstChange))["change"])
        #print "branch parent: %s" % branchParentChange
        gitParent = self.gitCommitByP4Change(sourceRef, branchParentChange)
        if len(gitParent) > 0:
            self.initialParents[self.gitRefForBranch(branch)] = gitParent
            #print "parent git commit: %s" % gitParent

        self.importChanges(changes)
        return True

    def importChanges(self, changes):
        cnt = 1
        for change in changes:
            description = p4Cmd("describe %s" % change)
            self.updateOptionDict(description)

            if not self.silent:
                sys.stdout.write("\rImporting revision %s (%s%%)" % (change, cnt * 100 / len(changes)))
                sys.stdout.flush()
            cnt = cnt + 1

            try:
                if self.detectBranches:
                    branches = self.splitFilesIntoBranches(description)
                    for branch in branches.keys():
                        ## HACK  --hwn
                        branchPrefix = self.depotPaths[0] + branch + "/"

                        parent = ""

                        filesForCommit = branches[branch]

                        if self.verbose:
                            print "branch is %s" % branch

                        self.updatedBranches.add(branch)

                        if branch not in self.createdBranches:
                            self.createdBranches.add(branch)
                            parent = self.knownBranches[branch]
                            if parent == branch:
                                parent = ""
                            else:
                                fullBranch = self.projectName + branch
                                if fullBranch not in self.p4BranchesInGit:
                                    if not self.silent:
                                        print("\n    Importing new branch %s" % fullBranch);
                                    if self.importNewBranch(branch, change - 1):
                                        parent = ""
                                        self.p4BranchesInGit.append(fullBranch)
                                    if not self.silent:
                                        print("\n    Resuming with change %s" % change);

                                if self.verbose:
                                    print "parent determined through known branches: %s" % parent

                        branch = self.gitRefForBranch(branch)
                        parent = self.gitRefForBranch(parent)

                        if self.verbose:
                            print "looking for initial parent for %s; current parent is %s" % (branch, parent)

                        if len(parent) == 0 and branch in self.initialParents:
                            parent = self.initialParents[branch]
                            del self.initialParents[branch]

                        self.commit(description, filesForCommit, branch, [branchPrefix], parent)
                else:
                    files = self.extractFilesFromCommit(description)
                    self.commit(description, files, self.branch, self.depotPaths,
                                self.initialParent)
                    self.initialParent = ""
            except IOError:
                print self.gitError.read()
                sys.exit(1)

    def importHeadRevision(self, revision):
        print "Doing initial import of %s from revision %s into %s" % (' '.join(self.depotPaths), revision, self.branch)

        details = { "user" : "git.cmd perforce import user", "time" : int(time.time()) }
        details["desc"] = ("Initial import of %s from the state at revision %s"
                           % (' '.join(self.depotPaths), revision))
        details["change"] = revision
        newestRevision = 0

        fileCnt = 0
        for info in p4CmdList("files "
                              +  ' '.join(["%s...%s"
                                           % (p, revision)
                                           for p in self.depotPaths])):

            if info['code'] == 'error':
                sys.stderr.write("p4 returned an error: %s\n"
                                 % info['data'])
                sys.exit(1)


            change = int(info["change"])
            if change > newestRevision:
                newestRevision = change

            if info["action"] in ("delete", "purge"):
                # don't increase the file cnt, otherwise details["depotFile123"] will have gaps!
                #fileCnt = fileCnt + 1
                continue

            for prop in ["depotFile", "rev", "action", "type" ]:
                details["%s%s" % (prop, fileCnt)] = info[prop]

            fileCnt = fileCnt + 1

        details["change"] = newestRevision
        self.updateOptionDict(details)
        #try:
        self.commit(details, self.extractFilesFromCommit(details), self.branch, self.depotPaths)
        #except IOError:
        #    print "IO error with git fast-import. Is your git version recent enough?"
        #    print self.gitError.read()


    def getClientSpec(self):
        # fill in self.clientSpecDirs, with a map from folder names to an
        # integer. If the integer is positive, the folder name maps to its
        # length. If the integer is negative, the folder name maps to its
        # negative length, and was explicitly excluded.
        specList = p4CmdList( "client -o" )
        temp = {}
        for entry in specList:
            for k,v in entry.iteritems():
                if k.startswith("View"):
                    if v.startswith('"'):
                        start = 1
                    else:
                        start = 0
                    index = v.find("...")
                    v = v[start:index]
                    if v.startswith("-"):
                        v = v[1:]
                        temp[v] = -len(v)
                    else:
                        temp[v] = len(v)
        self.clientSpecDirs = temp.items()
        self.clientSpecDirs.sort( lambda x, y: abs( y[1] ) - abs( x[1] ) )

    def run(self, args):
        self.depotPaths = []
        self.changeRange = ""
        self.initialParent = ""
        self.previousDepotPaths = []

        # map from branch depot path to parent branch
        self.knownBranches = {}
        self.initialParents = {}
        self.hasOrigin = originP4BranchesExist()
        if not self.syncWithOrigin:
            self.hasOrigin = False

        if self.importIntoRemotes:
            self.refPrefix = "refs/remotes/p4/"
        else:
            self.refPrefix = "refs/heads/p4/"

        if self.syncWithOrigin and self.hasOrigin:
            if not self.silent:
                print "Syncing with origin first by calling git fetch origin"
            system("git.cmd fetch origin")

        if len(self.branch) == 0:
            self.branch = self.refPrefix + "master"
            if gitBranchExists("refs/heads/p4") and self.importIntoRemotes:
                system("git.cmd update-ref %s refs/heads/p4" % self.branch)
                system("git.cmd branch -D p4");
            # create it /after/ importing, when master exists
            if not gitBranchExists(self.refPrefix + "HEAD") and self.importIntoRemotes and gitBranchExists(self.branch):
                system("git.cmd symbolic-ref %sHEAD %s" % (self.refPrefix, self.branch))

        if self.useClientSpec or gitConfig("git-p4.useclientspec") == "true":
            self.getClientSpec()

        # TODO: should always look at previous commits,
        # merge with previous imports, if possible.
        if args == []:
            if self.hasOrigin:
                createOrUpdateBranchesFromOrigin(self.refPrefix, self.silent)
            self.listExistingP4GitBranches()

            if len(self.p4BranchesInGit) > 1:
                if not self.silent:
                    print "Importing from/into multiple branches"
                self.detectBranches = True

            if self.verbose:
                print "branches: %s" % self.p4BranchesInGit

            p4Change = 0
            for branch in self.p4BranchesInGit:
                logMsg =  extractLogMessageFromGitCommit(self.refPrefix + branch)

                settings = extractSettingsGitLog(logMsg)

                self.readOptions(settings)
                if (settings.has_key('depot-paths')
                    and settings.has_key ('change')):
                    change = int(settings['change']) + 1
                    p4Change = max(p4Change, change)

                    depotPaths = sorted(settings['depot-paths'])
                    if self.previousDepotPaths == []:
                        self.previousDepotPaths = depotPaths
                    else:
                        paths = []
                        for (prev, cur) in zip(self.previousDepotPaths, depotPaths):
                            for i in range(0, min(len(cur), len(prev))):
                                if cur[i] <> prev[i]:
                                    i = i - 1
                                    break

                            paths.append (cur[:i + 1])

                        self.previousDepotPaths = paths

            if p4Change > 0:
                self.depotPaths = sorted(self.previousDepotPaths)
                self.changeRange = "@%s,#head" % p4Change
                if not self.detectBranches:
                    self.initialParent = parseRevision(self.branch)
                if not self.silent and not self.detectBranches:
                    print "Performing incremental import into %s git branch" % self.branch

        if not self.branch.startswith("refs/"):
            self.branch = "refs/heads/" + self.branch

        if len(args) == 0 and self.depotPaths:
            if not self.silent:
                print "Depot paths: %s" % ' '.join(self.depotPaths)
        else:
            if self.depotPaths and self.depotPaths != args:
                print ("previous import used depot path %s and now %s was specified. "
                       "This doesn't work!" % (' '.join (self.depotPaths),
                                               ' '.join (args)))
                sys.exit(1)

            self.depotPaths = sorted(args)

        revision = ""
        self.users = {}

        newPaths = []
        for p in self.depotPaths:
            if p.find("@") != -1:
                atIdx = p.index("@")
                self.changeRange = p[atIdx:]
                if self.changeRange == "@all":
                    self.changeRange = ""
                elif ',' not in self.changeRange:
                    revision = self.changeRange
                    self.changeRange = ""
                p = p[:atIdx]
            elif p.find("#") != -1:
                hashIdx = p.index("#")
                revision = p[hashIdx:]
                p = p[:hashIdx]
            elif self.previousDepotPaths == []:
                revision = "#head"

            p = re.sub ("\.\.\.$", "", p)
            if not p.endswith("/"):
                p += "/"

            newPaths.append(p)

        self.depotPaths = newPaths


        self.loadUserMapFromCache()
        self.labels = {}
        if self.detectLabels:
            self.getLabels();

        if self.detectBranches:
            ## FIXME - what's a P4 projectName ?
            self.projectName = self.guessProjectName()

            if self.hasOrigin:
                self.getBranchMappingFromGitBranches()
            else:
                self.getBranchMapping()
            if self.verbose:
                print "p4-git branches: %s" % self.p4BranchesInGit
                print "initial parents: %s" % self.initialParents
            for b in self.p4BranchesInGit:
                if b != "master":

                    ## FIXME
                    b = b[len(self.projectName):]
                self.createdBranches.add(b)

        self.tz = "%+03d%02d" % (- time.timezone / 3600, ((- time.timezone % 3600) / 60))

        importProcess = subprocess.Popen(["git.cmd", "fast-import"],
                                         stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                         stderr=subprocess.PIPE);
        self.gitOutput = importProcess.stdout
        self.gitStream = LargeFileWriter(importProcess.stdin)
        self.gitError = importProcess.stderr

        if revision:
            self.importHeadRevision(revision)
        else:
            changes = []

            if len(self.changesFile) > 0:
                output = open(self.changesFile).readlines()
                changeSet = Set()
                for line in output:
                    changeSet.add(int(line))

                for change in changeSet:
                    changes.append(change)

                changes.sort()
            else:
                if self.verbose:
                    print "Getting p4 changes for %s...%s" % (', '.join(self.depotPaths),
                                                              self.changeRange)
                changes = p4ChangesForPaths(self.depotPaths, self.changeRange)

                if len(self.maxChanges) > 0:
                    changes = changes[:min(int(self.maxChanges), len(changes))]

            if len(changes) == 0:
                if not self.silent:
                    print "No changes to import!"
                return True

            if not self.silent and not self.detectBranches:
                print "Import destination: %s" % self.branch

            self.updatedBranches = set()

            self.importChanges(changes)

            if not self.silent:
                print ""
                if len(self.updatedBranches) > 0:
                    sys.stdout.write("Updated branches: ")
                    for b in self.updatedBranches:
                        sys.stdout.write("%s " % b)
                    sys.stdout.write("\n")

        self.gitStream.close()
        if importProcess.wait() != 0:
            die("fast-import failed: %s" % self.gitError.read())
        self.gitOutput.close()
        self.gitError.close()

        return True

class P4Rebase(Command):
    def __init__(self):
        Command.__init__(self)
        self.options = [ ]
        self.description = ("Fetches the latest revision from perforce and "
                            + "rebases the current work (branch) against it")
        self.verbose = False

    def run(self, args):
        sync = P4Sync()
        sync.run([])

        return self.rebase()

    def rebase(self):
        if os.system("git.cmd update-index --refresh") != 0:
            die("Some files in your working directory are modified and different than what is in your index. You can use git update-index <filename> to bring the index up-to-date or stash away all your changes with git stash.");
        if len(read_pipe("git.cmd diff-index HEAD --")) > 0:
            die("You have uncommited changes. Please commit them before rebasing or stash them away with git stash.");

        [upstream, settings] = findUpstreamBranchPoint()
        if len(upstream) == 0:
            die("Cannot find upstream branchpoint for rebase")

        # the branchpoint may be p4/foo~3, so strip off the parent
        upstream = re.sub("~[0-9]+$", "", upstream)

        print "Rebasing the current branch onto %s" % upstream
        oldHead = read_pipe("git.cmd rev-parse HEAD").strip()
        system("git.cmd rebase %s" % upstream)
        system("git.cmd diff-tree --stat --summary -M %s HEAD" % oldHead)
        return True

class P4Clone(P4Sync):
    def __init__(self):
        P4Sync.__init__(self)
        self.description = "Creates a new git repository and imports from Perforce into it"
        self.usage = "usage: %prog [options] //depot/path[@revRange]"
        self.options += [
            optparse.make_option("--destination", dest="cloneDestination",
                                 action='store', default=None,
                                 help="where to leave result of the clone"),
            optparse.make_option("-/", dest="cloneExclude",
                                 action="append", type="string",
                                 help="exclude depot path")
        ]
        self.cloneDestination = None
        self.needsGit = False

    # This is required for the "append" cloneExclude action
    def ensure_value(self, attr, value):
        if not hasattr(self, attr) or getattr(self, attr) is None:
            setattr(self, attr, value)
        return getattr(self, attr)

    def defaultDestination(self, args):
        ## TODO: use common prefix of args?
        depotPath = args[0]
        depotDir = re.sub("(@[^@]*)$", "", depotPath)
        depotDir = re.sub("(#[^#]*)$", "", depotDir)
        depotDir = re.sub(r"\.\.\.$", "", depotDir)
        depotDir = re.sub(r"/$", "", depotDir)
        return os.path.split(depotDir)[1]

    def run(self, args):
        if len(args) < 1:
            return False

        if self.keepRepoPath and not self.cloneDestination:
            sys.stderr.write("Must specify destination for --keep-path\n")
            sys.exit(1)

        depotPaths = args

        if not self.cloneDestination and len(depotPaths) > 1:
            self.cloneDestination = depotPaths[-1]
            depotPaths = depotPaths[:-1]

        self.cloneExclude = ["/"+p for p in self.cloneExclude]
        for p in depotPaths:
            if not p.startswith("//"):
                return False

        if not self.cloneDestination:
            self.cloneDestination = self.defaultDestination(args)

        print "Importing from %s into %s" % (', '.join(depotPaths), self.cloneDestination)
        if not os.path.exists(self.cloneDestination):
            os.makedirs(self.cloneDestination)
        chdir(self.cloneDestination)
        system("git.cmd init")
        self.gitdir = os.getcwd() + "/.git"
        if not P4Sync.run(self, depotPaths):
            return False
        if self.branch != "master":
            if self.importIntoRemotes:
                masterbranch = "refs/remotes/p4/master"
            else:
                masterbranch = "refs/heads/p4/master"
            if gitBranchExists(masterbranch):
                system("git.cmd branch master %s" % masterbranch)
                system("git.cmd checkout -f")
            else:
                print "Could not detect main branch. No checkout/master branch created."

        return True

class P4Branches(Command):
    def __init__(self):
        Command.__init__(self)
        self.options = [ ]
        self.description = ("Shows the git branches that hold imports and their "
                            + "corresponding perforce depot paths")
        self.verbose = False

    def run(self, args):
        if originP4BranchesExist():
            createOrUpdateBranchesFromOrigin()

        cmdline = "git.cmd rev-parse --symbolic "
        cmdline += " --remotes"

        for line in read_pipe_lines(cmdline):
            line = line.strip()

            if not line.startswith('p4/') or line == "p4/HEAD":
                continue
            branch = line

            log = extractLogMessageFromGitCommit("refs/remotes/%s" % branch)
            settings = extractSettingsGitLog(log)

            print "%s <= %s (%s)" % (branch, ",".join(settings["depot-paths"]), settings["change"])
        return True

class HelpFormatter(optparse.IndentedHelpFormatter):
    def __init__(self):
        optparse.IndentedHelpFormatter.__init__(self)

    def format_description(self, description):
        if description:
            return description + "\n"
        else:
            return ""

def printUsage(commands):
    print "usage: %s <command> [options]" % sys.argv[0]
    print ""
    print "valid commands: %s" % ", ".join(commands)
    print ""
    print "Try %s <command> --help for command specific help." % sys.argv[0]
    print ""

commands = {
    "debug" : P4Debug,
    "submit" : P4Submit,
    "commit" : P4Submit,
    "sync" : P4Sync,
    "rebase" : P4Rebase,
    "clone" : P4Clone,
    "rollback" : P4RollBack,
    "branches" : P4Branches
}


def main():
    if len(sys.argv[1:]) == 0:
        printUsage(commands.keys())
        sys.exit(2)

    cmd = ""
    cmdName = sys.argv[1]
    try:
        klass = commands[cmdName]
        cmd = klass()
    except KeyError:
        print "unknown command %s" % cmdName
        print ""
        printUsage(commands.keys())
        sys.exit(2)

    options = cmd.options
    cmd.gitdir = os.environ.get("GIT_DIR", None)

    args = sys.argv[2:]

    if len(options) > 0:
        options.append(optparse.make_option("--git-dir", dest="gitdir"))

        parser = optparse.OptionParser(cmd.usage.replace("%prog", "%prog " + cmdName),
                                       options,
                                       description = cmd.description,
                                       formatter = HelpFormatter())

        (cmd, args) = parser.parse_args(sys.argv[2:], cmd);
    global verbose
    verbose = cmd.verbose
    if cmd.needsGit:
        if cmd.gitdir == None:
            cmd.gitdir = os.path.abspath(".git")
            if not isValidGitDir(cmd.gitdir):
                cmd.gitdir = read_pipe("git.cmd rev-parse --git-dir").strip()
                if os.path.exists(cmd.gitdir):
                    cdup = read_pipe("git.cmd rev-parse --show-cdup").strip()
                    if len(cdup) > 0:
                        chdir(cdup);

        if not isValidGitDir(cmd.gitdir):
            if isValidGitDir(cmd.gitdir + "/.git"):
                cmd.gitdir += "/.git"
            else:
                die("fatal: cannot locate git repository at %s" % cmd.gitdir)

        os.environ["GIT_DIR"] = cmd.gitdir

    if not cmd.run(args):
        parser.print_help()


if __name__ == '__main__':
    main()
