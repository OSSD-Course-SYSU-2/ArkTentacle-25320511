import distributedObject from '@ohos.data.distributedDataObject';
import hilog from '@ohos.hilog';
import { DistributedDevice } from './DistributedDeviceManager';

const TAG = 'HopManager';
const DOMAIN = 0x0000;

// 流转数据接口
export interface HopData {
  deviceName: string;
  message: string;
  timestamp: number;
  deviceId: string;
}

// 流转状态
export type HopState = 'idle' | 'preparing' | 'hopping' | 'completed' | 'failed';

// 流转状态变化回调
export type HopStateCallback = (state: HopState, message: string) => void;

// 流转管理器
export class HopManager {
  private distributedObject: distributedObject.DataObject | null = null;
  private sessionId: string = 'ArkTentacle_Session';
  private hopState: HopState = 'idle';
  private onHopStateChanged: HopStateCallback | null = null;
  private currentData: HopData | null = null;

  constructor() {
    hilog.info(DOMAIN, TAG, 'HopManager created');
    this.initDistributedObject();
  }

  // 初始化分布式数据对象
  private initDistributedObject(): void {
    try {
      // 创建分布式数据对象
      this.distributedObject = distributedObject.createDataObject(this.sessionId, {
        deviceName: '',
        message: '',
        timestamp: 0,
        deviceId: ''
      });

      if (this.distributedObject) {
        // 监听数据变化
        this.distributedObject.on('change', (sessionId: string, fields: string[]) => {
          this.handleDataChange(sessionId, fields);
        });

        // 监听状态变化
        this.distributedObject.on('status', (sessionId: string, deviceId: string, status: string) => {
          this.handleStatusChange(sessionId, deviceId, status);
        });

        hilog.info(DOMAIN, TAG, 'Distributed object initialized');
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to init distributed object: %{public}s', JSON.stringify(err));
    }
  }

  // 设置流转状态变化回调
  setOnHopStateChanged(callback: HopStateCallback): void {
    this.onHopStateChanged = callback;
  }

  // 准备流转数据
  prepareHopData(deviceName: string, message: string, deviceId: string): void {
    this.currentData = {
      deviceName: deviceName,
      message: message,
      timestamp: Date.now(),
      deviceId: deviceId
    };

    this.updateHopState('preparing', '准备流转数据');
    hilog.info(DOMAIN, TAG, 'Hop data prepared: %{public}s', deviceName);
  }

  // 执行流转到目标设备
  async hopToDevice(targetDevice: DistributedDevice): Promise<boolean> {
    if (!this.distributedObject || !this.currentData) {
      hilog.error(DOMAIN, TAG, 'Distributed object or data not ready');
      this.updateHopState('failed', '流转失败：数据未准备');
      return false;
    }

    try {
      this.updateHopState('hopping', '正在流转到 ' + targetDevice.deviceName);

      // 更新分布式数据对象
      this.distributedObject.put('deviceName', this.currentData.deviceName);
      this.distributedObject.put('message', this.currentData.message);
      this.distributedObject.put('timestamp', this.currentData.timestamp);
      this.distributedObject.put('deviceId', this.currentData.deviceId);

      // 保存数据到分布式对象
      await this.distributedObject.save(targetDevice.networkId);

      this.updateHopState('completed', '流转成功');
      hilog.info(DOMAIN, TAG, 'Hopped to device: %{public}s', targetDevice.deviceName);
      
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to hop: %{public}s', JSON.stringify(err));
      this.updateHopState('failed', '流转失败');
      return false;
    }
  }

  // 处理数据变化
  private handleDataChange(sessionId: string, fields: string[]): void {
    if (!this.distributedObject) {
      return;
    }

    hilog.info(DOMAIN, TAG, 'Data changed, fields: %{public}s', fields.join(','));

    // 读取流转过来的数据
    const deviceName = this.distributedObject.get('deviceName') as string;
    const message = this.distributedObject.get('message') as string;
    const timestamp = this.distributedObject.get('timestamp') as number;
    const deviceId = this.distributedObject.get('deviceId') as string;

    if (deviceName && message) {
      this.currentData = {
        deviceName: deviceName,
        message: message,
        timestamp: timestamp,
        deviceId: deviceId
      };

      this.updateHopState('completed', '接收到流转数据');
      hilog.info(DOMAIN, TAG, 'Received hop data: %{public}s', deviceName);
    }
  }

  // 处理状态变化
  private handleStatusChange(sessionId: string, deviceId: string, status: string): void {
    hilog.info(DOMAIN, TAG, 'Status changed: %{public}s, device: %{public}s', status, deviceId);
    
    if (status === 'online') {
      this.updateHopState('completed', '目标设备已上线');
    } else if (status === 'offline') {
      this.updateHopState('failed', '目标设备已离线');
    }
  }

  // 更新流转状态
  private updateHopState(state: HopState, message: string): void {
    this.hopState = state;
    
    if (this.onHopStateChanged) {
      this.onHopStateChanged(state, message);
    }
  }

  // 获取当前流转状态
  getHopState(): HopState {
    return this.hopState;
  }

  // 获取当前流转数据
  getCurrentData(): HopData | null {
    return this.currentData;
  }

  // 恢复流转数据（用于接收端）
  restoreHopData(): HopData | null {
    if (!this.distributedObject) {
      return null;
    }

    const deviceName = this.distributedObject.get('deviceName') as string;
    const message = this.distributedObject.get('message') as string;
    const timestamp = this.distributedObject.get('timestamp') as number;
    const deviceId = this.distributedObject.get('deviceId') as string;

    if (deviceName && message) {
      return {
        deviceName: deviceName,
        message: message,
        timestamp: timestamp,
        deviceId: deviceId
      };
    }

    return null;
  }

  // 清理资源
  cleanup(): void {
    if (this.distributedObject) {
      try {
        this.distributedObject.off('change');
        this.distributedObject.off('status');
        
        hilog.info(DOMAIN, TAG, 'Distributed object cleanup completed');
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'Failed to cleanup: %{public}s', JSON.stringify(err));
      }
    }

    this.onHopStateChanged = null;
    this.currentData = null;
    this.hopState = 'idle';
  }
}
