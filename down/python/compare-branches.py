#!/usr/bin/python
'''
Copyright (c) 2012 Rowan Wookey <admin@rwky.net>
          (c) 2013 Bernd Schubert <bernd.schubert@itwm.fraunhofer.de>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
'''

import sys, subprocess, getopt
import re

gitLogCmd       = ['git', 'log', '--pretty=oneline', '--no-merges', '--no-color']
gitAuthorCmd    = ['git', 'show', '-s', '--format=(%an)', '--no-color']
gitCommitMsgCmd = ['git', 'log', '-1', '--pretty=%B', '--no-color']

branchAOnly   = False
branchBOnly   = False
reversedOrder = False

cherryPickLine = '\(cherry picked from commit '

# just a basic commit object
class gitCommit:
    def __init__(self, commitID, commitSubject):
        self.commitID      = commitID
        self.commitSubject = commitSubject
        self.cherryPickID  = ""

    def getCommitID(self):
        return self.commitID

    def getCommitSubject(self):
        return self.commitSubject

    def addCherryPickID(self, ID):
        self.cherryPickID = ID

    def getCherryPickID(self):
        return self.cherryPickID


class Branch:
    def __init__(self, branchName):
        self.branchName = branchName
        self.patchIdDict    = {} # for fast search
        self.commitList     = []  # list of git commit ids
        self.commitObjDict  = {}  # list of gitCommit objects
        self.missingDict    = {} # list of missing commitIDs of this branch

    def searchCherryPickID(self, commitID):
        commitMsg = subprocess.check_output(gitCommitMsgCmd + [commitID])

        searchRegEx  = re.compile(cherryPickLine)

        for line in commitMsg.splitlines():
            if searchRegEx.search(line):
                cherryPickID = searchRegEx.split(line)[1]

                # remove closing bracket
                cherryPickID = re.sub('\)$', '', cherryPickID)

                return cherryPickID

    def addCommit(self, commitID, commitSubject):

        commitObj = gitCommit(commitID, commitSubject)

        gitShow = subprocess.check_output(['git', 'show', commitID])
        proc = subprocess.Popen(['git', 'patch-id'], stdout=subprocess.PIPE, stdin=subprocess.PIPE)
        patchID = proc.communicate(input=gitShow)[0].split(' ')[0]

        commitObj.addCherryPickID(self.searchCherryPickID(commitID) )
        # print self.branchName + ': Adding: ' + patchID + ' : ' + commitID

        self.commitList.append(commitID)
        self.commitObjDict[commitID] = commitObj
        self.patchIdDict[patchID]    = commitID

    def addLogLine(self, logLine):
        commitID      = logLine[:40]
        commitSubject = logLine[41:]
        self.addCommit(commitID, commitSubject)

    def addGitLog(self, logOutput):
        lines = logOutput.split('\n')
        if lines[-1] == '':
            lines.pop()

        for line in lines:
            self.addLogLine(line)

    def doComparedBranchLog(self, comparedBranchName):
        cmd = gitLogCmd + [self.branchName]

        if 'logSinceTime' in globals():
            cmd.append('--since="%s"' % logSinceTime)
        elif not 'exactSearch' in globals():
            cmd.append('^' + comparedBranchName)

        # print 'Compared branch log: ' + str(cmd)

        log = subprocess.check_output(cmd );

        self.addGitLog(log)

    def createMissingDict(self, comparisonDict):
        for key in comparisonDict.keys():
            if key not in self.patchIdDict:
                commitID = comparisonDict.get(key)
                self.missingDict[commitID] = commitID

                # print self.branchName + ': missing: ' + key + ' : ' + commitID

    def isCommitInMissingDict(self, commitID):
        if commitID in self.missingDict:
            return True

        return False

    # iterate over missing commits to either reverse-assign cherry-pick-ids or to
    # print missing commits
    def iterateMissingCommits(self, comparisonCommitList, comparisonCommitDict, doPrint):

        # Note: Print in the order given by the commitList and not
        #       in arbitrary order of the commit dictionary.

        if doPrint:
            print "Missing from %s" % self.branchName

        for commitID in comparisonCommitList:
            if self.isCommitInMissingDict(commitID):
                cmd          = gitAuthorCmd + [commitID]
                commitAuthor = subprocess.check_output(cmd).rstrip()
                commitObj    = comparisonCommitDict[commitID]

                cherryPickID = commitObj.getCherryPickID()
                if (cherryPickID and (cherryPickID in self.commitObjDict) ):

                    # assign cherry pick id to our branch
                    if not doPrint:
                        cherryObj = self.commitObjDict[cherryPickID]
                        cherryObj.addCherryPickID(commitID)

                    continue

                if doPrint:

                    if 'filterAuthor' in globals() and \
                        not re.search(filterAuthor, commitAuthor):
                            continue # a different owner

                    print '  %s %s %s' % \
                        (commitID, commitAuthor, commitObj.getCommitSubject() )

        if doPrint:
            print

    def printMissingCommits(self, comparisonCommitList, comparisonCommitDict):
        self.iterateMissingCommits(comparisonCommitList, comparisonCommitDict, True)

    def reverseAssignCherryPickIDs(self, comparisonCommitList, comparisonCommitDict):
        self.iterateMissingCommits(comparisonCommitList, comparisonCommitDict, False)


    def getPatchIdDict(self):
        return self.patchIdDict

    def getCommitList(self):
        return self.commitList

    def getCommitObjDict(self):
        return self.commitObjDict

