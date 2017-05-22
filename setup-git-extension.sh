    #!/bin/bash
    # extract current branch name
    BRANCH=$(git name-rev HEAD 2> /dev/null | awk "{ print \$2 }")
    echo Building archive on branch \\"$BRANCH\\"
    # get name of the most top folder of current directory, used for the
    # output filename
    ARCHIVE_NAME=$(basename $(pwd))
    # get a version string, so archives will not be overwritten when creating
    # many of them
    VERSION=$(git describe �always �long)
    # if not on master append branch name into the filename
    if [ "$BRANCH" = "master" ]; then
            FILENAME=$ARCHIVE_NAME.$VERSION.zip
    else
            FILENAME=$ARCHIVE_NAME.$VERSION.$BRANCH.zip
    fi
    # combine path and filename
    OUTPUT=$(pwd)/$FILENAME
    # building archive
    git archive �format zip �output $OUTPUT $BRANCH
    # also display size of the resulting file
    echo Saved to \\"$FILENAME\\" \(`du -h $OUTPUT | cut -f1`\)

