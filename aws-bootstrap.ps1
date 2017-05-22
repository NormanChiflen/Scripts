

	

aws ec2 create-security-group --group-name "Windows" --description "Remote access to Windows instances"
# WinRM
aws ec2 authorize-security-group-ingress --group-name "Windows" --protocol tcp --port 5985 --cidr <YOURIP>/32
# Incoming SMB/TCP 
aws ec2 authorize-security-group-ingress --group-name "Windows" --protocol tcp --port 445 --cidr <YOURIP>/32
# RDP
aws ec2 authorize-security-group-ingress --group-name "Windows" --protocol tcp --port 3389 --cidr <YOURIP>/32


	

<powershell>
Set-ExecutionPolicy Unrestricted
icm $executioncontext.InvokeCommand.NewScriptBlock((New-Object Net.WebClient).DownloadString('https://gist.github.com/masterzen/6714787/raw')) -ArgumentList "VerySecret"
</powershell>

This powershell script will download the Windows bootstrap Gist and execute it, passing the desired administrator password.

Next we launch the instance:

1

	

aws ec2 run-instances --image-id ami-4524002c --instance-type m1.small --security-groups Windows --key-name <YOURKEY> --user-data "$(cat userdata.txt)"

Unlike what is written in the ec2config documentation, the user-data must not be encoded in Base64.

Note, the first boot can be quite long :)

After that we can connect through WinRM with the “VerySecret” password. To check we’ll use the WinRM Go tool I wrote and talked about above:

1

	

./winrm -hostname <publicip> -username Administrator -password VerySecret "ipconfig /all"
