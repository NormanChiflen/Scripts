#!/bin/bash

# Xcode4 doesn't setup the environment
source ~/.bashrc

# Delete the URL part from the file passed in
fn=${BASH_ARGV#file://localhost}
echo "fn=" $fn

if [ -a ${fn} ]; then
    res=$(/usr/local/bin/p4 edit ${fn})

    # TODO: Report the status back to the user in Xcode
    # This output goes to the console.
    echo $res
else
    echo "FnF" ${fn}
fi