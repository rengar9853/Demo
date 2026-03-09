# PHP 模块化目录脚手架（Laravel/Hyperf 通用）

```text
app/
  Shared/
    Domain/
      Event/
      ValueObject/
    Infra/
      Cache/
      MQ/
      DB/
    Support/
      Idempotency/
      Lock/

  Modules/
    User/
      Domain/
      Application/
      Infrastructure/
      Interfaces/Http/

    Product/
      Domain/
      Application/
      Infrastructure/
      Interfaces/Http/

    Coupon/
      Domain/
      Application/
      Infrastructure/
      Interfaces/Http/

    Order/
      Domain/
      Application/
      Infrastructure/
      Interfaces/Http/

    Payment/
      Domain/
      Application/
      Infrastructure/
      Interfaces/Http/

    Activity/
      Domain/
      Application/
      Infrastructure/
      Interfaces/Http/

    Home/
      Domain/
      Application/
      Infrastructure/
      Interfaces/Http/

    Scheduler/
      Domain/
      Application/
      Infrastructure/
      Interfaces/Console/
```

## 约束建议
- Domain 层禁止依赖具体框架实现。
- Application 负责编排用例（下单、支付、发券）。
- Infrastructure 承载 ORM/Redis/MQ/第三方支付适配。
- Interfaces 层仅处理协议转换（HTTP/Console）。

## 关键中间件
- 鉴权中间件：JWT + 刷新机制
- 幂等中间件：`X-Idempotency-Key`
- 链路追踪中间件：`X-Trace-Id`
- 限流中间件：按用户 + 接口 + 活动维度
