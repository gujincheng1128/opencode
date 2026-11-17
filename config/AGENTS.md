# OpenCode 永久策略（全局指令，每次会话自动生效）

> 详细版：`G:\opencode\gz\opencode-config\strategy\MEMORY.md`（备份仓库 gujincheng1128/opencode）

## 1. C→G 迁移永久策略（升级 / 重装 / 更新 / 配置改动后必须执行）

触发时机：**每次 OpenCode 升级安装后或有改动后，必须完整执行以下方案一次**。

1. **查询**：扫描 C 盘所有 OpenCode 相关配置、缓存、数据、日志、`.opencode` 目录及所占空间大小（Junction 不计物理占用）。
2. **迁移**：将 C 盘所有 OpenCode 数据完整迁移至 `G:\opencode\.opencode`；迁移失败/无法直接移动的文件或目录，创建符号链接（Junction）指向 `G:\opencode\.opencode`。
3. **清理**：在 OpenCode 完全正常运行的前提下，清理 C 盘残留的无用缓存、临时文件、冗余配置、日志、空目录。
4. **验收**：C 盘 OpenCode 路径全部为 Junction 或不存在（真实数据 0 字节）；全程会话/进程零中断；保证 OpenCode 不再往 C 盘写入任何信息资料。

关键陷阱：删除 Junction 只能 `Remove-Item -Force`（禁 `-Recurse` 穿透删 G 盘数据）；robocopy 退出码 0–7 为成功；升级会重建 C 盘目录覆盖链接，升级后第一时间重跑。

## 2. 技能加载规则

- **常驻白名单 10 个**（allow）：`ai-coding-pipeline` / `m3-coding` / `m3-debug` / `m3-fusion` / `m3-pipeline` / `m3-suite` / `nihaixia` / `opencode-migrate` / `opencode-evo-fusion` / `opencode-self-evolving-memory`
- 除此以外的所有技能：仅命中触发条件时临时调用；非触发状态不加载、不启用、不主动推荐。
- 运行基准：全程程序完全稳定正常运行；优先极简快捷、高速响应。

## 3. 数据落位（当前实测 2026-11-17）

- C 盘 OpenCode 真实数据 = 0 字节，13 个 Junction 全部指向 `G:\opencode\.opencode`。
- 程序本体：`G:\opencode\opencode\OpenCode.exe`；技能目录：`G:\opencode\.opencode\migrated\config-opencode\skills`。
