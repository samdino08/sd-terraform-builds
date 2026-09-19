# EC2 Jenkins Terraform Module

Provisions an EC2 instance (Amazon Linux 2), installs Java 17 and Jenkins via
`user_data`, and opens the security group ports needed for SSH (22) and the
Jenkins web UI (8080).

## Structure

```
terraform-ec2-jenkins/
├── modules/
│   └── ec2-jenkins/
│       ├── main.tf          # EC2 instance + security group
│       ├── variables.tf     # Module inputs
│       ├── outputs.tf       # Module outputs
│       ├── versions.tf      # Provider requirements
│       └── user_data.sh.tpl # Jenkins install script (runs on boot)
└── examples/
    └── dev/
        ├── main.tf          # Example root config calling the module
        ├── variables.tf     # Root-level input variables
        └── terraform.tfvars.example
```

## Usage

```hcl
module "jenkins_server" {
  source = "./modules/ec2-jenkins"

  instance_name               = "jenkins-dev"
  instance_type                = "t3.medium"
  key_name                     = "your-key-pair-name"
  vpc_id                       = "vpc-xxxxxxxx"
  subnet_id                    = "subnet-xxxxxxxx"
  allowed_ssh_cidr_blocks       = ["203.0.113.5/32"]
  allowed_jenkins_cidr_blocks   = ["203.0.113.5/32"]

  tags = {
    Environment = "dev"
  }
}
```

## Deploying the example

```bash
cd examples/dev
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your key_name, vpc_id, subnet_id, and IP

terraform init
terraform plan
terraform apply
```

## After apply

1. Wait 2–3 minutes for `user_data` to finish installing Jenkins.
2. Open the URL from the `jenkins_url` output, e.g. `http://<public-ip>:8080`.
3. Get the initial admin password:
   ```bash
   ssh -i /path/to/key.pem ec2-user@<public-ip> \
     "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
   ```
4. Paste it into the Jenkins setup wizard, install suggested plugins, and
   create your admin user.

## Notes / things to adjust for production

- **Instance size**: `t3.medium` is a reasonable minimum for Jenkins with a
  few jobs. Bump it up if you'll run heavy builds directly on the controller.
- **Security groups**: the defaults for `allowed_ssh_cidr_blocks` and
  `allowed_jenkins_cidr_blocks` are `0.0.0.0/0` — restrict these to your IP
  or VPN CIDR before using this anywhere but a throwaway sandbox.
- **HTTPS**: Jenkins here is served over plain HTTP on 8080. For real use,
  put it behind an ALB/Nginx with TLS rather than exposing 8080 directly.
- **State backend**: this example uses local state. For team use, configure
  an S3 backend with state locking (DynamoDB) or use Terraform Cloud.
- **Persistence**: Jenkins data lives on the instance's root volume. Consider
  a separate EBS volume for `/var/lib/jenkins` if you want to detach/reattach
  or snapshot independently of the instance.

## Cleanup

```bash
cd examples/dev
terraform destroy
```
