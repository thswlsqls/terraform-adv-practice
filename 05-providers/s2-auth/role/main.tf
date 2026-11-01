data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

data "aws_iam_policy_document" "deployer" {
  statement {
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::tfadv-deploy-*", "arn:aws:s3:::tfadv-deploy-*/*"]
  }

  # aws_iam_session_context는 assumed-role ARN을 풀 때 iam:GetRole을 호출한다
  statement {
    actions   = ["iam:GetRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/tfadv-deployer"]
  }
}

resource "aws_iam_role" "deployer" {
  name               = "tfadv-deployer"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy" "deployer" {
  role   = aws_iam_role.deployer.id
  policy = data.aws_iam_policy_document.deployer.json
}

output "role_arn" {
  value = aws_iam_role.deployer.arn
}
