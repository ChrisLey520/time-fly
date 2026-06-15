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

检查 DevEco `hdc` 是否能看到设备/模拟器：

```bash
node scripts/check-deveco-env.mjs --device
```

构建并同时检查设备：

```bash
node scripts/check-deveco-env.mjs --assemble --device
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

预检脚本会在调用 Hvigor 子进程时自动修正为正确路径：

```bash
node scripts/check-deveco-env.mjs --assemble
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

当前构建产物：

```text
entry/build/default/outputs/default/entry-default-unsigned.hap
```

这是未签名 HAP，普通真机/模拟器安装前需要在 DevEco Studio 中补齐签名配置。

## 签名配置

当前 `build-profile.json5` 中 `products[0].signingConfig` 引用了 `default`，但 `app.signingConfigs` 仍为空。DevEco 自动生成签名后通常会补齐：

```json5
"signingConfigs": [
  {
    "name": "default",
    "type": "HarmonyOS",
    "material": {
      "storeFile": "...",
      "storePassword": "...",
      "keyAlias": "...",
      "keyPassword": "...",
      "signAlg": "SHA256withECDSA",
      "profile": "...",
      "certpath": "..."
    }
  }
]
```

签名材料不要手写进公共仓库；在 DevEco Studio 中配置本机签名后再安装验证。

## 安装检查

确认设备连接：

```bash
node scripts/check-deveco-env.mjs --device
```

脚本会使用：

```text
/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc
```

如果已有签名 HAP，可使用：

```bash
node scripts/check-deveco-env.mjs --install
```

当只有 `*-unsigned.hap` 时，脚本会阻止直接安装并提示先配置签名。
