import distributedDataObject from '@ohos.data.distributedDataObject';
import hilog from '@ohos.hilog';

const TAG = 'DataSyncManager';
const DOMAIN = 0x0000;

// 同步数据类型
export interface SyncData {
  // 用户输入的角色内容
  deviceName: string;
  // 游戏ID
  message: string;
  // 时间戳
  timestamp: number;
  // 设备ID
  sourceDeviceId: string;
  // 应用状态
  appState: 'idle' | 'advertising' | 'scanning' | 'connected';
  // 选中的设备ID
  selectedDeviceId: string;
}

// 数据变化回调
export type DataChangeCallback = (data: SyncData) => void;

// 数据同步管理器
export class DataSyncManager {
  private distributedObject: distributedDataObject.DataObject | null = null;
  private sessionId: string = 'ArkTentacle_DataSync';
  private onDataChange: DataChangeCallback | null = null;
  private currentData: SyncData;

  constructor() {
    hilog.info(DOMAIN, TAG, 'DataSyncManager created');
    
    // 初始化默认数据
    this.currentData = {
      deviceName: '',
      message: '',
      timestamp: Date.now(),
      sourceDeviceId: '',
      appState: 'idle',
      selectedDeviceId: ''
    };

    this.initDistributedObject();
  }

  // 初始化分布式数据对象
  private initDistributedObject(): void {
    try {
      // 创建分布式数据对象
      this.distributedObject = distributedDataObject.createDataObject(this.sessionId, {
        deviceName: '',
        message: '',
        timestamp: 0,
        sourceDeviceId: '',
        appState: 'idle',
        selectedDeviceId: ''
      });

      if (this.distributedObject) {
        // 监听数据变化
        this.distributedObject.on('change', (sessionId: string, fields: string[]) => {
          this.handleDataChange(sessionId, fields);
        });

        hilog.info(DOMAIN, TAG, 'Distributed object initialized');
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to init distributed object: %{public}s', JSON.stringify(err));
    }
  }

  // 设置数据变化回调
  setOnDataChange(callback: DataChangeCallback): void {
    this.onDataChange = callback;
  }

  // 更新本地数据
  updateLocalData(data: Partial<SyncData>): void {
    this.currentData = {
      ...this.currentData,
      ...data,
      timestamp: Date.now()
    };

    // 同步到分布式对象
    this.syncToDistributedObject();
  }

  // 同步数据到分布式对象
  private syncToDistributedObject(): void {
    if (!this.distributedObject) {
      return;
    }

    try {
      this.distributedObject.put('deviceName', this.currentData.deviceName);
      this.distributedObject.put('message', this.currentData.message);
      this.distributedObject.put('timestamp', this.currentData.timestamp);
      this.distributedObject.put('sourceDeviceId', this.currentData.sourceDeviceId);
      this.distributedObject.put('appState', this.currentData.appState);
      this.distributedObject.put('selectedDeviceId', this.currentData.selectedDeviceId);

      hilog.info(DOMAIN, TAG, 'Data synced to distributed object');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to sync data: %{public}s', JSON.stringify(err));
    }
  }

  // 处理数据变化
  private handleDataChange(sessionId: string, fields: string[]): void {
    if (!this.distributedObject) {
      return;
    }

    hilog.info(DOMAIN, TAG, 'Data changed, fields: %{public}s', fields.join(','));

    // 读取同步过来的数据
    const deviceName = this.distributedObject.get('deviceName') as string;
    const message = this.distributedObject.get('message') as string;
    const timestamp = this.distributedObject.get('timestamp') as number;
    const sourceDeviceId = this.distributedObject.get('sourceDeviceId') as string;
    const appState = this.distributedObject.get('appState') as 'idle' | 'advertising' | 'scanning' | 'connected';
    const selectedDeviceId = this.distributedObject.get('selectedDeviceId') as string;

    // 更新当前数据
    this.currentData = {
      deviceName: deviceName,
      message: message,
      timestamp: timestamp,
      sourceDeviceId: sourceDeviceId,
      appState: appState,
      selectedDeviceId: selectedDeviceId
    };

    // 通知回调
    if (this.onDataChange) {
      this.onDataChange(this.currentData);
    }
  }

  // 保存数据到指定设备
  async saveToDevice(networkId: string): Promise<boolean> {
    if (!this.distributedObject) {
      return false;
    }

    try {
      await this.distributedObject.save(networkId);
      hilog.info(DOMAIN, TAG, 'Data saved to device: %{public}s', networkId);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to save data: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  // 获取当前数据
  getCurrentData(): SyncData {
    return this.currentData;
  }

  // 恢复数据（用于接收端）
  restoreData(): SyncData | null {
    if (!this.distributedObject) {
      return null;
    }

    const deviceName = this.distributedObject.get('deviceName') as string;
    const message = this.distributedObject.get('message') as string;
    const timestamp = this.distributedObject.get('timestamp') as number;
    const sourceDeviceId = this.distributedObject.get('sourceDeviceId') as string;
    const appState = this.distributedObject.get('appState') as 'idle' | 'advertising' | 'scanning' | 'connected';
    const selectedDeviceId = this.distributedObject.get('selectedDeviceId') as string;

    return {
      deviceName: deviceName,
      message: message,
      timestamp: timestamp,
      sourceDeviceId: sourceDeviceId,
      appState: appState,
      selectedDeviceId: selectedDeviceId
    };
  }

  // 清理资源
  cleanup(): void {
    if (this.distributedObject) {
      try {
        this.distributedObject.off('change');
        hilog.info(DOMAIN, TAG, 'Distributed object cleanup completed');
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'Failed to cleanup: %{public}s', JSON.stringify(err));
      }
    }

    this.onDataChange = null;
  }
}
