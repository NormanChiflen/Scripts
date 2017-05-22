#for i in `cat server.list`; do ssh $i ‘hostname;uptime’;done

#We can use chef to build list of servers by role, and a list all servers in a our farm if managed by chef :)

    #!/bin/bash

    ####
    #
    # Must be run from a server that has knife and your key i.e. chef.server.com
    #
    ###

    # I think I am going to make this a recipe
    # but for now…

    #Generate a list of all chef controlled servers

    knife node list | sed s/\”//g | sed s/,// | grep -v \] > /home/operations/servers/all.txt

    # List of all roles:

    knife role list | sed s/\”//g | sed s/,// | egrep -v ‘\]|\[' > /home/operations/servers/roles.txt

    # Generate a file for each role containing the servers in that role
    # Tetsu likes the files lower case ... works for me :)

    for i in `cat roles.txt`; do echo $i; z=`echo $i | tr '[:upper:]‘ ‘[:lower:]‘`; knife search node role:$i -i > $z.txt; done
