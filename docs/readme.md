The commands of this documentation  were tested in bellow tools versions:

- Minikube: v1.25.1
- Docker: 20.10.21
- Helm: v3.18.4
- AWS CLI: 1.32.111
- Terraform: v1.5.7
- Terragrunt: v0.87.7

## Execute locally using Minikube:


minikube start --driver=docker

eval $(minikube docker-env)

cd application

docker build -t ruby-app .

cd ../helm

helm install ruby-app ruby-app

After application installed using Helm, run the following commnad:

kubectl port-forward svc/ruby-app 3000

Open your browser and access http://localhost:3000

On terminal, close the port-forwarding and execute following commnad to switch docker env:

eval $(minikube docker-env -u)

## Build and deploy application

The folder infrastructure/terragrunt has a structure to provisioning AWS resources (e.g VPC, subnets, EKS, Ingress Controller, etc).

The folders have been organized in modules and environments.

Execution:

1. Set up your AWS credentials:
```bash
export AWS_PROFILE=your-profile
```

2. Navigate to the target environment directory:
```bash
cd infrastructure/terragrunt/stage
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

