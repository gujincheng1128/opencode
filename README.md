# opencode — 个人配置备份仓库

OpenCode 的长期策略、权限配置与迁移脚本的云端备份。
每次升级 / 重装 / 配置改动后，按 `strategy/MEMORY.md` 的固化流程执行。

## 目录结构

```
config/    opencode.jsonc          权限与技能白名单（permission.skill）
strategy/  MEMORY.md               C→G 迁移永久策略 + 技能加载策略
scripts/   Move-OpenCode.ps1       一键迁移脚本（纯 ASCII，避免 PS5.1 GBK 乱码）
           Run-MoveOpenCode.bat    管理员一键启动器
```

## 核心策略速览

1. **C 盘零残留**：每次升级/改动后，将 C 盘 OpenCode 数据镜像至 `G:\opencode\.opencode`，原路径建 Junction 软链接，清理 C 盘残留。
2. **技能加载**：仅常驻 9 个白名单技能（allow），其余一律触发式（ask），运行以极简快捷高速为基准。
3. **验证标准**：C 盘真实数据 0 字节；OpenCode 启动后配置/会话/日志读写正常。

## 常用命令

```powershell
# 迁移（管理员运行）
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Move-OpenCode.ps1

# 提交备份
git add -A; git commit -m "backup"; git push
```

---
Git 身份：gujincheng1128 &lt;273104732@qq.com&gt;
