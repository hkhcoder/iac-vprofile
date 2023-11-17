name: "Vprofile IAC"
on:
  push:
    branches:
      - main
      - stage
    paths:  
      - terraform/**
  pull_request:
    branches:
      - main
    paths:
      - terraform/**

env:
 # Credentials for deployment to AWS
 AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
 AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
 # S3 bucket for the Terraform state
 BUCKET_TF_STATE: ${{ secrets.BUCKET_TF_STATE}}
 AWS_REGION: us-east-2
 EKS_CLUSTER: vprofile-eks

jobs:
   terraform:
     name: "Apply terraform code changes"
     runs-on: ubuntu-latest
     defaults:
       run:
         shell: bash
         working-directory: ./terraform

     steps:
       - name: Checkout source code 
         uses: actions/checkout@v4

       - name: Setup Terraform with specified version on the runner
         uses: hashicorp/setup-terraform@v2
         #with:
         #  terraform_version: 1.6.3

       - name: Terraform init
         id: init
         run: terraform init -backend-config="bucket=$BUCKET_TF_STATE"

       - name: Terraform format
         id: fmt
         run: terraform fmt -check

       - name: Terraform validate
         id: validate
         run: terraform validate

       - name: Terraform plan
         id: plan
         run: terraform plan -no-color -input=false -out planfile
         continue-on-error: true

       - name: Terraform plan status
         if: steps.plan.outcome == 'failure' 
         run: exit 1     

       - name: Terraform Apply
         id: apple
         if: github.ref == 'refs/heads/main' && github.event_name == 'push'
         run: terraform apply -auto-approve -input=false -parallelism=1 planfile

       - name: Configure AWS credentials
         uses: aws-actions/configure-aws-credentials@v1
         with:
           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
           aws-region: ${{ env.AWS_REGION }}
     
       - name: Get Kube config file
         id: getconfig
         if: steps.apple.outcome == 'success'
         run: aws eks update-kubeconfig --region ${{ env.AWS_REGION }} --name ${{ env.EKS_CLUSTER }} 

       - name: Install Ingress controller
         if: steps.apple.outcome == 'success' && steps.getconfig.outcome == 'success'
         run: kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.3/deploy/static/provider/aws/deploy.yaml
