# Docker Compose 统一规范

> 版本：1.0
> 发布日期：2026-08-24
> 适用范围：本仓库所有 Docker Compose 文件
> 兼容基线：现代 Docker Compose v2 与当前 Compose Specification

## 1. 目标与生效方式

本规范用于统一 Compose 文件的结构、表达方式和可审查性，同时明确哪些运行优化可以全局应用，哪些必须逐服务验证。

首版采用渐进式生效，并已完成历史文件的第一轮迁移：

- 新增 Compose 文件必须遵守全部适用的 MUST。
- 修改现有 Compose 文件时，应同步整理本次涉及的逻辑块。
- 当前 82 个文件已完成可机械规则和已授权全局行为目标的迁移。
- 数据库端口、挂载、健康检查、依赖和高权限配置仍按逐服务评审处理。
- 后续新增或修改的 Compose 文件立即遵守全部适用 MUST。
- 当前只完成静态验证；仍需在 Docker Compose 可用的目标主机上执行 config 与启动验证。

### 1.1 规则等级

- **MUST**：强制要求。除不可豁免规则外，保留例外时必须写明理由。
- **SHOULD**：默认采用；存在明确兼容性或运行理由时可以不采用。
- **MAY**：按项目需求选择。

### 1.2 例外格式

可豁免的 MUST 使用紧邻配置的结构化注释：

```yaml
# compose-style: allow NET001 - 该端口只允许通过固定管理网段访问
ports:
  - "192.0.2.10:8443:8443"
```

以下规则不可豁免：

- YAML 必须可解析。
- 不得存在重复键。
- 不得提交真实密码、token、私钥或其他有效密钥。

## 2. 文件级规范

### FMT001 文件名与换行

- 当前 MUST 使用 `docker-compose.yml`。
- 当前 MUST 保持 CRLF，与仓库现状一致。
- 文件末尾 MUST 有一个换行。
- 未来将 `compose.yaml`、LF 和 `.gitattributes` 作为同一批迁移处理；首版只记录路线图，不提前判定违规。

### FMT002 缩进与空白

- MUST 使用 2 个空格缩进，不得使用 Tab。
- 逻辑组之间 MUST 保留一个空行。
- 逻辑组内部字段连续书写。
- MUST 删除尾随空格。
- 不设置最大行宽；不可安全拆分的 URL、镜像引用和命令保持单行。

### FMT003 注释

- MUST 保留有价值的上游和业务注释。
- 不要求翻译已有上游注释。
- 新增仓库说明 MUST 使用中文。
- 注释 SHOULD 放在对应字段或逻辑块上方，避免冗余行尾注释。
- 只有 `container_name` 和 `extra_hosts` 允许作为全局注释占位；其他可选能力按需直接添加。

### FMT004 标量与引号

- 普通无歧义字符串 SHOULD 不加引号。
- 布尔、数字、null 类、日期时间、包含 `#` 或可能产生 YAML 类型歧义的字符串 MUST 使用双引号。
- `environment` 的值必须保持应用期望的字符串类型。
- ports 短语法 MUST 对完整映射字符串使用双引号。
- JSON、复杂 shell 和已有上游引用形式可以保留更合适的引号。

### FMT005 列表与命令

- 普通列表 MUST 使用 block style。
- 简短的 `healthcheck.test`、`entrypoint` 或其他 exec 参数 MAY 使用 flow style。
- 不需要 shell 语义时，`command` 与 `entrypoint` SHOULD 使用 exec list。
- 需要循环、管道、重定向、条件判断或变量展开时 MUST 使用 block scalar，并明确 shell 或 entrypoint。

## 3. 顶层结构

### STR001 顶层字段顺序

存在的字段 MUST 按以下顺序排列：

```text
x-*
name
include
services
models
networks
volumes
configs
secrets
```

- 不使用已废弃的顶层 `version`。
- `x-*` 放在 services 前，便于 anchors 被后续内容引用。
- 本仓库当前不采用 Compose secrets；`secrets` 仅保留 Schema 中的位置定义。

