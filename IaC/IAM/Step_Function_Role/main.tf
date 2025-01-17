name: Deploy IAM SFN Roles
on:
  workflow_dispatch:
    inputs:
      s3_bucket:
        description: "S3 bucket name for storing Terraform plans"
        required: true
      s3_path:
        description: "S3 path prefix for plans "
        required: true
jobs:
  terraform:
    name: 'Deploy IAM SFN Resources'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: "1.5.7"
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v3
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-southeast-2
      # Deploy StepFuction Role
      - name: Delete Existing Resources
        working-directory: IaC/IAM/Step_Function_Role
        run: |
          terraform init
          # Remove policy first
          terraform state rm aws_iam_role_policy.lambda_invocation_policy || true
          terraform destroy -auto-approve -target=aws_iam_role_policy.lambda_invocation_policy
          # Then remove role
          terraform state rm aws_iam_role.lambda_invocation_role || true
          terraform destroy -auto-approve -target=aws_iam_role.lambda_invocation_role
          
      - name: Deploy SFN Role
        working-directory: IaC/IAM/Step_Function_Role
        run: |
          terraform plan -out=tfplan-iam-stepfunction-role
          TIMESTAMP=$(date +%Y%m%d%H%M%S)
          aws s3 cp tfplan-iam-stepfunction-role s3://${{ github.event.inputs.s3_bucket }}/${{ github.event.inputs.s3_path }}/tfplan-iam-stepfunction-role-${TIMESTAMP}
          terraform apply -auto-approve tfplan-iam-stepfunction-role
