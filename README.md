-------------
## Please note that this project is no longer supported. For more up to date cloud deployment tool please proceed to https://github.com/jpmorganchase/quorum-cloud
-------------


# quorum-aws

This repo contains the tools we use to deploy test Quorum clusters to AWS.

- We use [Docker](https://www.docker.com/) to build images for quorum, constellation, and this codebase (quorum-aws, which extends [quorum-tools](https://github.com/jpmorganchase/quorum-tools)).
- Docker images are pushed to AWS' [ECS repositories](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_Console_Repositories.html).
- We use [Terraform](https://www.terraform.io/) to provision single-region (cross-availability-zone) and multi-region (cross-internet) Quorum clusters using these images.

With a little bit of time and an AWS account, you should be able to use this project to easily deploy a Quorum cluster to AWS.

### Requirements

- Installed software: [Docker](https://docs.docker.com/engine/installation/), [Terraform](https://www.terraform.io/intro/getting-started/install.html), [stack](https://docs.haskellstack.org/en/stable/README/#how-to-install), [jq](https://stedolan.github.io/jq/download/), and [awscli](https://aws.amazon.com/cli/)
- awscli needs to be configured to talk to AWS (see the [user guide](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) or use `aws configure help`)
- `vim terraform/secrets/terraform.tfvars` to reflect AWS credentials in `~/.aws/credentials`

### Building images

From the root of this project, you can execute the following two scripts in order to build Docker images for quorum, constellation, and quorum-aws. The latter will be built both locally and in docker (to be deployed to AWS.) We need to build and push these Docker images before we can run a cluster on AWS.

If we haven't already, we need to pull Quorum and Constellation down into the `dependencies` directory:

- `git submodule init && git submodule update`

Then build the Docker images and push them to ECS repositories:

- `./build && ./push`

#### Building issues
Error 137 is generally a sign that you should configure Docker with more memory.


### A note on how we are using Terraform

In order to manage terraformed infrastructure across different regions and clusters, instead of using the `terraform` binary directly, we use (symlinks to) a wrapper script (around the `terraform` binary) to automatically set variables and state output locations per environment. Take a look inside `terraform/bin` to see how this works:

```
> ls -al terraform/bin
total 64
drwxr-xr-x  11 bts  staff  374 Oct 11 15:13 .
drwxr-xr-x  13 bts  staff  442 Oct 11 15:35 ..
drwxr-xr-x   3 bts  staff  102 Oct 11 15:58 .bin
-rwxr-xr-x   1 bts  staff  793 Oct 11 14:39 .multi-start-cluster
-rwxr-xr-x   1 bts  staff  812 Oct 11 14:39 .multi-start-tunnels
lrwxr-xr-x   1 bts  staff   16 Oct  2 11:42 demo -> .bin/env-wrapper
lrwxr-xr-x   1 bts  staff   16 Oct  2 11:42 global -> .bin/env-wrapper
lrwxr-xr-x   1 bts  staff   16 Oct  2 11:42 intl-ireland -> .bin/env-wrapper
lrwxr-xr-x   1 bts  staff   16 Oct  2 11:42 intl-tokyo -> .bin/env-wrapper
lrwxr-xr-x   1 bts  staff   16 Oct  2 11:42 intl-virginia -> .bin/env-wrapper
-rwxr-xr-x   1 bts  staff  235 Oct 11 15:13 multi-start
```

Here, `demo` is a symlink to the wrapper script that will invoke Terraform in a such a way that it knows we are concerned with the "demo" environment. Instead of using the `terraform` binary directly (e.g. `terraform plan`), we issue the same Terraform CLI commands to the wrapper script (e.g. `bin/demo plan`).

The pre-supplied binary wrappers have the following purposes:
- `global` environment contains IAM infrastructure that is not particular to any one AWS region, and will be `apply`ed only once.
- `demo` is the default name of a single-region cluster that will be deployed to `us-east-1`.
- `intl-ireland`, `intl-tokyo`, and `intl-virginia` contain the infrastructure respectively for 3 different regions in an international cluster. This infrastructure lives in separate files because Terraform is hard-coded to support at most one region per `main.tf` file.

If you want, you can simply make a new symlink (in `terraform/bin`) to `terraform/bin/.bin/env-wrapper` named whatever you like (eg. `mycluster`), and then you can use that script to launch a new cluster with that name.

### One-time: initialize Terraform plugins (for Terraform 0.10+)

Because we're using the `aws` and `null` Terraform plugins, we need to initialize them:

- `terraform init`

### One-time: deploy some "global" IAM infrastructure

The following only needs to be done once to deploy some Identity and Access Management (IAM) infrastructure that we re-use across clusters:

- `cd terraform`
- `bin/global apply`

If at some point in the future you want to destroy this infrastructure, you can run `bin/global destroy`.

### Deploying a single-region cluster

- `cd terraform`

For a given Terraform environment, we can use the normal Terraform commands like `plan`, `show`, `apply`, `destroy`, and `output` to work with a single-region cluster:

- `bin/demo plan` shows us what infrastructure will be provisioned if we decide to `apply`
- `bin/demo apply` creates the infrastructure. In a single-region setting, this also automatically starts the Quorum cluster.
- `bin/demo show` reports the current Terraform state for the environment
- `bin/demo output` can print the value for an output variable listed in `output.tf`. e.g.: `bin/demo output geth1`. This can be handy to easily SSH into a node in the cluster: e.g. try `ssh ubuntu@$(bin/demo output geth1)` or `ssh ubuntu@$(bin/demo output geth2)`.

Once SSH'd in to a node, we can use a few utility scripts that have been installed in the `ubuntu` user's homedir to interact with `geth`:

- `./spam 10` will send in 10 transactions per second until `^C` stops it
- `./follow` shows the end of the (`tail -f`/followed) `geth` log
- `./attach` attaches to the local `geth` process.
- `exit`

At this point, if we like, we can destroy the cluster:

- `bin/demo destroy`

### Deploying a multi-region cluster

At the moment, this is slightly more involved than deployment for a single-region cluster. Symlinks (in `terraform/bin`) are currently set up for one multi-region called "intl" that spans three regions. Because `ireland` is set up in this cluster to be "geth 1", it performs the side effect of generating a `cluster-data` directory that will be used for the other two regions. So, we provision `ireland` first:

- `bin/intl-ireland apply`

Then we can provision `tokyo` and `virginia`. You can do these two steps in parallel (e.g. in different terminals) if you'd like:

- `bin/intl-tokyo apply`
- `bin/intl-virginia apply`

Once all three regions have been provisioned, we need to start the cluster. In single-region clusters this is done automatically, but in multi-region clusters, it's manual. This will set up SSH tunnels between regions for secure communication between them, then start constellation and quorum on each node. Note here we specify the name of the cross-region cluster, `intl`.

- `bin/multi-start intl`

At this point, we should be able to log in to one of the nodes and see the cluster in action:

- `ssh ubuntu@$(bin/intl-virginia output eip)` where `eip` stands for Elastic IP, the static IP address other nodes in the cluster can use to connect to this one.
- `./spam 10` send in 10 transactions per second for a few seconds, then `^C` to stop it
- `./follow` shows the end of the (`tail -f`/followed) `geth` log, or `./attach` attaches to the local node.
