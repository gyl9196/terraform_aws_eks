# Referenced by 
https://github.com/WesleyCharlesBlake/terraform-aws-eks

## What resources are created

1. VPC
2. Internet Gateway (IGW)
3. Public and Private Subnets
4. Security Groups, Route Tables and Route Table Associations
5. IAM roles, instance profiles and policies
6. An EKS Cluster
7. Autoscaling group and Launch Configuration
8. Worker Nodes in a private Subnet
9. The ConfigMap required to register Nodes with EKS
10. KUBECONFIG file to authenticate kubectl using the heptio authenticator aws binary

## Instructions
1. Understand the `tf.sh` file to setup your AWS credential key in ~/.zshrc or ~/.bash_profile
```bash
AAAA_AWS_ACCESS_KEY=******
```
2. 
```bash
./tf.sh plan/apply/destroy  AAAA eks
```
3. update kubeconfig use aws cli (1.16.80)
```bash
aws eks update-kubeconfig --name my-cluster
```
4. To check worker nodes in private subnet, create a file name `aws-auth-cm.yaml`, in the output, we will see the rolearn address
```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: {your own rolearn address}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes

```
