variables {
  env = "dev"
}

run "rejects_unknown_env" {
  command = plan

  variables {
    env = "qa"
  }

  expect_failures = [var.env]
}

run "rejects_unknown_instance_type" {
  command = plan

  variables {
    instance_type = "m5.large"
  }

  expect_failures = [var.instance_type]
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    allowed_cidr = "10.0.0.0/33"
  }

  expect_failures = [var.allowed_cidr]
}

run "prod_requires_t3_small" {
  command = plan

  variables {
    env = "prod"
  }

  expect_failures = [aws_instance.web]
}

run "dev_defaults" {
  command = plan

  assert {
    condition     = aws_instance.web.instance_type == "t3.micro"
    error_message = "dev should default to t3.micro."
  }
}
