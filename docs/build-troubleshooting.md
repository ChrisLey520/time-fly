# 构建与同步排障

本项目使用 HarmonyOS 6.1.1 API 24：

- `compileSdkVersion`: `6.1.1(24)`
- `targetSdkVersion`: `6.1.1(24)`
- `compatibleSdkVersion`: `5.0.0(12)`
- `runtimeOS`: `HarmonyOS`
- Hvigor model version: `6.0.0`

## 一键预检

先运行：

```bash
node scripts/check-deveco-env.mjs
```

如果要在预检通过后直接调用 Hvigor：

```bash
node scripts/check-deveco-env.mjs --assemble
```

也可以透传 Hvigor 参数：

```bash
node scripts/check-deveco-env.mjs --assemble -- assembleHap --no-daemon --stacktrace --debug
```

## `SDK component missing`

Hvigor 报错：

```text
00303168 Configuration Error
Error Message: SDK component missing.
```

本机已验证的原因是 `DEVECO_SDK_HOME` 指到了错误层级：

```bash
# 错误
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk/default

# 正确
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
```

原因：HarmonyOS 构建会同时扫描 `default/openharmony` 和 `default/hms` 下的组件，SDK manager 期望 `DEVECO_SDK_HOME` 是 `sdk` 根目录，而不是 `sdk/default`。

修正后，命令行构建可以推进到 ArkTS 编译和 HAP 打包阶段：

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap --no-daemon --stacktrace
```

## Java Runtime

预检脚本会优先使用 DevEco Studio 自带 JBR：

```bash
/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
```

如果 HAP 打包阶段仍报错：

```text
Tools execution failed.
The operation couldn't be completed. Unable to locate a Java Runtime.
```

说明脚本没有找到 DevEco JBR，也没有找到可用的 `JAVA_HOME`/`java`。可以手动设置：

```bash
export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH
```

再重新运行：

```bash
node scripts/check-deveco-env.mjs --assemble
```

## 当前命令行验证状态

预检脚本会自动修正命令行 Hvigor 子进程的 `DEVECO_SDK_HOME` 和 `JAVA_HOME`。当前代码已通过 `CompileArkTS`、`PackageHap`、`SignHap` 和 `assembleHap`；由于仓库还没有签名配置，`SignHap` 会提示跳过签名。
