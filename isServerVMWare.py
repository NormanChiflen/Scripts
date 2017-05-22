# edit: fixed python code tks to kstrauser

  import os
    if 'vmware' in os.popen('dmidecode').upper():
        print 'this is a vmware vm'
    else:
        print 'this is not a vmware vm'




Here the same code in ruby

`dmidecode`
if $_ ~= /vmware/i
    puts 'this is a vmware vm'
else
    puts 'this is not a vmware vm'


Frankly, this kind of code makes my eyes bleed.