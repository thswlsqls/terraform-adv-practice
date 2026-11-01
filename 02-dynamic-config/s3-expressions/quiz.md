# 표현식 값 예측 퀴즈 (2c · 2e)

결과를 먼저 종이에 적고, 이 디렉터리에서 `terraform console`을 열어 확인하세요. 오류가 나는 식은 "오류"라고 적으세요.

```text
1.  max(3, 7, 2)
2.  min([5, 12, 9]...)
3.  one([])
4.  one(["a", "b"])
5.  sort(["10", "9", "b", "A"])
6.  distinct(concat(["a"], ["b", "a"]))
7.  format("%s-%03d", "web", 7)
8.  join(",", flatten([["a"], [], ["b", ["c"]]]))
9.  merge({ a = 1, b = 2 }, { b = 3, c = 4 })
10. lookup({ a = "x" }, "b", "default")
11. length({ a = 1, b = 2 })
12. [for k, v in { b = 2, a = 1 } : "${k}=${v}"]
13. { for s in ["a", "bb", "cc"] : length(s) => s... }
14. [{ n = 1 }, { n = 2 }][*].n
15. cidrsubnet("10.20.0.0/16", 4, 3)
16. element(["a", "b", "c"], 4)
17. try(tonumber("abc"), 0)
18. coalesce("", "x")
19. length(setproduct(["a", "b"], [1, 2, 3]))
20. keys({ b = 1, a = 2 })
```
