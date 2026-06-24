# 华为鸿蒙多端部署与一键流转功能说明

## 功能概述

本项目已实现华为鸿蒙特有的多端部署和一键流转功能，支持在不同鸿蒙设备之间无缝流转应用数据。

## 核心组件

### 1. DistributedDeviceManager (分布式设备管理器)
- **位置**: `entry/src/main/ets/utils/DistributedDeviceManager.ets`
- **功能**: 
  - 发现附近的分布式设备（手机、平板、TV、PC等）
  - 监听设备上下线状态
  - 管理设备连接

### 2. HopManager (流转管理器)
- **位置**: `entry/src/main/ets/utils/HopManager.ets`
- **功能**:
  - 实现一键流转功能
  - 管理流转状态（idle、preparing、hopping、completed、failed）
  - 处理流转数据的发送和接收

### 3. DataSyncManager (数据同步管理器)
- **位置**: `entry/src/main/ets/utils/DataSyncManager.ets`
- **功能**:
  - 实时同步应用数据到分布式对象
  - 监听远程数据变化
  - 支持多端数据一致性

## 使用方法

### 1. 发现分布式设备
1. 点击"发现分布式设备"按钮
2. 系统会自动扫描附近的鸿蒙设备
3. 在设备列表中查看发现的设备

### 2. 选择目标设备
1. 在分布式设备列表中点击要流转的目标设备
2. 设备会被标记为"已选中"状态

### 3. 准备流转数据
1. 在"可以输入喜爱的角色等内容"输入框中输入角色信息
2. 在"请输入游戏ID"输入框中输入游戏ID

### 4. 执行一键流转
1. 点击"一键流转"按钮
2. 系统会将当前数据流转到选中的目标设备
3. 流转状态会实时显示

### 5. 接收流转数据
- 当其他设备向本设备流转数据时，会自动接收并显示
- 接收到的数据会显示在"接收到流转数据"区域
- 数据会自动填充到输入框中

## 权限说明

应用已配置以下分布式权限：

1. **ohos.permission.DISTRIBUTED_DATASYNC**: 分布式数据同步权限
2. **ohos.permission.DISTRIBUTED_DEVICE_STATE_CHANGE**: 设备状态变化监听权限
3. **ohos.permission.GET_DISTRIBUTED_DEVICE_INFO**: 获取分布式设备信息权限
4. **ohos.permission.ACCESS_SERVICE_DM**: 访问设备管理服务权限

## 技术实现

### 分布式数据对象
使用 `@ohos.data.distributedDataObject` API 实现跨设备数据同步：
- 创建会话ID标识数据对象
- 监听数据变化事件
- 支持数据保存和恢复

### 设备管理
使用 `@ohos.distributedDeviceManager` API 实现设备发现和管理：
- 主动发现附近设备
- 监听设备状态变化
- 支持多种设备类型（手机、平板、TV、PC等）

### 流转流程
1. **准备阶段**: 收集当前应用数据
2. **流转阶段**: 将数据同步到分布式对象
3. **保存阶段**: 保存数据到目标设备
4. **接收阶段**: 目标设备接收并恢复数据

## 支持的设备类型

- PHONE (手机)
- TABLET (平板)
- TV (电视)
- PC (电脑)
- CAR (车机)
- WEARABLE (可穿戴设备)

## 注意事项

1. **网络要求**: 所有设备需要在同一局域网下
2. **账号要求**: 设备需要登录同一华为账号（可选）
3. **权限授予**: 首次使用需要授予分布式权限
4. **设备距离**: 设备距离不宜过远，建议在10米范围内

## 示例场景

### 场景1: 手机到平板流转
1. 在手机上输入角色信息和游戏ID
2. 发现并选择平板设备
3. 点击一键流转
4. 平板自动接收并显示数据

### 场景2: 多设备协同
1. 多个设备同时在线
2. 任意设备可以发起流转
3. 其他设备实时接收数据
4. 实现多端数据同步

## API参考

### DistributedDeviceManager
```typescript
// 开始设备发现
startDeviceDiscovery(): Promise<boolean>

// 停止设备发现
stopDeviceDiscovery(): Promise<void>

// 获取已发现的设备列表
getDiscoveredDevices(): DistributedDevice[]
```

### HopManager
```typescript
// 准备流转数据
prepareHopData(deviceName: string, message: string, deviceId: string): void

// 执行流转
hopToDevice(targetDevice: DistributedDevice): Promise<boolean>

// 获取流转状态
getHopState(): HopState
```

### DataSyncManager
```typescript
// 更新本地数据
updateLocalData(data: Partial<SyncData>): void

// 保存数据到指定设备
saveToDevice(networkId: string): Promise<boolean>

// 获取当前数据
getCurrentData(): SyncData
```

## 更新日志

### v1.0.0
- 实现分布式设备发现功能
- 实现一键流转功能
- 实现数据同步功能
- 添加多端协同UI界面
- 配置分布式权限
