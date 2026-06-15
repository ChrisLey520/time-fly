# 栖时

栖时是一个 HarmonyOS 原生专注计时 App 原型。当前仓库已经实现可交互的本地 MVP：专注计时、任务、记录、统计、设置和完成提醒骨架。

## 当前能力

- 应用名：栖时
- 包名：`com.qishi.focus`
- 底部页面：专注 / 任务 / 记录 / 设置
- 专注页支持开始专注、暂停、继续、结束本次、恢复计时
- 专注页提供「快速验证 10 秒」，用于开发期快速验证完成记录
- 专注时长读取设置，默认 25 分钟
- 完成专注后进入待歇息状态，可开始短歇息或跳过
- 支持按配置在固定轮次后进入长歇息
- 完成专注后展示完成反馈和当前专注轮次
- 任务页支持创建任务、设置预计专注次数、开始任务专注、标记完成、删除
- 从任务页开始任务专注后，会自动切回专注页显示倒计时
- 已有专注、暂停或待歇息时，会阻止重复开始并引导回专注页
- 任务页会展示当前专注/歇息状态，当前任务按钮会切换为「查看」
- 专注完成生成 `completed` 记录
- 主动结束生成 `abandoned` 记录
- 记录页展示今日 completed 专注时长、完成次数、任务数、计划时长和历史记录
- 设置页支持调整专注/歇息时长、提醒开关和清除本地数据
- 已接入 2*2 服务卡片骨架，展示当前状态、剩余时间、任务和今日时长
- 通知服务已接入完成链路，真机行为需等 SDK 补齐后验证

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
  assets/           图标源文件
```

## 本地验证

当前机器只安装了模拟器 system image，缺少编译用 HarmonyOS SDK 组件，`hvigorw tasks` 已能通过项目版本检查，但会停在 `SDK component missing`。用 DevEco Studio 打开项目后，按提示安装 HarmonyOS SDK 的 toolchains、ets 和 build-tools 后再构建。

核心计时逻辑可用 Node 验证：

```bash
node test/timer_core.test.mjs
```

## 下一步

1. 在 DevEco Studio 中补齐 HarmonyOS SDK 后构建真机包。
2. 修正可能的 ArkTS 编译细节。
3. 进入下一轮：通知延迟调度、卡片真机验证和更完整的视觉打磨。
