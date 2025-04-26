This repository contains code to build a container which executes AWS Nuke.

To run the contianer you can deploy the container to ECS Fargate using Terraform. This is scripted using the `wipeit.sh` script in the home directory of the repository.

Create a configuration file for AWS Nuke and execute deployment and running of the container with a command like the following:
`./wipeit.sh my-aws-nuke.conf`
