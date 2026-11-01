# 05-S1 해설

정답 코드는 `solution/`에 있습니다.

- 리소스와 data source는 `provider = aws.dr`로 alias를 고릅니다. 지정하지 않으면 **기본(alias 없는) 구성**을 씁니다.
- AMI ID는 리전마다 다릅니다(같은 이미지라도 리전별로 복사본 ID가 따로 있음). 그래서 리전마다 따로 조회해야 합니다.
- 모듈이 provider 구성을 여러 개 받으려면 `required_providers`에 `configuration_aliases = [aws.src, aws.dst]`를 선언하고, 호출하는 쪽에서 `providers = { aws.src = aws, aws.dst = aws.dr }`로 넘깁니다.
- CRR 요건은 세 가지입니다. ① **양쪽** 버킷 versioning ② S3가 assume하는 IAM 역할(src 읽기, dst 쓰기) ③ src 쪽 provider로 만드는 `aws_s3_bucket_replication_configuration`. versioning이 먼저 켜져야 하므로 `depends_on`으로 순서를 고정합니다. IAM은 글로벌 서비스라 어느 provider로 만들어도 됩니다. 다만 `providers` 맵을 쓰는 모듈에서는 data source까지 모든 리소스에 `provider`를 명시하세요. 1.6은 생략된 리소스를 루트 기본 `aws`로 암묵 연결하지만, 문서는 필요한 provider를 모두 매핑하라고 권고합니다.
- 복제는 설정 **이후에** 올라온 객체부터 적용됩니다(기존 객체는 Batch Replication 필요).
- 모듈은 기본 provider를 **암묵적으로 상속**합니다. 그래서 alias 없는 모듈에는 `providers`를 생략해도 됩니다.
- 5: `provider` 메타 인자가 없는 모든 리소스(`aws_s3_bucket.primary`, `data.aws_ami.al2023`)가 기본 구성을 씁니다. 기본 구성을 지우면 Terraform이 **빈 설정의 기본 provider**를 쓰려 합니다. 이때 region을 정할 수 없어 오류가 나거나 환경 변수의 리전으로 동작합니다.
- 이미 생성된 리소스의 provider 구성을 지우면 Terraform이 그 리소스를 파괴할 provider를 찾지 못해 `Provider configuration not present` 오류가 납니다. provider 블록은 리소스를 먼저 옮기거나 파괴한 **다음에** 지우세요.
