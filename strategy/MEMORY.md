# MEMORY.md — OpenCode C 盘 → G 盘 迁移永久策略

> 本文件固化 OpenCode 在 C 盘零残留的迁移与符号链接策略。
> 触发时机：**每次 OpenCode 升级 / 重装 / 更新 / 有配置改动后**，必须执行本策略。
> （2026-11-16 更新：目标盘由 D 盘改为 **G:\opencode\.opencode**，旧 D 盘映射条目保留作升级后新增目录预案。）

---

## 1. 核心目标

- OpenCode 程序完全正常运行的前提下，**C 盘不保留任何 OpenCode 真实数据**（配置、缓存、数据、日志、.opencode 目录等）。
- 所有 OpenCode 数据完整落在 `G:\opencode\.opencode`。
- 迁移失败 / 无法直接移动的文件 / 目录 → 创建符号链接（软链接）指向 `G:\opencode\.opencode`。
- 迁移 & 符号链接部署完成后，在确保 OpenCode 可正常完整运行的前提下，清理 C 盘残留的无用缓存、临时文件、冗余配置、日志、空目录。
- 最终效果：OpenCode 通过原 C 盘路径透明读写，实际数据全部在 G 盘，**不往 C 盘写任何信息和资料**。

---

## 2. 触发时机

| 场景 | 是否必须执行 |
|------|-------------|
| OpenCode 升级 | ✅ 必须 |
| OpenCode 重装 | ✅ 必须 |
| OpenCode 更新 | ✅ 必须 |
| OpenCode 配置/数据有改动 | ✅ 必须 |
| 发现 C 盘出现新的 OpenCode 真实目录（非链接） | ✅ 必须 |

> 升级会重建 C 盘默认目录并覆盖符号链接 → 升级后第一时间重跑本策略。

---

## 3. 执行步骤（固化方案）

### 步骤 1：查询 C 盘 OpenCode 所有数据和资料及空间大小

用 Python 扫描（自动识别 Junction，Junction 不计物理占用）以下路径：

```
%USERPROFILE%\.opencode
%USERPROFILE%\.config\opencode
%USERPROFILE%\.cache\opencode
%USERPROFILE%\.local\share\opencode
%USERPROFILE%\.local\state\opencode
%APPDATA%\opencode
%LOCALAPPDATA%\opencode
%LOCALAPPDATA%\cache\opencode
%USERPROFILE%\.codearts\kernel\.opencode\agents
%APPDATA%\ai.opencode.desktop
%LOCALAPPDATA%\Programs\OpenCode
%LOCALAPPDATA%\@opencode-aidesktop-updater
%LOCALAPPDATA%\@opencodedesktop-updater
%TEMP%\opencode
```

输出：每个路径的 存在/是否链接/字节大小 + 总计。

### 步骤 2：完整迁移至 G:\opencode\.opencode

对每个存在的 C 盘真实目录：

1. 已是指向 G 盘的正确符号链接 → 跳过（幂等）
2. 真实目录 → `robocopy /MIR` 全量镜像到 `G:\opencode\.opencode\<对应子目录>` → 清空 C 盘原目录内容 → `mklink /J` 在原路径创建 Junction 指向 G 盘
3. 不存在但父目录存在 → 直接创建 Junction（拦截未来写入）
4. 迁移失败 / 无法直接移动 → 创建符号链接（软链接）指向 `G:\opencode\.opencode`

### 步骤 3：清理 C 盘残留

在确保 OpenCode 正常运行前提下，清理 C 盘：

- 无用缓存、临时文件（`%TEMP%\opencode*` 等）
- 冗余配置、日志、空目录

### 步骤 4：验证

- [ ] C 盘所有 OpenCode 路径均为 Junction/symlink 或不存在（真实数据 = 0 字节）
- [ ] 每个链接正确指向 `G:\opencode\.opencode\...`
- [ ] 启动 OpenCode，配置/会话/日志可正常读写
- [ ] C 盘无新增 OpenCode 真实文件

---

## 4. 迁移映射表（C 盘 → G 盘，2026-11-16 实测生效）

| C 盘源路径 | G 盘目标路径 | 链接类型 |
|-----------|-------------|---------|
| `%USERPROFILE%\.opencode` | `G:\opencode\.opencode` | junction |
| `%USERPROFILE%\.config\opencode` | `G:\opencode\.opencode\config` | junction |
| `%USERPROFILE%\.cache\opencode` | `G:\opencode\.opencode\cache` | junction |
| `%APPDATA%\opencode` | `G:\opencode\.opencode\roaming` | junction |
| `%LOCALAPPDATA%\opencode` | `G:\opencode\.opencode\local` | junction |
| `%USERPROFILE%\.codearts\kernel\.opencode\agents` | `G:\opencode\.opencode\agents` | junction |
| `%TEMP%\opencode` | `G:\opencode\.opencode\temp` | junction |
| `%USERPROFILE%\.local\share\opencode` | `G:\opencode\.opencode\share` | junction（预案） |
| `%USERPROFILE%\.local\state\opencode` | `G:\opencode\.opencode\state` | junction（预案） |
| `%APPDATA%\ai.opencode.desktop` | `G:\opencode\.opencode\AppData\Roaming\ai.opencode.desktop` | junction（预案） |
| `%LOCALAPPDATA%\Programs\OpenCode` | `G:\opencode\.opencode\AppData\Local\Programs\OpenCode` | junction（预案） |

