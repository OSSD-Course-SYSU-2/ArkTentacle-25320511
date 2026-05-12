# HarmonyOS 蓝牙设备发现应用 - 构建说明

## 项目结构

```
demo/
├── AppScope/                    # 应用全局配置
│   ├── app.json5               # 应用配置文件
│   └── resources/              # 应用资源
├── entry/                       # 主模块
│   ├── src/main/
│   │   ├── ets/                # ArkTS 源代码
│   │   │   ├── entryability/   # 入口能力
│   │   │   ├── pages/          # 页面
│   │   │   └── utils/          # 工具类
│   │   ├── resources/          # 资源文件
│   │   └── module.json5        # 模块配置
│   ├── build-profile.json5     # 构建配置
│   ├── hvigorfile.ts           # Hvigor 构建脚本
│   └── oh-package.json5        # 包配置
├── build-profile.json5         # 项目构建配置
├── hvigorfile.ts               # 项目 Hvigor 脚本
├── oh-package.json5            # 项目包配置
└── hvigor/                     # Hvigor 配置
```

## 功能特性

1. **蓝牙设备扫描** - 扫描附近的 BLE 设备
2. **设备列表展示** - 显示发现的设备信息
3. **信号强度显示** - RSSI 值和颜色指示
4. **实时更新** - 动态更新设备列表

## 构建要求

- DevEco Studio 3.1 或更高版本
- HarmonyOS SDK API 9 或更高版本
- Node.js 14.x 或更高版本

## 构建步骤

### 1. 安装依赖

```bash
ohpm install
```

### 2. 构建 Debug 版本

```bash
hvigorw assembleHap --mode module -p module=entry@default
```

### 3. 构建 Release 版本

```bash
hvigorw assembleHap --mode module -p module=entry@default -p product=default
```

或者使用 DevEco Studio:
1. 打开项目
2. 选择 Build -> Build Hap(s)/APP(s) -> Build Hap(s)
3. 在 build 目录下找到生成的 HAP 文件

### 4. 打包 APP (可选)

如果需要生成 APP 包用于发布：

```bash
hvigorw assembleApp --mode project -p product=default
```

## 输出位置

构建完成后，输出文件位于：
- Debug HAP: `entry/build/default/outputs/default/entry-default-signed.hap`
- Release HAP: `entry/build/default/outputs/default/entry-default-signed.hap`
- APP: `build/outputs/entry-default-signed.app`

## 权限说明

应用需要以下权限：
- `ohos.permission.USE_BLUETOOTH` - 使用蓝牙
- `ohos.permission.DISCOVER_BLUETOOTH` - 发现蓝牙设备
- `ohos.permission.LOCATION` - 位置权限（蓝牙扫描需要）

## 签名配置

Release 版本需要配置签名：
1. 在 DevEco Studio 中配置签名证书
2. 或在 `build-profile.json5` 中配置签名信息

## 注意事项

1. 确保设备支持蓝牙 BLE
2. 运行时需要授予蓝牙和位置权限
3. 部分设备可能需要开启位置服务才能扫描蓝牙设备
