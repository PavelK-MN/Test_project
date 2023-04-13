############################################################################
Before you run test.tf you have to do some steps:

Create key_pair in AWS.

Specify your key_pair name for each ec2.insance in file test.tf  


Before you run playbook1.yml:

Chenge public IPs in the next list of files:
hosts.txt
group_vars/servers 
redirect_site
config

Put file config in ~/.ssh/ 

Insert your private_key name in the next files: 

~/.ssh/config

Put private_key file in ~/.ssh/ directory.
