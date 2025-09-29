The commands of this documentation  were tested in bellow tools versions:

- Minikube: v1.25.1
- Docker: 20.10.21
- Helm: v3.18.4
- AWS CLI: 1.32.111
- Terraform: v1.5.7
- Terragrunt: v0.87.7

## 1. Create an application that always responds with “Hello World” to web requests.

The developed application is in the folder devops-homework/application/hello_world_app

## 2. Create Dockerfile for this application.

The created dockerfile is in the folder devops-homework/application/hello_world_app/Dockerfile

To reduce the runtime's attack surface, a non-root user was used in the second stage of the dockerfile. Additionally, the dockerfile prioritized alpine base images, which have a smaller set of dependencies.

## 3. Write yaml to host in kubernetes
A helm chart was used to package the yaml manifests. They can be found in the folder devops-homework/helm/ruby-app

a. Can use minikube or docker desktop

```bash
# Start Minikube cluster
minikube start --driver=docker

# Configure Docker to use Minikube's Docker daemon
eval $(minikube docker-env)

# Build the application image
# This step will deploy 2 instances of hello world application and expose the service.
cd ./application/hello_world_app
docker build -t ruby-app .

# Install the Helm chart
cd ../../helm/
helm install ruby-app ruby-app
```

After application is installed using Helm, wait for Ready status using the command bellow:
```bash
#Check exposed service.
kubectl port-forward svc/ruby-app 3000
```

When the pods were ready, run the following command:

```bash
kubectl port-forward svc/ruby-app 3000
```

Open your browser and access http://localhost:3000

On terminal, close the port-forwarding and execute following command to switch back to your local Docker environment:

```bash
eval $(minikube docker-env -u)
```

## 4. Instructions how to build and deploy to kubernetes

The folder infrastructure/terragrunt has a structure to provisioning AWS resources (e.g VPC, subnets, EKS, Ingress Controller, etc).

The folders have been organized in modules and environments.

Prerequisites

- Create a bucket for state files
- Create DynamoDb tables for execution locks. It is important to avoid problems related concurrent executions.

To create the S3 bucket for storing Terraform state:

```bash
# Create the S3 bucket
aws s3api create-bucket \
    --bucket terraform-state-$(aws sts get-caller-identity --query 'Account' --output text)-<YOUR-REGION> \
    --region <YOUR-REGION>

# Enable versioning for state bucket (Optional)
aws s3api put-bucket-versioning \
    --bucket terraform-state-$(aws sts get-caller-identity --query 'Account' --output text)-<YOUR-REGION> \
    --versioning-configuration Status=Enabled
```

To create DynamoDB tables for state locking:

```bash
# Create table for demo environment
aws dynamodb create-table \
    --table-name terraform-locks-$(aws sts get-caller-identity --query 'Account' --output text)-demo \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST

# Create table for stage environment
aws dynamodb create-table \
    --table-name terraform-locks-$(aws sts get-caller-identity --query 'Account' --output text)-stage \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST

# Create table for prod environment
aws dynamodb create-table \
    --table-name terraform-locks-$(aws sts get-caller-identity --query 'Account' --output text)-prod \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
```

Execution:

1. Set up your AWS credentials:
```bash
export AWS_PROFILE=<your-profile>
```

2. Navigate to the target environment directory:
```bash
cd infrastructure/terragrunt/demo
```

3. Execute the infrastructure modules in order:

VPC Module:
```bash
cd 01-vpc
terragrunt init \
terragrunt plan \
terragrunt apply
```

EKS Module:
```bash
cd ../02-eks
terragrunt init
terragrunt plan
terragrunt apply
```

Kubernetes Components:
```bash
cd ../03-kubernetes-components
terragrunt init
terragrunt plan
terragrunt apply
```

Application Deployment:
```bash
cd ../04-application
terragrunt init
terragrunt plan
terragrunt apply
```

After the apply command completes, the NLB DNS will be available as output.

Alternatively, you can execute all modules at once:
```bash
cd infrastructure/terragrunt/demo
terragrunt run-all plan    # Review all changes
terragrunt run-all apply   # Apply all changes
```

To destroy the infrastructure:
```bash
cd infrastructure/terragrunt/demo
terragrunt run-all destroy
```

Note: If destroying modules individually, follow the reverse order of creation:
1. 04-application
2. 03-kubernetes-components
3. 02-eks
4. 01-vpc


One of the most commonly used practice for the Continuous Delivery process has been GitOps, which ensures that the application's state in the environment matches what's in the Git repository. The ArgoCD and FluxCD tools meet this requirement. It mitigates, for example, disruptions caused by mistaken deletions, because FluxCD or ArgoCD will resync the state.
Using ArgoCD, for example, we could create applications based on the Helm chart developed here along with the image updater plugin to update the application as new versions are released.