### STR002 Service 排列

- 多服务项目 MUST 先写主应用或主要入口服务。
- 数据库、缓存、队列、worker 和辅助服务随后按业务阅读顺序排列。
- 实际启动依赖 MUST 通过 `depends_on` 等 Compose 关系表达，不依赖 YAML 书写顺序。

### STR003 Service 字段分组

存在的字段 MUST 按下列组顺序排列。组内使用表中顺序；Schema 新增字段应归入最接近的逻辑组并在规范中登记。

#### 1. 来源与身份

```text
image
build
provider
container_name
hostname
domainname
profiles
platform
pull_policy
pull_refresh_after
```

`profiles` 不在本仓库中使用；该位置仅用于识别外部文件。`platform` 仅在明确的架构约束下设置。

#### 2. 生命周期与命令

```text
restart
init
working_dir
entrypoint
command
pre_start
post_start
pre_stop
stop_signal
stop_grace_period
attach
stdin_open
tty
```

`init` 不作为全局要求，仅整理现有或上游明确需要的配置。

#### 3. 依赖

```text
depends_on
links
external_links
extends
```

#### 4. 网络与端口

```text
network_mode
networks
ports
expose
dns
dns_opt
dns_search
extra_hosts
mac_address
```

#### 5. 配置与元数据

```text
env_file
environment
label_file
labels
annotations
models
```

`env_file` 必须位于 `environment` 前，以对应“文件提供基础值，environment 覆盖”的优先级。

#### 6. 健康检查

```text
healthcheck
```

#### 7. 存储

```text
volumes
volumes_from
configs
secrets
tmpfs
shm_size
```

#### 8. 权限与宿主访问

```text
user
group_add
read_only
privileged
use_api_socket
devices
device_cgroup_rules
gpus
cap_add
cap_drop
credential_spec
security_opt
sysctls
ulimits
pid
ipc
uts
userns_mode
cgroup
cgroup_parent
isolation
runtime
```

该组必须集中展示，便于审查宿主权限、命名空间和设备访问。

#### 9. 日志与资源

```text
logging
blkio_config
cpu_count
cpu_percent
cpu_shares
cpu_period
cpu_quota
cpu_rt_period
cpu_rt_runtime
cpus
cpuset
mem_limit
mem_reservation
mem_swappiness
memswap_limit
oom_kill_disable
oom_score_adj
pids_limit
scale
storage_opt
deploy
develop
```

本仓库目标状态不保留 service 级 `logging`；该位置只用于整理迁移前文件或明确例外。`deploy` 与 `develop` 放在最后。

### STR004 资源命名

- 新 service、network、volume MUST 使用 kebab-case。
- 环境变量 MUST 使用 UPPER_SNAKE_CASE。
- 现有名称不机械迁移，避免改变 service DNS、`depends_on` 引用或实际命名卷。
- 没有属性的顶层资源 MUST 使用空值形式：

```yaml
volumes:
  app-data:
```

### STR005 目录独立性与复用

- 每个 Compose 目录 MUST 能独立复制和部署，不依赖仓库根目录公共片段。
- 至少 3 个 service 存在完全相同的多字段块时 MAY 使用 `x-*` 与 YAML anchors。
- 单字段或少量重复 SHOULD 保持展开。
- `include` 与 `extends` 只在大型同项目拆分时 MAY 使用，不用于建立跨项目隐式依赖。

## 4. 镜像、名称与生命周期

### OPS001 镜像版本

- 镜像 tag MUST 可通过环境变量覆盖。
- 默认值使用上游提供的 `stable`；没有 stable 通道时使用 `latest`。
- 历史文件首轮迁移保留原 tag 作为变量默认值，避免格式迁移隐含镜像升级。
- 单服务使用 `IMAGE_TAG`；多服务使用 `APP_IMAGE_TAG`、`POSTGRES_IMAGE_TAG` 等前缀变量。
- 实际部署 SHOULD 在 `.env` 中覆盖为所需版本通道。
- `pull_policy` 默认省略；离线、强制拉取或特殊缓存场景才显式设置。

