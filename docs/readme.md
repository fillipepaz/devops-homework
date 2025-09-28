The commands of this documentation  were tested in bellow tools versions:

- Minikube: v1.25.1
- Docker: 20.10.21
- Helm: v3.18.4
- AWS CLI: 1.32.111
- Terraform: v1.5.7
- Terragrunt: v0.87.7

## Execute locally using Minikube (Q1,Q2,Q3):

```bash
# Start Minikube cluster
minikube start --driver=docker

# Configure Docker to use Minikube's Docker daemon
eval $(minikube docker-env)

# Build the application image
cd application
docker build -t ruby-app .

# Install the Helm chart
cd ../helm
helm install ruby-app ruby-app
```

After application is installed using Helm, run the following command:

```bash
kubectl port-forward svc/ruby-app 3000
```

Open your browser and access http://localhost:3000

On terminal, close the port-forwarding and execute following command to switch back to your local Docker environment:

```bash
eval $(minikube docker-env -u)
```

## Build and deploy application (Q4)

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
    --bucket terraform-state-$(aws sts get-caller-identity --query 'Account' --output text)-us-east-1 \
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
export AWS_PROFILE=your-profile
```

2. Navigate to the target environment directory:
```bash
cd infrastructure/terragrunt/demo
```

3. Execute the infrastructure modules in order:

VPC Module:
```bash
cd 01-vpc
terragrunt init
terragrunt plan
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

Alternatively, you can execute all modules at once:
```bash
cd infrastructure/terragrunt/stage
terragrunt run-all plan    # Review all changes
terragrunt run-all apply   # Apply all changes
```

To destroy the infrastructure:
```bash
cd infrastructure/terragrunt/stage
terragrunt run-all destroy
```

Note: If destroying modules individually, follow the reverse order of creation:
1. 04-application
2. 03-kubernetes-components
3. 02-eks
4. 01-vpc

### Continous Delivery Process (Q4)

The most commonly used practice for the Continuous Delivery process has been GitOps, which ensures that the application's state in the environment matches what's in the Git repository. The ArgoCD and FluxCD tools meet this requirement. It mitigates, for example, disruptions caused by mistaken deletions, because FluxCD or ArgoCD will resync the state.
Using ArgoCD, for example, we could create applications based on the Helm chart developed here along with the image updater plugin to update the application as new versions are released.

In this homework, this process has been simplified to ensure that the entire environment is available in a simpler way. One possible approach for updating the software version would be to generate a pull request for the branch that triggered the image update. This pull request will replace the image version tag using the application module's inputs. 
After that, a workflow can be triggered to execute terragrunt's apply on the application module of the changed environment.

### About terraform state management (Q5)

In the implemented example, separate terraform states were adopted for each environment and module, so the structure was as seen below:

"bucket/environment/modulo/terraform.tfstate"
For example:

s3://terraform-state-704151674151-us-east-1/demo/01-vpc/terraform.tfstate

This allows granular isolation of states and consequently avoids changes caused by other modules in the event of changes or updates.

It's important to note that if environments are isolated by AWS account, it's possible to provision and maintain separate buckets using a cross-account role model with adjustments to root.hcl.

The current implementation assumes all resources will be provisioned in the same AWS account; however, they are isolated at the network level, as the VPCs are distinct by default.

### Secrets and Variables Management (Q6)

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

