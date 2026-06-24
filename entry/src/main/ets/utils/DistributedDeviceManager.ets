import deviceManager from '@ohos.distributedDeviceManager';
import hilog from '@ohos.hilog';

const TAG = 'DistributedDeviceManager';
const DOMAIN = 0x0000;

// 分布式设备信息接口
export interface DistributedDevice {
  deviceId: string;
  deviceName: string;
  deviceType: string;
  deviceState: 'online' | 'offline';
  networkId: string;
}

// 设备状态变化回调
export type DeviceStateCallback = (device: DistributedDevice, state: 'online' | 'offline') => void;
export type DeviceFoundCallback = (devices: DistributedDevice[]) => void;

// 分布式设备管理器
export class DistributedDeviceManager {
  private deviceManager: deviceManager.DeviceManager | null = null;
  private discoveredDevices: Map<string, DistributedDevice> = new Map();
  private onDeviceFound: DeviceFoundCallback | null = null;
  private onDeviceStateChanged: DeviceStateCallback | null = null;
  private isDiscovering: boolean = false;

  constructor() {
    hilog.info(DOMAIN, TAG, 'DistributedDeviceManager created');
    this.initDeviceManager();
  }

  // 初始化设备管理器
  private initDeviceManager(): void {
    try {
      // 创建设备管理器
      this.deviceManager = deviceManager.createDeviceManager('ArkTentacle');
      
      if (this.deviceManager) {
        // 注册设备状态变化监听
        this.deviceManager.on('deviceStateChange', (data: deviceManager.DeviceInfo) => {
          this.handleDeviceStateChange(data);
        });

        // 注册设备发现监听
        this.deviceManager.on('deviceFound', (data: deviceManager.DeviceInfo) => {
          this.handleDeviceFound(data);
        });

        // 注册设备离线监听
        this.deviceManager.on('deviceOffline', (data: deviceManager.DeviceInfo) => {
          this.handleDeviceOffline(data);
        });

        hilog.info(DOMAIN, TAG, 'Device manager initialized successfully');
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to init device manager: %{public}s', JSON.stringify(err));
    }
  }

  // 设置设备发现回调
  setOnDeviceFound(callback: DeviceFoundCallback): void {
    this.onDeviceFound = callback;
  }

  // 设置设备状态变化回调
  setOnDeviceStateChanged(callback: DeviceStateCallback): void {
    this.onDeviceStateChanged = callback;
  }

  // 开始发现设备
  async startDeviceDiscovery(): Promise<boolean> {
    if (!this.deviceManager || this.isDiscovering) {
      hilog.warn(DOMAIN, TAG, 'Device manager not ready or already discovering');
      return false;
    }

    try {
      // 清空已发现的设备列表
      this.discoveredDevices.clear();

      // 开始设备发现
      const subscribeInfo: deviceManager.SubscribeInfo = {
        subscribeId: 0,
        mode: 'DISCOVER_MODE_ACTIVE',
        medium: 'AUTO',
        freq: 'MID',
        isSameAccount: false,
        isWakeRemote: true,
        capability: 'ddmpCapability'
      };

      this.deviceManager.startDeviceDiscovery(subscribeInfo);
      this.isDiscovering = true;
      
      hilog.info(DOMAIN, TAG, 'Device discovery started');
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to start device discovery: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  // 停止设备发现
  async stopDeviceDiscovery(): Promise<void> {
    if (!this.deviceManager || !this.isDiscovering) {
      return;
    }

    try {
      this.deviceManager.stopDeviceDiscovery({
        subscribeId: 0
      });
      this.isDiscovering = false;
      
      hilog.info(DOMAIN, TAG, 'Device discovery stopped');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to stop device discovery: %{public}s', JSON.stringify(err));
    }
  }

  // 处理设备状态变化
  private handleDeviceStateChange(data: deviceManager.DeviceInfo): void {
    const device: DistributedDevice = {
      deviceId: data.deviceId,
      deviceName: data.deviceName || 'Unknown Device',
      deviceType: this.getDeviceType(data.deviceType),
      deviceState: 'online',
      networkId: data.networkId || ''
    };

    hilog.info(DOMAIN, TAG, 'Device state changed: %{public}s', device.deviceName);

    if (this.onDeviceStateChanged) {
      this.onDeviceStateChanged(device, 'online');
    }
  }

  // 处理设备发现
  private handleDeviceFound(data: deviceManager.DeviceInfo): void {
    const device: DistributedDevice = {
      deviceId: data.deviceId,
      deviceName: data.deviceName || 'Unknown Device',
      deviceType: this.getDeviceType(data.deviceType),
      deviceState: 'online',
      networkId: data.networkId || ''
    };

    this.discoveredDevices.set(device.deviceId, device);
    
    hilog.info(DOMAIN, TAG, 'Device found: %{public}s, type: %{public}s', 
      device.deviceName, device.deviceType);

    if (this.onDeviceFound) {
      const devices = Array.from(this.discoveredDevices.values());
      this.onDeviceFound(devices);
    }
  }

  // 处理设备离线
  private handleDeviceOffline(data: deviceManager.DeviceInfo): void {
    const deviceId = data.deviceId;
    const device = this.discoveredDevices.get(deviceId);

    if (device) {
      this.discoveredDevices.delete(deviceId);
      
      hilog.info(DOMAIN, TAG, 'Device offline: %{public}s', device.deviceName);

      if (this.onDeviceStateChanged) {
        this.onDeviceStateChanged(device, 'offline');
      }

      if (this.onDeviceFound) {
        const devices = Array.from(this.discoveredDevices.values());
        this.onDeviceFound(devices);
      }
    }
  }

  // 获取设备类型
  private getDeviceType(type: number): string {
    switch (type) {
      case 0x00:
        return 'UNKNOWN';
      case 0x01:
        return 'PHONE';
      case 0x02:
        return 'TABLET';
      case 0x03:
        return 'TV';
      case 0x04:
        return 'PC';
      case 0x05:
        return 'CAR';
      case 0x06:
        return 'WEARABLE';
      case 0x07:
        return 'DEFAULT';
      default:
        return 'UNKNOWN';
    }
  }

  // 获取已发现的设备列表
  getDiscoveredDevices(): DistributedDevice[] {
    return Array.from(this.discoveredDevices.values());
  }

  // 获取发现状态
  getDiscoveryState(): boolean {
    return this.isDiscovering;
  }

  // 清理资源
  cleanup(): void {
    if (this.deviceManager) {
      try {
        this.stopDeviceDiscovery();
        this.deviceManager.off('deviceStateChange');
        this.deviceManager.off('deviceFound');
        this.deviceManager.off('deviceOffline');
        
        hilog.info(DOMAIN, TAG, 'Device manager cleanup completed');
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'Failed to cleanup: %{public}s', JSON.stringify(err));
      }
    }
    
    this.discoveredDevices.clear();
    this.onDeviceFound = null;
    this.onDeviceStateChanged = null;
  }
}
