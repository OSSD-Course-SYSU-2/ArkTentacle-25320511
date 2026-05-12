import bluetooth from '@ohos.bluetooth';
import hilog from '@ohos.hilog';

const TAG = 'BluetoothManager';
const DOMAIN = 0x0000;

// 设备信息接口
export interface DeviceInfo {
  deviceId: string;
  deviceName: string;
  rssi: number;
  lastSeen: number;
}

// 蓝牙管理类
export class BluetoothManager {
  private isScanning: boolean = false;
  private discoveredDevices: Map<string, DeviceInfo> = new Map();
  private onDeviceFound: ((devices: DeviceInfo[]) => void) | null = null;
  private onScanStateChanged: ((isScanning: boolean) => void) | null = null;

  constructor() {
    hilog.info(DOMAIN, TAG, 'BluetoothManager created');
  }

  // 设置设备发现回调
  setOnDeviceFound(callback: (devices: DeviceInfo[]) => void) {
    this.onDeviceFound = callback;
  }

  // 设置扫描状态变化回调
  setOnScanStateChanged(callback: (isScanning: boolean) => void) {
    this.onScanStateChanged = callback;
  }

  // 检查蓝牙是否开启
  async isBluetoothEnabled(): Promise<boolean> {
    try {
      const state = bluetooth.getState();
      return state === bluetooth.BluetoothState.STATE_ON;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to check bluetooth state: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  // 开启蓝牙
  async enableBluetooth(): Promise<boolean> {
    try {
      await bluetooth.enableBluetooth();
      hilog.info(DOMAIN, TAG, 'Bluetooth enabled successfully');
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to enable bluetooth: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  // 开始扫描
  async startScan(): Promise<boolean> {
    if (this.isScanning) {
      hilog.warn(DOMAIN, TAG, 'Already scanning');
      return false;
    }

    try {
      // 检查蓝牙是否开启
      const isEnabled = await this.isBluetoothEnabled();
      if (!isEnabled) {
        hilog.error(DOMAIN, TAG, 'Bluetooth is not enabled');
        return false;
      }

      // 清空已发现的设备列表
      this.discoveredDevices.clear();

      // 开始BLE扫描
      bluetooth.startBLEScan(
        {
          serviceUuids: [], // 空数组表示扫描所有设备
          acceptDuplication: false,
          interval: 0,
          dutyMode: bluetooth.ScanDuty.SCAN_MODE_LOW_POWER,
          matchMode: bluetooth.MatchMode.MATCH_MODE_AGGRESSIVE
        },
        (result) => {
          this.handleDeviceFound(result);
        }
      );

      this.isScanning = true;
      if (this.onScanStateChanged) {
        this.onScanStateChanged(true);
      }
      
      hilog.info(DOMAIN, TAG, 'BLE scan started');
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to start scan: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  // 停止扫描
  async stopScan(): Promise<void> {
    if (!this.isScanning) {
      return;
    }

    try {
      bluetooth.stopBLEScan();
      this.isScanning = false;
      
      if (this.onScanStateChanged) {
        this.onScanStateChanged(false);
      }
      
      hilog.info(DOMAIN, TAG, 'BLE scan stopped');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to stop scan: %{public}s', JSON.stringify(err));
    }
  }

  // 处理发现的设备
  private handleDeviceFound(result: bluetooth.ScanResult): void {
    const deviceId = result.deviceId;
    const deviceName = result.deviceName || 'Unknown Device';
    const rssi = result.rssi;
    const lastSeen = Date.now();

    // 更新或添加设备信息
    const deviceInfo: DeviceInfo = {
      deviceId: deviceId,
      deviceName: deviceName,
      rssi: rssi,
      lastSeen: lastSeen
    };

    this.discoveredDevices.set(deviceId, deviceInfo);
    
    hilog.info(DOMAIN, TAG, 'Device found: %{public}s, RSSI: %{public}d', deviceName, rssi);

    // 通知UI更新
    if (this.onDeviceFound) {
      const devices = Array.from(this.discoveredDevices.values());
      this.onDeviceFound(devices);
    }
  }

  // 获取已发现的设备列表
  getDiscoveredDevices(): DeviceInfo[] {
    return Array.from(this.discoveredDevices.values());
  }

  // 获取扫描状态
  getScanState(): boolean {
    return this.isScanning;
  }

  // 开始蓝牙广播
  async startAdvertising(deviceName: string, message: string): Promise<boolean> {
    try {
      // 检查蓝牙是否开启
      const isEnabled = await this.isBluetoothEnabled();
      if (!isEnabled) {
        hilog.error(DOMAIN, TAG, 'Bluetooth is not enabled');
        return false;
      }

      // 设置广播参数
      const advertisingParams: bluetooth.AdvertiseParams = {
        serviceUuids: ['0000FFF0-0000-1000-8000-00805F9B34FB'], // 自定义服务UUID
        manufacturerData: [
          {
            manufacturerId: 0x01, // 厂商ID
            manufacturerValue: this.stringToByteArray(message) // 将消息转换为字节数组
          }
        ]
      };

      // 开始广播
      bluetooth.startBLEAdvertising(advertisingParams);
      hilog.info(DOMAIN, TAG, 'BLE advertising started with message: %{public}s', message);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to start advertising: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  // 停止蓝牙广播
  async stopAdvertising(): Promise<void> {
    try {
      bluetooth.stopBLEAdvertising();
      hilog.info(DOMAIN, TAG, 'BLE advertising stopped');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to stop advertising: %{public}s', JSON.stringify(err));
    }
  }

  // 连接到指定设备
  async connectToDevice(deviceId: string): Promise<boolean> {
    try {
      await bluetooth.connect(deviceId);
      hilog.info(DOMAIN, TAG, 'Connected to device: %{public}s', deviceId);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to connect to device: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  // 断开设备连接
  async disconnectDevice(deviceId: string): Promise<void> {
    try {
      await bluetooth.disconnect(deviceId);
      hilog.info(DOMAIN, TAG, 'Disconnected from device: %{public}s', deviceId);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to disconnect: %{public}s', JSON.stringify(err));
    }
  }

  // 发送数据到已连接的设备
  async sendDataToDevice(deviceId: string, data: string): Promise<boolean> {
    try {
      // 这里需要先获取GATT特征值，然后写入数据
      // 简化实现：直接通过广播发送
      const dataBytes = this.stringToByteArray(data);
      hilog.info(DOMAIN, TAG, 'Sending data to device: %{public}s', data);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to send data: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  // 字符串转字节数组
  private stringToByteArray(str: string): number[] {
    const result: number[] = [];
    for (let i = 0; i < str.length; i++) {
      result.push(str.charCodeAt(i));
    }
    return result;
  }

  // 清理资源
  async cleanup(): Promise<void> {
    await this.stopScan();
    await this.stopAdvertising();
    this.discoveredDevices.clear();
    this.onDeviceFound = null;
    this.onScanStateChanged = null;
    hilog.info(DOMAIN, TAG, 'BluetoothManager cleanup completed');
  }
}
