# Docker Compose 统一规范（通用范式）

## 目标

本文用于统一 `docker-compose.yml` / `compose.yaml` 的书写风格，提升以下方面的一致性：

- 可读性
- 可维护性
- 可审查性
- 团队协作中的 diff 友好性
- 后续自动化导入与复用能力

核心原则：**统一结构，提升可读性，保持语义不变。**

---

## 顶层推荐顺序

推荐统一使用以下顶层字段顺序：

```yaml
name:
services:
networks:
volumes:
configs:
secrets:
```

说明：

- `name`：可选，推荐在多项目环境中显式指定
- `services`：必须优先
- `networks / volumes / configs / secrets`：按资源类型统一放置

---

## 单个 Service 推荐字段顺序

建议每个 service 内部统一按如下顺序排列：

```yaml
image:
container_name:
hostname:
profiles:
build:
pull_policy:
platform:
restart:
init:
privileged:
user:
working_dir:
entrypoint:
command:
depends_on:
links:
network_mode:
networks:
ports:
expose:
environment:
env_file:
labels:
healthcheck:
volumes:
volumes_from:
configs:
secrets:
tmpfs:
devices:
cap_add:
cap_drop:
security_opt:
sysctls:
ulimits:
dns:
dns_search:
extra_hosts:
logging:
develop:
deploy:
```

说明：

- 不存在的字段不要强行补齐
- 多个逻辑块之间建议保留一个空行
- `deploy` 一般放在最后

---

## 基础格式规范

### 1. 缩进

统一使用 **2 个空格缩进**。

### 2. 空行

同类配置连续排列，不同逻辑块之间使用 1 个空行分隔，例如：

- 基础信息
- 网络与端口
- 环境变量
- 健康检查
- 挂载
- 日志
- 资源限制

### 3. 引号策略

- 能不用引号就不用
- 含特殊字符、冒号、JSON、空格或易歧义值时保留引号
- `healthcheck.test` 的数组写法建议统一使用双引号
- `logging.options.max-file` 这类字段建议显式写为字符串

示例：

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/healthz"]

logging:
  driver: json-file
  options:
    max-size: 10m
    max-file: "10"
```

---

## environment 统一规范

### 推荐写法

统一采用 **map 写法**，不要使用 `- KEY=value` 列表写法。

推荐：

```yaml
environment:
  TZ: ${TZ:-Asia/Shanghai}
  DB_HOST: ${DB_HOST:-postgres}
  DB_PORT: ${DB_PORT:-5432}
```

不推荐：

```yaml
environment:
  - TZ=${TZ:-Asia/Shanghai}
  - DB_HOST=${DB_HOST:-postgres}
  - DB_PORT=${DB_PORT:-5432}
```

### 原因

- 更适合维护和 diff
- 不容易出现 `=` 分割误解
- 注释挂载更清晰
- 键值关系更直观

### 排列建议

- 优先按业务逻辑分组
- 同组内建议按名称或阅读逻辑排序
- 注释保留在对应配置项上方

示例：

```yaml
environment:
  TZ: ${TZ:-Asia/Shanghai}

  # 数据库
  DB_HOST: ${DB_HOST:-postgres}
  DB_PORT: ${DB_PORT:-5432}
  DB_NAME: ${DB_NAME:-app}

  # 外部认证
  OAuthClientId: ${OAuthClientId}
  OAuthClientSecret: ${OAuthClientSecret}
```

---

## labels 统一规范

统一采用 **map 写法**。

推荐：

```yaml
labels:
  com.centurylinklabs.watchtower.enable: ${WATCHTOWER_ENABLE:-true}
```

不推荐：

```yaml
labels:
  - com.centurylinklabs.watchtower.enable=${WATCHTOWER_ENABLE:-true}
```

如标签语义已足够明确，可不再追加冗余行尾注释。

---

## ports / expose 规范

### ports

推荐统一列表写法：

```yaml
ports:
  - ${PORT:-8080}:8080
```

多个端口时保持顺序稳定，通常按：

1. 主业务端口
2. 管理端口
3. 调试或备用端口

带注释示例：

```yaml
ports:
  - ${PORT:-5011}:8080
  # - 5001:8081
```

### expose

仅在需要容器间暴露端口而不对宿主公开时使用：

```yaml
expose:
  - "8080"
```

---

## volumes 规范

### 推荐顺序

- 先命名卷
- 再宿主机路径挂载
- 再只读挂载

### 示例

```yaml
volumes:
  - DataProtection-Keys:/root/.aspnet/DataProtection-Keys
  - ${MNT_DIR:-/mnt/docker}/IdentityServer:/app/cert
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

### 建议

- 持久化路径明确命名
- 路径含义尽量稳定
- 数据库目录优先使用镜像官方推荐路径

例如 PostgreSQL 建议优先使用镜像官方数据目录：

| 版本 | 容器内数据目录 |
|------|--------------|
| PostgreSQL ≤ 17 | `/var/lib/postgresql/data` |
| PostgreSQL 18+ | `/var/lib/postgresql` |

```yaml
# PostgreSQL 17 及以下
volumes:
  - ${MNT_DIR:-/mnt/docker}/postgres:/var/lib/postgresql/data

# PostgreSQL 18+
volumes:
  - ${MNT_DIR:-/mnt/docker}/postgres:/var/lib/postgresql
```

