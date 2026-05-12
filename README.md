# ArkTentacle - 粥批触须

一款基于 HarmonyOS 的蓝牙设备发现与通信应用，支持设备扫描、内容广播和定向消息发送。

## 功能特性

### 核心功能

- **蓝牙设备扫描** - 扫描附近的 BLE 设备并实时显示
- **设备信息展示** - 显示设备名称、ID 和信号强度（RSSI）
- **内容广播** - 将喜爱的角色内容通过蓝牙广播出去
- **定向发送** - 向选中的设备发送游戏ID等自定义消息
- **设备选择** - 点击设备列表项选择目标设备

### 界面功能

- 蓝牙状态实时显示
- 扫描状态提示
- 设备数量统计
- 信号强度颜色指示（绿色：强，黄色：中，红色：弱）
- 设备选中高亮显示
- 发送状态反馈

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
│   │   │   │   └── Index.ets   # 主页面
│   │   │   └── utils/          # 工具类
│   │   │       └── BluetoothManager.ets  # 蓝牙管理类
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

## 使用说明

### 1. 广播喜爱的角色内容

1. 在"可以输入喜爱的角色等内容"输入框中输入内容
2. 点击"开始广播"按钮
3. 内容将通过蓝牙 BLE 广播出去，其他设备可以接收到
4. 点击"停止广播"可以停止广播

### 2. 发送游戏ID到指定设备

1. 点击"开始扫描"按钮扫描附近的蓝牙设备
2. 在设备列表中点击要发送的目标设备（设备会高亮显示）
3. 在"请输入游戏ID"输入框中输入游戏ID
4. 点击"发送游戏ID"按钮
5. 游戏ID将发送到选中的设备

### 3. 查看设备信息

- 设备列表显示所有发现的蓝牙设备
- 每个设备显示：设备名称、设备ID、信号强度（RSSI）
- 信号强度颜色指示：
  - 绿色：信号强（RSSI > -60 dBm）
  - 黄色：信号中等（-80 < RSSI ≤ -60 dBm）
  - 红色：信号弱（RSSI ≤ -80 dBm）

## 技术实现

### 蓝牙功能

- **BLE 扫描**：使用 `bluetooth.startBLEScan()` 扫描附近设备
- **BLE 广播**：使用 `bluetooth.startBLEAdvertising()` 广播自定义数据
- **数据传输**：通过厂商数据（Manufacturer Data）携带自定义消息

### 数据格式

- **服务 UUID**：`0000FFF0-0000-1000-8000-00805F9B34FB`
- **厂商 ID**：`0x01`
- **数据编码**：字符串转字节数组

### 状态管理

使用 `@State` 装饰器管理以下状态：
- 扫描状态（`isScanning`）
- 广播状态（`isAdvertising`）
- 设备列表（`devices`）
- 选中设备（`selectedDevice`）
- 状态消息（`statusMessage`、`sendStatus`）

## 权限说明

应用需要以下权限：

- `ohos.permission.USE_BLUETOOTH` - 使用蓝牙
- `ohos.permission.DISCOVER_BLUETOOTH` - 发现蓝牙设备
- `ohos.permission.LOCATION` - 位置权限（蓝牙扫描需要）

权限已在 `module.json5` 中配置，运行时会自动请求。

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

## 注意事项

1. 确保设备支持蓝牙 BLE
2. 运行时需要授予蓝牙和位置权限
3. 部分设备可能需要开启位置服务才能扫描蓝牙设备
4. 广播内容长度建议不超过 20 字节
5. 设备连接和数据传输功能需要进一步实现 GATT 服务

## 开发说明

### 主要类说明

#### BluetoothManager

蓝牙管理类，封装了所有蓝牙操作：

- `startScan()` - 开始扫描设备
- `stopScan()` - 停止扫描
- `startAdvertising()` - 开始广播
- `stopAdvertising()` - 停止广播
- `sendDataToDevice()` - 发送数据到设备
- `connectToDevice()` - 连接到设备
- `disconnectDevice()` - 断开设备连接

#### Index

主页面，包含所有 UI 和交互逻辑：

- 设备扫描和显示
- 广播控制
- 设备选择
- 消息发送

## 版本历史

### v1.0.0
- 实现基础的蓝牙设备扫描功能
- 实现设备列表展示
- 实现内容广播功能
- 实现定向消息发送功能
- 完善UI界面和交互

## 许可证

本项目仅供学习和研究使用。

## 联系方式

如有问题或建议，请提交 Issue 或 Pull Request。
