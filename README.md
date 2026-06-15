# 栖时

栖时是一个 HarmonyOS 原生专注计时 App 原型。当前仓库已经实现可交互的本地 MVP：专注计时、任务、记录、统计、设置、系统提醒和服务卡片骨架。

## 当前能力

- 应用名：栖时
- 包名：`com.qishi.focus`
- 底部页面：专注 / 任务 / 记录 / 设置
- 专注页支持开始专注、暂停、继续、结束本次和自动恢复计时
- 设置页可开启「开发调试」后显示「快速验证 10 秒」，用于真机调试完成链路
- 专注时长读取设置，默认 25 分钟
- 完成专注后进入待歇息状态，可开始短歇息或跳过
- 支持按配置在固定轮次后进入长歇息
- 支持配置每日专注目标，专注页展示今日目标进度和剩余目标时长
- 完成专注后展示完成反馈和当前专注轮次
- 任务页支持创建任务、编辑任务、设置预计专注次数、开始任务专注、标记完成、归档、恢复和删除
- 任务页展示任务进度、剩余专注次数、目标达成状态和当前专注状态
- 从任务页开始任务专注后，会自动切回专注页显示倒计时
- 已有专注、暂停或待歇息时，会阻止重复开始并引导回专注页
- 任务页会展示当前专注/歇息状态，当前任务按钮会切换为「查看」
- 正在专注的任务会锁定编辑、手动完成、归档和删除，避免专注记录与任务进度脱节
- 专注完成生成 `completed` 记录
- 主动结束生成 `abandoned` 记录
- 记录页展示今日 completed 专注时长、完成次数、任务数、计划时长和历史记录
- 记录页支持按全部 / 已完成 / 已结束筛选，并展示完成率、结束次数、平均完成时长
- 记录页按日期分组历史记录，支持删除单条记录和清空全部记录
- 记录页展示本周总专注、活跃日均、最佳日和最近 7 天柱状概览
- 设置页支持调整专注/歇息时长、提醒开关、恢复默认节奏和清除本地数据
- 设置页支持调整每日目标时长
- 已接入 2*2 服务卡片骨架，展示当前状态、剩余时间、任务、今日时长和目标进度
- 通知服务已接入完成链路，系统级延迟提醒使用 `@ohos.reminderAgentManager`
- 应用图标已同步到 AppScope 和 entry 资源，使用居中的 256px 图标资源

## 工程结构

```text
entry/src/main/ets/
  components/       基础 UI 组件
  entryability/     应用入口
  entryformability/ 服务卡片入口
  models/           数据模型
  pages/            页面
  services/         Storage / Timer / Session 服务
  widget/           服务卡片页面
  utils/            时间格式化、ID
docs/
  widget-design.md  服务卡片设计与快照接口
  build-troubleshooting.md DevEco/Hvigor 构建排障
  assets/           图标源文件
scripts/
  check-deveco-env.mjs DevEco/Hvigor 环境预检
```

## 本地验证

核心计时逻辑可用 Node 验证：

```bash
node test/timer_core.test.mjs
node test/stats_core.test.mjs
```

DevEco/Hvigor 环境可用预检脚本验证：

```bash
node scripts/check-deveco-env.mjs
```

构建并同时检查设备：

```bash
node scripts/check-deveco-env.mjs --assemble --device
```

确认环境通过后可直接构建 HAP：

```bash
node scripts/check-deveco-env.mjs --assemble
```

当前项目要求 `DEVECO_SDK_HOME` 指向 DevEco SDK 根目录，例如 `/Applications/DevEco-Studio.app/Contents/sdk`。如果指到 `sdk/default`，Hvigor 会报 `SDK component missing`。详细排障见 [docs/build-troubleshooting.md](docs/build-troubleshooting.md)。

## 下一步

1. 在 DevEco Studio 中补充签名配置并做真机/模拟器安装验证。
2. 真机验证服务卡片刷新、系统提醒触发和后台计时恢复。