In this homework, this process has been simplified to ensure that the entire environment is available in a simpler way. One possible approach for updating the software version would be to generate a pull request for the branch that triggered the image update. This pull request will replace the image version tag using the application module's inputs. 
After that, a workflow can be triggered to execute terragrunt's apply on the application module of the changed environment.

## 5. How would you manage your terraform state file for multiple environments? e.g stage, prod, demo.

In the implemented example, separate terraform states were adopted for each environment and module, so the structure was as seen below:

"bucket/{{ environment }}/{{ module }}/terraform.tfstate"
For example:

s3://terraform-state-704151674151-us-east-1/demo/01-vpc/terraform.tfstate

This allows granular isolation of states and consequently avoids changes caused by other modules in the event of changes or updates.

It's important to note that if environments are isolated by AWS account, it's possible to provision and maintain separate buckets using a cross-account role model with adjustments to root.hcl.

The current implementation assumes all resources will be provisioned in the same AWS account; however, they are isolated at the network level, as the VPCs are distinct by default.

## 6. How would you approach managing terraform variables and secrets as well?

Managing variables and secrets in Terraform can be done in different ways.

#### Environment Variables (non-sensitive information)

Terraform/Terragrunt variables can be versioned via Git. This facilitates equalization between environments and automation of infrastructure creation/modification through pipelines.

#### Environment Secrets (sensitive information)

Secrets, on the other hand, require more careful management. One possible approach is to use the Secrets Manager data source or Parameter Store (Secret type) data source. In an automated flow using terragrunt/terraform in Github Actions, we could use the OIDC provider to enable actions in AWS and the datasource to retrieve sensitive credentials.

Below is an example using AWS Secrets Manager:

```hcl
data "aws_secretsmanager_secret" "my_secret" {
  name = "my-app-secret"
}

data "aws_secretsmanager_secret_version" "my_secret_version" {
  secret_id = data.aws_secretsmanager_secret.my_secret.id
}

locals {
  secret_data = jsondecode(data.aws_secretsmanager_secret_version.my_secret_version.secret_string)
}

output "username" {
  value = local.secret_data["username"]
  sensitive = true
}

output "password" {
  value = local.secret_data["password"]
  sensitive = true
}
```

Another way to retrieve secrets would be to use the Hashicorp Vault data source for Terraform. However, this would require the use of self-hosted runners, as Vault deployments are typically not accessible from the internet for security reasons. Example:

```hcl
provider "vault" {
  address = "https://vault.your-vault-address.com"
  token   = <YOUR REPLACEMENT SECRET PATTERN HERE TO BE USED ON WORKFLOW>
}

data "vault_generic_secret" "myapp_secret" {
  path = "secret/data/myapp"
}

output "username" {
  value = data.vault_generic_secret.myapp_secret.data["username"]
}

output "password" {
  value     = data.vault_generic_secret.myapp_secret.data["password"]
  sensitive = true
}
```

If you want to create secrets via continuous integration, we recommend using Environment Secrets from Github Actions. Before applying the Terraform code to create/modify the secret, a step would replace predefined tokens in the Terraform/Terragrunt file with the values ​​registered in the Actions environment.
Note that the replacement should occur during workflow execution in the runner, and after the code is applied, the file should be deleted.

## Extras

### 1. Write the “Hello World” application in rails
The Hello World application was developed using Ruby on Rails. The Docker Image is available in docker hub and it was published using Github Actions.
Registry location:  fstudy/ruby-app:25c50fcde672d6c37a6c5e9eee8e4324cb2e030c

### 2. Create a helm chart instead of a plain kubernetes yaml manifest file
It was developed a Helm Chart with necessary manifests. This chart is in "helm" folder. In devops-homework/helm/ruby-app/templates is possible to see base manifest (e.g. Deployment, Service, Ingress) and variable replacements.

### 3. Describe how you would test this infrastructure.
We can test and validate Terraform infrastructure code using Terratest. Terratest is a collection of Golang packages that allows you to create automated resource tests in a controlled environment. This way, Terraform modules can be validated separately or in an integrated manner by comparing desired inputs and outputs generated by the cloud provider.
Additionally,
the Checkov tool can be used for static code testing. The purpose in this case is to identify vulnerable configurations or configurations that do not follow good security practices before infrastructure provisioning.


### Some Considerations

- To simplify the helm chart implementation, the cluster API Server Endpoint has been made publicly available. For enterprise environments, it's recommended to keep this endpoint private, so that communication is only possible through a machine on the cluster's own network. This option has been maintained as a variable in the Terraform module.

- The HTTPS enforcement was not applid, however is recommended for corporative environments.