```yaml
services:
  app:
    image: example/app:${IMAGE_TAG:-stable}
```

### OPS002 container_name

- 已启用的现有 `container_name` 保留。
- 每个缺失的现有 service 和每个新 service MUST 提供注释占位。
- 单服务使用 `CONTAINER_NAME`；多服务使用 service 前缀变量。

```yaml
services:
  app:
    image: example/app:${IMAGE_TAG:-stable}
    # container_name: ${CONTAINER_NAME:-app}
```

顶层 `name` 只在目录名不稳定或确需固定 Compose 项目名时 MAY 使用。

### OPS003 restart

- 长期运行服务 MUST 设置 `restart: unless-stopped`。
- 明确要求宿主重启后持续恢复的特殊服务 MAY 使用 `always`。
- 一次性任务 MAY 省略 restart。
- `on-failure` 只用于失败重试语义，不用于标识持续运行服务。

### OPS004 Watchtower

只有 `restart: always` 或 `restart: unless-stopped` 的服务纳入 Watchtower 管理：

- 普通应用、Web、API、worker、agent、daemon 默认 true。
- PostgreSQL、MySQL、MariaDB、MongoDB、RabbitMQ、Meilisearch、Typesense 等数据库、队列和搜索索引默认 false。
- Redis、Valkey、Kvrocks 等缓存默认 true。
- 一次性任务不添加标签。

单应用使用 `WATCHTOWER_ENABLE`；多服务和默认 false 的状态服务使用 `POSTGRES_WATCHTOWER_ENABLE` 等前缀变量。

```yaml
labels:
  com.centurylinklabs.watchtower.enable: ${WATCHTOWER_ENABLE:-true}
```

### OPS005 日志

- Compose 文件 MUST 不设置 service 级 `logging`。
- Docker daemon MUST 配置日志轮转。
- 本规范不强制 daemon 的日志 driver 或轮转参数，但部署文档必须记录宿主已启用轮转。

## 5. 环境变量与标签

### ENV001 environment

- `environment` MUST 使用 map。
- 变量按业务逻辑分组，保留对应注释；不得强制全局字母排序。
- 变量名称与应用接口保持一致，不擅自重命名镜像要求的键。
- 布尔和数字字符串 MUST 显式双引号。

```yaml
environment:
  LOG_LEVEL: ${LOG_LEVEL:-info}
  FEATURE_ENABLED: "true"
  HTTP_PORT: "8080"
```

### ENV002 env_file

存在 `environment` 的 service MUST 同时使用项目级 `.env`，采用现代 Compose v2 long syntax，并允许文件缺失：

```yaml
env_file:
  - path: .env
    required: false

environment:
  API_URL: ${API_URL:-http://localhost:8080}
```

- 项目 `.env` 会被注入该 service，`environment` 中同名值优先。
- 同一 Compose 项目的多个 service 可以看到 `.env` 中未在 environment 显式列出的其他变量；这是本仓库接受的设计选择。
- `.env` 不得提交。

### ENV003 必填与敏感变量

- 密码、token、API key 等没有安全默认值的敏感变量 MUST 使用 required 插值。
- 非敏感必填项可以继续使用 `${VAR}`，并在 `.env.example` 中说明。
- 不采用 Compose secrets。

```yaml
environment:
  API_TOKEN: ${API_TOKEN:?API_TOKEN is required}
```

### ENV004 .env.example

包含需要人工覆盖或必填变量的项目 MUST 提供 `.env.example`：

```dotenv
# 必填：应用访问令牌
API_TOKEN=

# 可选：镜像版本通道
# IMAGE_TAG=stable
```

- 敏感变量 MUST 留空，不得使用可直接部署的示例密钥。
- 有安全默认值且通常无需修改的变量 MAY 仅以注释形式列出。
- `.env.example` 必须提交，真实 `.env` 必须忽略。

### ENV005 labels