def usage():
        print '''
        Usage:

          -h
                Print this help message.
          -a <branch-name> 
                The name of branch a.
          -b <branch-name>
                The name of branch b.
          -A
                List commits missing from branch a only.
          -B
                List commits missing from branch b only.
          -d
                Print the date when the commit was created.
          -e
                Exact search with *all* commits. Usually we list commits with
                'git log branchA ^branchB', which might not be correct with
                merges between branches.
          -f
                Only print commits created by this user.
          -r
                Print in reverse order (older (top) to newer (bottom) ).
          -t
                How far back in time to go (passed to git log as --since) i.e. '1 month ago'.
        '''


try:
    opts, args = getopt.getopt(sys.argv[1:], "ha:b:BAdef:rt:")
except:
    usage()
    sys.exit()


for opt,arg in opts:
    if opt == '-h':
        usage()
        sys.exit();
    if opt == '-a':
        branchAName = arg
    if opt == '-b':
        branchBName = arg
    if opt == '-A':
        branchAOnly = True
    if opt == '-B':
        branchBOnly = True
    if opt == '-d':
        # mis-use the author command and add the commit date
        gitAuthorCmd[3] = '--format=(%an) %aD'
    if opt == '-e':
        exactSearch = True
    if opt == '-f':
        filterAuthor = arg
    if opt == '-r':
        reversedOrder = True
    if opt == '-t':
        logSinceTime = arg


if 'branchAName' not in globals() or 'branchBName' not in globals():
    print 'You must specify two branches with -a and -b'
    sys.exit(1)

if reversedOrder:
    gitLogCmd += ['--reverse']


branchAObj = Branch(branchAName)
branchBObj = Branch(branchBName)


branchAObj.doComparedBranchLog(branchBName)
branchBObj.doComparedBranchLog(branchAName)

branchAObj.createMissingDict(branchBObj.getPatchIdDict() )
branchBObj.createMissingDict(branchAObj.getPatchIdDict() )


branchAObj.reverseAssignCherryPickIDs(branchBObj.getCommitList(), \
    branchBObj.getCommitObjDict()  )

branchBObj.reverseAssignCherryPickIDs(branchAObj.getCommitList(), \
    branchAObj.getCommitObjDict() )

#print

if not branchBOnly:
    branchAObj.printMissingCommits(branchBObj.getCommitList(), \
        branchBObj.getCommitObjDict()  )

if not branchAOnly:
    branchBObj.printMissingCommits(branchAObj.getCommitList(), \
        branchAObj.getCommitObjDict() )

#if not branchBOnly and not branchAOnly:
#    print
#    print "Commits that can be probably ignored due to merge conflicts: "
#    for msg in branch1_commit_msg:
#        if msg in branch2_commit_msg:
#            print '  ' + msg


