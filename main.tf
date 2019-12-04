provider "aws" {
  region = "us-west-2"
}

module "external" {
  source = "../terraform-aws-terraform-enterprise/modules/external-services"

  vpc_id     = "vpc-0855b8a28d229d1be"
  install_id = "${module.terraform-enterprise.install_id}"

  rds_subnet_tags = {
    "Usage" = "ptfe"
  }
}

locals {
  setup_bucket = "emp-tfe-dev"
}

resource "aws_iam_role_policy" "setup-bucket" {
  role = "${module.terraform-enterprise.iam_role}"
  name = "emp-setup-bucket-${module.terraform-enterprise.install_id}"

  policy = <<__policy
{
    "Version": "2012-10-17",
    "Statement": [{
        "Resource": [
            "arn:aws:s3:::${local.setup_bucket}",
            "arn:aws:s3:::${local.setup_bucket}/*"
        ],
        "Effect": "Allow",
        "Action": [
            "s3:*"
        ]
    }]
}
__policy
}

module "terraform-enterprise" {
  source = "../terraform-aws-terraform-enterprise"
  vpc_id = "vpc-0855b8a28d229d1be"
  domain = "ptfedev.com"

  subnet_tags = {
    "Usage" = "ptfe"
  }

  license_file           = "emp1.rli"
  primary_count          = 3
  secondary_count        = 5
  hostname               = "emp-v5"
  import_key             = "gh:evanphx"
  distribution           = "ubuntu"
  iact_subnet_list       = "0.0.0.0/0"
  iact_subnet_time_limit = "unlimited"

  # installer_url = "https://${local.setup_bucket}.s3-us-west-2.amazonaws.com/tfe-setup/ptfe.zip"
  # airgap_installer_url = "s3://${local.setup_bucket}/tfe-setup/replicated.tar.gz?region=us-west-2"
  # airgap_package_url   = "s3://${local.setup_bucket}/tfe-setup/emp1.airgap?region=us-west-2"

  postgresql_user         = "${module.external.database_username}"
  postgresql_password     = "${module.external.database_password}"
  postgresql_address      = "${module.external.database_endpoint}"
  postgresql_database     = "${module.external.database_name}"
  postgresql_extra_params = "sslmode=disable"
  s3_bucket               = "${module.external.s3_bucket}"
  s3_region               = "us-west-2"
  aws_access_key_id       = "${module.external.iam_access_key}"
  aws_secret_access_key   = "${module.external.iam_secret_key}"
}

output "primary_public_ip" {
  value = "${module.terraform-enterprise.primary_public_ip}"
}

output "installer_dashboard_password" {
  value = "${module.terraform-enterprise.installer_dashboard_password}"
}