- `labels` MUST 使用 map。
- labels MUST 按完整键名稳定排序。
- 动态 Traefik 键和空值标签必须保留原语义。
- 不保留“watchtower”等可从键名直接判断的冗余行尾注释。

## 6. 网络与端口

### NET001 ports

普通宿主端口 MUST 显式提供可覆盖的绑定地址，默认保持当前全接口行为：

```yaml
ports:
  - "${BIND_ADDRESS:-0.0.0.0}:${PORT:-8080}:8080"
```

- 单服务使用 `PORT`；多服务使用 `APP_PORT`、`ADMIN_PORT` 等有业务含义的变量。
- 普通映射使用短语法。
- 需要 `host_ip`、`protocol`、`app_protocol`、`mode` 或 `name` 时使用长语法。
- ports 列表按主业务端口、管理端口、指标端口、调试端口排列。

### NET002 数据库端口

- 仅供同一 Compose 应用使用的数据库 MUST 不发布宿主端口。
- 需要宿主管理、外部备份或跨项目访问时 MAY 发布，并写明用途。
- 数据库容器仍可通过 Compose 默认网络和 service 名访问。

### NET003 networks

- Compose 默认网络满足需求时 SHOULD 不额外定义网络。
- 反向代理、数据库隔离或跨项目连接时 SHOULD 显式定义。
- Service 仅加入网络时使用 list；需要 aliases、静态地址或优先级等属性时使用 map。
- external 网络不得由格式化流程改为内部网络。

### NET004 extra_hosts

每个缺失的现有 service 和每个新 service MUST 提供以下注释占位，默认不启用：

```yaml
# extra_hosts:
#   - host.docker.internal:host-gateway
```

只有容器确实需要访问宿主服务时才取消注释。

## 7. 存储

### STO001 普通持久化数据

普通 data、config、model 等持久化目录 SHOULD 默认使用命名卷，并允许通过环境变量切换为 bind mount：

```yaml
services:
  app:
    volumes:
      - ${DATA_DIR:-app-data}:/app/data

volumes:
  app-data:
```

- 单服务使用 `DATA_DIR`、`CONFIG_DIR`；多服务使用 service 前缀。
- 环境变量设置为绝对或相对路径时，Compose 将其作为 bind mount。
- 转换现有挂载前必须确认备份、权限、宿主可见性和实际数据位置。

### STO002 特殊挂载

以下挂载 MUST 保持显式，不得套用命名卷默认模式：

- Docker socket。
- `/proc`、`/sys`、`/dev` 和宿主根目录。
- 配置文件、证书和其他单文件挂载。
- 设备映射和 FUSE。
- 明确要求只读的宿主资源。

### STO003 volumes 语法与排序

- 普通 bind mount 和命名卷使用短语法。
- 需要 `bind`、`volume`、`tmpfs`、`image`、`subpath` 等高级选项时使用长语法。
- 列表按主要持久化数据、配置、缓存/临时目录、只读资源、宿主系统资源排列。
- 不机械改变现有命名卷键，避免创建新空卷。

## 8. 健康、依赖与安全

### OPS006 healthcheck

- 镜像自带可靠健康检查时 SHOULD 沿用。
- 服务存在稳定、轻量的探测方式时 SHOULD 添加 healthcheck。
- 不得为所有镜像猜测通用 curl/wget 检查。
- 无需 shell 时使用 `["CMD", ...]`。
- 需要变量、管道或复合命令时使用 `["CMD-SHELL", "..."]`。
- interval、timeout、retries、start_period 沿用上游建议或实测值，不设置全局默认。

### OPS007 depends_on

- 仅表达启动顺序时使用 list。
- 依赖具有可靠 healthcheck 且消费者确需等待可用时，使用 map 与 `condition: service_healthy`。
- 一次性初始化任务 MAY 使用 `service_completed_successfully`。
- 不得仅为统一格式把 list 改为 condition map。

### SEC001 高权限配置

以下字段 MUST 逐服务审查，不得机械增删：

