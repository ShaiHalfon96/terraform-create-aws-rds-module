locals {
  version_with_dash   = replace(var.engine_version, ".", "-")
  option_group_name   = "${var.identifier}-${local.version_with_dash}"
  major_version = "${element(split(".", var.engine_version), 0)}.${element(split(".", var.engine_version), 1)}"
  azs_without_primary = [for az in data.aws_availability_zones.available.names : az if az != aws_db_instance.primary_instance.availability_zone]
  engine_default_port = {"mysql" = 3306}
}