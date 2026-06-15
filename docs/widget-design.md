# 栖时服务卡片设计

第一版服务卡片保持轻量，不在卡片上塞完整操作流。

## 空闲态

```text
栖时
准备专注
今日 0 分钟
自由专注
```

## 专注中

```text
栖时
正在专注
18:32
阅读产品文档
```

## 数据来源

服务卡片使用 `WidgetService.getSnapshot()` 读取轻量快照：

```ts
interface WidgetSnapshot {
  todayFocusSeconds: number
  currentTaskTitle: string
  timerStatus: string
  remainingSeconds: number
  updatedAt: number
}
```

## 当前接入

当前已新增 `EntryFormAbility`、`form_config.json` 和 `WidgetCard.ets`，卡片使用 2*2 规格。主 App 的开始、暂停、继续、结束、任务变更和清除数据会触发卡片刷新；运行中卡片会请求 1 分钟后的下一次系统刷新。

命令行构建目前仍被本机 `SDK component missing` 阻断，需在 DevEco Studio 补齐 SDK 后做真机/模拟器验证。
