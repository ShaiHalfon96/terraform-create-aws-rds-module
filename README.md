# RDS Database Instance and Security Group Configuration
This Terraform configuration creates an RDS Database Instance with monitoring enabled using Amazon CloudWatch.
This module supports the MySQL database engine in the current version. If you need to use a different database engine, you will need to manually update the module to add support for it.

## Prerequisites
Before using this Terraform configuration, ensure you have:

* Installed Terraform
* Configured AWS credentials with sufficient permissions

## Usage
1. Create terrafoorm file that implemnt the module, like the following example:
```hcl
provider "aws" {
    region     = "eu-central-1"
}

data "aws_eks_cluster" "cluster" {
  name = "eks-cluster"
}
locals{
  security_group_a                    = "sg-#################"
  security_group_b                    = "sg-#################"
}

module "mysql_rds" {
    source = "git@github.com:ShaiHalfon96/terraform-create-aws-rds-module.git?ref=master"
    identifier                = "mysql-instance"
    username                  = "admin"
    vpc_id                    = data.aws_eks_cluster.cluster.vpc_config[0].vpc_id
    subnet_ids                = data.aws_eks_cluster.cluster.vpc_config[0].subnet_ids
    ingress_security_groups   = [local.security_group_a, local.security-group_b]
    password                  = "password"
    engine                    = "mysql"
    # ... other configuration settings
} 
```

2. Initialize the Terraform configuration:
```shell
terraform init
```

3. Run the plan command to see the proposed changes:
```shell
terraform plan
```
Terraform will analyze your configuration files, query the current state of your infrastructure, and then display a summary of the changes it plans to make. Review the output carefully to ensure it matches your intentions.

4. Apply the Terraform configuration to create the RDS Database Instance and Security Group:

```shell
terraform apply
```
After the apply command completes, Terraform will display the outputs, including the primary_instance_endpoint for the RDS Database Instance.

### Terraform Configuration
The Terraform configuration consists of two main resources:

#### aws_security_group.rds_sg
* This resource creates a Security Group for the RDS instance.
* The Security Group allows inbound traffic on the engine default port (for example: port 3306 for MySQL engine) from the CIDR block of the specified EKS cluster.

#### aws_iam_role.rds_monitoring_role

* An IAM role is created to allow Amazon RDS to publish data to Amazon CloudWatch for monitoring purposes.

#### aws_db_instance.primary_instance
* This resource creates an RDS Database Instance with the specified configuration.
* The RDS instance uses the engine and is associated with the previously created Security Group.
* IAM database authentication is enabled, and the RDS instance is not publicly accessible.
* The master user password managed with Secrets Manager.

#### aws_db_instance.read_replica (default is 0 instances)
* This resource creates the RDS read replica instance.
* The backup_window specifies the daily time range for backups in UTC.

### Variables
| Variable          | Description                                     | Type   | Default | Required |
|-------------------|-------------------------------------------------|--------|---------|----------|
| `engine`          | The rds engine to use for the instance. | string | "mysql"     | Yes      |
| `engine_version`  | The version of the engine to use for the RDS instance. | string | "8.0.35"     | Yes      |
| `identifier`      | A unique identifier for the RDS Database Instance. | string | N/A     | Yes      |
| `username`        | The username for accessing the RDS instance.      | string | "admin"     | Yes      |
| `password`        | The master user password for accessing the RDS instance.      | string | N/A     | Yes      |
| `instance_class`  | The instance type to use for the RDS instance.    | string | "db.t4g.large"     | Yes      |
| `max_allocated_storage` | The maximum allocated storage for the Amazon RDS  instance. (in GB). | number | 10     | Yes      |
| `storage_type`    | The storage type for the RDS instance (gp2/gp3).   | string | "gp3"     | Yes      |
| `read_replicas`        | Number of read replicas (between 0-5).      | number | 0     | Yes      |
| `backup_retention_period`  | The number of days to retain automated backups. | number | 7     | Yes      |
| `vpc_id`   | The ID of the vpc where the db will be created. | string | N/A     | Yes      |
| `ingress_security_groups`   | List of groups can be used relative to the RDS. | list | N/A     | Yes      |
| `subnet_group`   | Existing subnet group associated with the VPC. | list | N/A     | Yes      |

### Outputs
After applying the Terraform configuration, the following outputs are displayed:

* primary_instance_endpoint: The endpoint URL for accessing the RDS Database Instance.

**_NOTE:_** Make sure you open egress from destination to the RDS.