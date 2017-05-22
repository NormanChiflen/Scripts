     #!/bin/bash

    ####
    #
    # Must be run from a server that has knife and your key i.e. chef.int.rdio
    #
    ###

    # List of all roles:

    knife role list | sed s/\”//g | sed s/,// | egrep -v ‘\]|\[‘ > ./rolelist.txt

    # Generate a file for each role containing the servers in that role

    for i in `cat rolelist.txt`; do echo $i; knife role show $i > $i.json; done 