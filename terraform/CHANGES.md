1) Added a go script that will be run by Terraform to reinitialize the nodes
to be able to use Istanbul consensus. Specifically, all previous node keys and
enode values will be used, but the genesis block will be filled to follow istanbul
set up. Script can be found at terraform/go/src/github.com/istanbul-tools.main.go

2) Added a bash script to run the go script in Terraform. All paths referenced
within script is relative and GOPATH is set inside the script. Script is called
reinit.sh and can be found at terraform/scripts/reinit.sh

3) terraform main.tf has been changed to run reinit.sh. Specific changes can be
found on lines 178-180.

4) start-quorum.sh is currently going to set up for Istanbul. To change this, go to
terraform/scripts/install/start-quorum.shd

5) To query the state of the block chain, run ./query.sh which is in
terraform/scripts. Add the host ips into this file.
