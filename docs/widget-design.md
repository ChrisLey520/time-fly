# 栖时服务卡片设计

第一版服务卡片保持轻量，不在卡片上塞完整操作流。

## 空闲态

```text
栖时
今日已专注 1小时20分
开始专注
```

## 专注中

```text
栖时
专注中
剩余 18:32
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

## 接入时机

等 DevEco Studio 补齐 HarmonyOS SDK 后，再新增 FormExtensionAbility 和卡片资源。先验证主 App 的计时与通知，避免同时踩两个平台能力坑。
