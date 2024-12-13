# Starting a Server inside a VPC with Terraform
- Terraform config file is `main.tf`
- Add Environemt variables for 
    - Accesskey with key as `AWS_ACCESS_KEY_ID`
    - Secret Accesskey with key as `AWS_SECRET_ACCESS_KEY`
## Initial Requirement
- Have Terraform installed and path added to the eniornment variable `PATH`

## Deploying
- Run command `terraform plan` to get an idea what changes you are about to make
- Then run `terraform apply` to deploy changes

## Add output
- Add output to show values of some attributes by adding 
```hcl
output "name" {
    value = service.attribute
}
```