- `privileged`。
- `network_mode: host`。
- `pid: host`、`ipc: host`。
- `devices`、`gpus`。
- `cap_add`、`cap_drop`。
- `security_opt`。
- Docker socket 与宿主系统目录挂载。

### SEC002 可选加固

`read_only`、`cap_drop: ALL`、`no-new-privileges` 只作为 SHOULD 级优化建议。启用前必须确认：

- 镜像写入路径。
- tmpfs 或可写 volume。
- setuid、sudo、设备和 capability 需求。
- 启动、升级、备份和恢复流程。

`user` 与 `hostname` 不纳入本仓库统一规范，保持镜像或项目现状。

## 9. 不纳入全局规则的特性

- `profiles`：本仓库不使用。
- `init`：不设统一要求，保留现有和上游用法。
- `user`、`hostname`：不设统一要求。
- `deploy.resources`：保留现状，不为所有服务补默认限制。
- Compose secrets：本仓库不采用。
- service 级 logging：目标状态移除，由 Docker daemon 管理轮转。

## 10. 完整示例

```yaml
services:
  app:
    image: example/app:${IMAGE_TAG:-stable}
    # container_name: ${CONTAINER_NAME:-app}
    restart: unless-stopped

    depends_on:
      db:
        condition: service_healthy

    ports:
      - "${BIND_ADDRESS:-0.0.0.0}:${PORT:-8080}:8080"

    # extra_hosts:
    #   - host.docker.internal:host-gateway

    env_file:
      - path: .env
        required: false

    environment:
      API_TOKEN: ${API_TOKEN:?API_TOKEN is required}

    labels:
      com.centurylinklabs.watchtower.enable: ${WATCHTOWER_ENABLE:-true}

    healthcheck:
      test: ["CMD", "/app", "health"]
      interval: 30s
      timeout: 10s
      retries: 3

    volumes:
      - ${DATA_DIR:-app-data}:/app/data

  db:
    image: postgres:${POSTGRES_IMAGE_TAG:-latest}
    # container_name: ${POSTGRES_CONTAINER_NAME:-app-db}
    restart: unless-stopped

    # extra_hosts:
    #   - host.docker.internal:host-gateway

    env_file:
      - path: .env
        required: false

    environment:
      POSTGRES_DB: ${POSTGRES_DB:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}
      POSTGRES_USER: ${POSTGRES_USER:-app}

    labels:
      com.centurylinklabs.watchtower.enable: ${POSTGRES_WATCHTOWER_ENABLE:-false}

    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5

    volumes:
      - ${POSTGRES_DATA_DIR:-postgres-data}:/var/lib/postgresql/data

volumes:
  app-data:
  postgres-data:
```

## 11. 参考来源

检索日期：2026-08-24。

- [Compose Specification JSON Schema](https://github.com/compose-spec/compose-spec/blob/main/schema/compose-spec.json)
- [Docker Compose file reference: services](https://docs.docker.com/reference/compose-file/services/)
- [Docker Compose file reference: version and name](https://docs.docker.com/reference/compose-file/version-and-name/)
- [Docker Compose startup order](https://docs.docker.com/compose/how-tos/startup-order/)
- [Docker Compose environment variables](https://docs.docker.com/compose/how-tos/environment-variables/)
- [Docker logging driver configuration](https://docs.docker.com/engine/logging/configure/)
- [DCLint service key ordering](https://github.com/zavoloklom/docker-compose-linter/blob/main/docs/rules/service-keys-order-rule.md)
- [DCLint top-level key ordering](https://github.com/zavoloklom/docker-compose-linter/blob/main/docs/rules/top-level-properties-order-rule.md)
- [Docker Awesome Compose examples](https://github.com/docker/awesome-compose)
- [Grafana Docker Compose documentation](https://github.com/grafana/grafana/blob/main/docs/sources/setup-grafana/installation/docker/index.md)
- [Nextcloud Docker Compose examples](https://github.com/nextcloud/docker/tree/master/.examples/docker-compose)

字段顺序是本仓库的可读性约定，不是 Docker Compose 官方强制顺序。
