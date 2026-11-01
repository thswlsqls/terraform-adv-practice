# 04-S1 해설

정답 코드는 `solution/`에 있습니다.

- 3: 처음부터 `for_each` 키 주소(`module.web["blue"]...`)로 `moved` 하면 한 번에 끝납니다. 이미 `module.web`(단일)으로 옮긴 적이 있다면 `moved { from = module.web  to = module.web["blue"] }`처럼 **모듈 단위**로 옮길 수도 있습니다.
- 4(핵심 함정): `moved`는 주소만 바꾸고 **인자 값은 보존하지 않습니다**. 모듈이 SG `name_prefix`를 `"${var.name}-"`로 만들면 기존 `mono-web-`과 달라 SG가 replace되고, destroy-then-create 순서라 인스턴스가 쓰는 SG 삭제가 막힙니다. 기존 값을 넘길 수 있는 선택 입력(`sg_name_prefix`, 기본 `null` + `coalesce`)을 만들어 해결합니다.
- `for_each`는 **문자열 set 또는 map**만 받습니다. `set(number)`는 오류이므로 `{ for p in var.ingress_ports : tostring(p) => p }`로 바꾸고, 주소는 `this["80"]`가 됩니다.
- 모듈 안에 `provider` 블록이 있는 "legacy module"에는 `count`/`for_each`/`depends_on`을 쓸 수 없습니다. 그래서 provider 설정은 루트가 맡고, 모듈은 `required_providers`만 선언합니다.
- 모듈 경계는 변수(입력)와 출력으로만 통과합니다. 루트가 `module.web["blue"].aws_instance.this.id`처럼 모듈 내부 리소스에 직접 접근할 수 없으므로 필요한 값은 출력으로 노출하세요.
