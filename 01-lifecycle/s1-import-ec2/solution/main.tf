variable "sg_id" {
  type = string
}

variable "instance_id" {
  type = string
}

# import 블록(imports.tf)은 apply 후 삭제했다(과제 6). 작성했던 내용은 SOLUTION.md 참고.
# 리소스 정의는 terraform plan -generate-config-out=generated.tf 로 만든 뒤 정리한 generated.tf에 있다.