---

## 5. 自动化脚本（本会话已固化）

| 文件 | 作用 |
|------|------|
| `G:\opencode\gz\Move-OpenCode.ps1` | 主迁移脚本（**纯 ASCII 无中文**，避免 PS 5.1 GBK 乱码假语法错误）；逻辑：跳过已是 Junction → robocopy 镜像 → 清空源 → mklink /J → VERIFY 验证 |
| `G:\opencode\gz\Run-MoveOpenCode.bat` | 一键启动器：`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Move-OpenCode.ps1"` + pause |

**运行方式**：右键 `Run-MoveOpenCode.bat` → **以管理员身份运行**（需先关闭 OpenCode，避免文件被锁）。
脚本幂等，可重复运行；结尾输出 `RESULT:` 行与每个链接的 `[OK]` 验证。

**编码教训（重要）**：Windows PowerShell 5.1 按 ANSI/GBK 读取无 BOM 的 UTF-8 脚本，脚本内含中文/emoji 会导致乱码 + 假 ParserError。此脚本必须保持纯 ASCII。

---

## 6. 当前状态（2026-11-16 已核实）

| 项目 | 数值 |
|------|------|
| C 盘真实 OpenCode 数据 | **0 字节**（0 MB） |
| C 盘 Junction 数量 | 5 个（`.opencode` / `.config\opencode` / `.cache\opencode` / `%APPDATA%\opencode` / `%LOCALAPPDATA%\opencode`，全部指向 G 盘） |
| 实际数据位置 | `G:\opencode\.opencode` |
| OpenCode 程序位置 | `D:\opencode\opencode\OpenCode.exe` |

---

## 7. 注意事项 / 陷阱

- Junction/symlink 创建需要管理员权限；`mklink /J`（Junction）对目录无需开发者模式，优先用 Junction
- **删除 Junction 只能用 `rmdir` / `Remove-Item -Force`（非 -Recurse 语义穿透）**，绝不能 `Remove-Item -Recurse` 穿透链接删 G 盘真实数据
- 升级会重建 C 盘目录并覆盖链接 → 升级后第一时间重跑脚本（幂等安全）
- `%TEMP%` 可能被系统清理任务删除；若 Junction 被删，重跑脚本恢复
- 迁移前若 OpenCode 正在运行，先关闭，避免文件被锁导致 robocopy 失败
- robocopy 退出码 0–7 为成功，≥8 才是失败
- 脚本只搬移 OpenCode 自身数据，**不写入 C 盘**
- 不得删除 `raw/` 原文、不得改写知识库死规矩、不得引入带斜杠的链接（知识库规则）

---

## 8. 技能加载策略（2026-11-16 最新指令，覆盖此前 m3-integrated 优先策略）

### ⭐ 常驻白名单（仅 9 个，其余一律触发式）

`ai-coding-pipeline` / `m3-coding` / `m3-debug` / `m3-fusion` / `m3-pipeline` / `m3-suite` / `nihaixia` / `opencode-migrate` / `opencode-self-evolution`

### 调用规则

- **仅常驻加载上述 9 个指定技能**
- **除此以外的所有技能**（含 `m3-integrated` / `m3-evolution` / `m3-memory` / `opencode-self-evolving-memory` / `xiaoxue-core` / `browser` / `opencode` / `report` / 未来新增）：**仅在明确命中触发条件时才临时调用**；非触发状态不加载正文、不主动启用、不在回答中主动推荐。
- 加载原则：最小上下文——技能正文只按需加载，一次任务不加载无关技能，不因"可能有用"而预加载。

### 运行基准（最高优先）

- **全程保持程序完全稳定正常运行**
- **优先极简、快捷、高速响应**：避免不必要的全盘扫描、长命令、重复读取与冗长输出
- 冲突处理：本策略优先于技能描述里的"自动加载/协同加载"建议；只有用户明确要求或任务确实命中触发词时才越界调用

### 权限对应（opencode.jsonc → permission.skill）

- 上述 9 个常驻技能 = `allow`
- 其余全部技能（含 5 个融合版技能与 browser/opencode/report）= `ask`，兜底 `"*": "ask"`
- 注：全局 AGENTS.md 文件当前缺失，权限实际以 `opencode.jsonc` 为准；技能注册目录 `~/.config/opencode/skills/`（junction → `G:\AiSof\skill\`）不受影响，仅调用策略按本节执行。

### 注册技能清单（存档，10 个 junction，不因本策略删除）

`ai-coding-pipeline` / `m3-coding` / `m3-debug` / `m3-evolution` / `m3-fusion` / `m3-integrated` / `m3-memory` / `m3-suite` / `opencode-self-evolving-memory` / `xiaoxue-core`

---

> 此策略已固化进长期记忆（MEMORY.md），触发时机"升级安装后或有改动后"都必须执行。技能仅常驻加载 9 个白名单技能，其余一律触发式，运行以极简快捷高速为基准。