注意版本升级时数据目录可能发生变更，挂载路径需同步调整，避免数据丢失。

---

## networks 规范

### 顶层网络

外部网络示例：

```yaml
networks:
  web:
    external: true
```

默认由 compose 创建的内部网络示例：

```yaml
networks:
  db_network:
```

### Service 内部网络

统一列表写法：

```yaml
networks:
  - web
```

### 规范建议

- 如果定义了顶层网络，服务应显式声明是否接入
- 不使用的网络不要保留
- 按业务边界拆分网络，例如：
  - `web`
  - `db_network`
  - `internal`

---

## healthcheck 规范

推荐对可探测服务统一增加健康检查。

通用示例：

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/healthz"]
  interval: 1m30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

轻量命令示例：

```yaml
healthcheck:
  test: ["CMD", "/agent", "health"]
  interval: 120s
```

规范建议：

- 尽量使用服务自身官方或稳定探针
- 避免复杂 shell
- 参数风格统一

---

## logging 规范

推荐统一采用 `json-file`，并限制日志大小：

```yaml
logging:
  driver: json-file
  options:
    max-size: 10m
    max-file: "10"
```

建议：

- 所有长期运行服务尽量统一日志策略
- `max-file` 显式字符串化，减少 YAML 类型歧义

---

## deploy 规范

资源限制统一放在最后：

```yaml
deploy:
  resources:
    limits:
      memory: ${RESOURCES_LIMITS_MEMORY:-500m}
```

说明：

- Docker Compose v2 单机场景下 `deploy.resources.limits` 已完整生效，无需 Swarm
- Docker Compose v1（旧版 `docker-compose`）不支持此字段，如仍在使用请改用顶层 `mem_limit` / `cpus`

---

## depends_on 规范

当服务存在明显启动依赖关系时建议声明。

**推荐：结合 `healthcheck` 使用 condition 写法**，确保依赖服务真正可用后再启动：

```yaml
depends_on:
  db:
    condition: service_healthy
```

仅需保证启动顺序时可使用简写：

```yaml
depends_on:
  - db
```

说明：

- 简写形式只保证启动顺序，不保证依赖服务已经”可用”
- 严格可用性场景应使用 `condition: service_healthy`，要求依赖服务配置了 `healthcheck`

---

## restart 策略建议

常见推荐：

```yaml
restart: unless-stopped
```

或：

```yaml
restart: always
```

选择建议：

- 通用业务服务：`unless-stopped`
- 明确要求持续运行的核心服务：`always`

团队内应尽量统一使用理由，而不是随意混用。

---

## 推荐的通用单服务模板

```yaml
services:
  app:
    image: your-image:latest
    container_name: app
    hostname: app
    restart: unless-stopped

    networks:
      - web

    ports:
      - ${PORT:-8080}:8080

    environment:
      TZ: ${TZ:-Asia/Shanghai}

    labels:
      com.centurylinklabs.watchtower.enable: ${WATCHTOWER_ENABLE:-true}

    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/healthz"]
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 40s

    volumes:
      - ${MNT_DIR:-/mnt/docker}/app:/app/data

    logging:
      driver: json-file
      options:
        max-size: 10m
        max-file: "10"

    deploy:
      resources:
        limits:
          memory: ${RESOURCES_LIMITS_MEMORY:-500m}

networks:
  web:
    external: true
```

---

## 推荐的双服务模板（应用 + 数据库）

```yaml
services:
  app:
    image: your-app:latest
    container_name: app
    restart: unless-stopped

    depends_on:
      - db

    networks:
      - db_network

    ports:
      - ${PORT:-8080}:8080

    environment:
      TZ: ${TZ:-Asia/Shanghai}
      DB_HOST: ${DB_HOST:-db}
      DB_NAME: ${DB_NAME:-app}
      DB_USER: ${DB_USER:-postgres}
      DB_PASSWORD: ${DB_PASSWORD}

  db:
    image: postgres:${POSTGRES_IMAGE_TAG:-16}
    container_name: db
    restart: unless-stopped

    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

    networks:
      - db_network

    volumes:
      - ${MNT_DIR:-/mnt/docker}/app/db:/var/lib/postgresql/data

networks:
  db_network:
```

---

## 输出时的统一整理规则

在整理已有 compose 文件时，统一遵循以下规则：

1. 不改变原始业务语义
2. 优先做字段排序与格式统一
3. `environment` 改为 map 写法
4. `labels` 改为 map 写法
5. 统一 `healthcheck.test` 数组风格
6. 统一 `logging.options.max-file` 为字符串
7. 顶层资源按统一顺序输出
8. 删除无意义尾随空格
9. 保留有价值的业务注释
10. 对“已声明但未使用”的网络、卷、配置项进行标注提醒

---

## 可选增强项

以下属于增强项，不应在“纯格式化”时擅自添加，但可在评审中建议：

- 增加 `name`
- 增加 `healthcheck`
- 增加 `logging`
- 增加 `depends_on`
- 增加 `env_file`
- 统一 `watchtower` 标签
- 拆分外部网络与内部网络
- 使用锚点复用公共配置
- 增加资源限制

