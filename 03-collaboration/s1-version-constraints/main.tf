module "labels" {
  source = "./modules/labels"
  name   = "app"
}

output "label" {
  value = module.labels.id
}
