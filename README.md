# eks-tf-module
A module used to deploy EKS with work nodes on AWS.

## Prerequisites

**1.** Install AWS IAM authenticator. You can find instructions on how to do this in the AWS documention; the link [here](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html).

Make sure that when you run the `terraform apply` that the `aws-iam-authenticator` application is available in the `PATH`. You can quickly do this by running the following:
```
export PATH=$PATH:<path_to_app>
```

**2.** Add tags to the public and private subnets that EKS cluster will be deployed to with the following tags and values:

| Subnet        | Tag                                                        | Value  |
| ------------- | -----------------------------------------------------------|:------:|
| private       | kubernetes.io/cluster/\<project_name\>-\<env\>-eks-cluster | shared |
| private       | kubernetes.io/role/internal-elb                            |   1    |
| public        | kubernetes.io/cluster/\<project_name\>-\<env\>-eks-cluster | shared |
| public        | kubernetes.io/role/elb                                     |        |

These are necessary for deployment of the EKS cluster with the worker nodes and Services.

## Deployment

Run the following commands within the root folder of the repo:

```
terraform init
terraform refresh -var-file=<tfvars_file>.tfvars
terraform apply -var-file=<tfvars_file>.tfvars
```

Make sure that you have provided a valid tfvars file with the variables/configurations you desire for your EKS Cluster. The refresh is necessary if the data sources are to be populated before the apply.
