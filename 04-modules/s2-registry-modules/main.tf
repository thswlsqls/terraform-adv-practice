variable "envs" {
  type    = set(string)
  default = ["dev", "stg"]
}

# TODO: 레지스트리 모듈 terraform-aws-modules/s3-bucket/aws 로 env별 버킷, 각 버킷에 README.txt 업로드
