import { BluetoothManager, DeviceInfo } from '../utils/BluetoothManager';
import { DistributedDeviceManager, DistributedDevice } from '../utils/DistributedDeviceManager';
import { HopManager, HopData, HopState } from '../utils/HopManager';
import hilog from '@ohos.hilog';

const TAG = 'Index';
const DOMAIN = 0x0000;

@Entry
@Component
struct Index {
  @State private isScanning: boolean = false;
  @State private devices: DeviceInfo[] = [];
  @State private bluetoothEnabled: boolean = false;
  @State private statusMessage: string = '';
  @State private deviceNameInput: string = '';
  @State private secretMessageInput: string = '';
  @State private isAdvertising: boolean = false;
  @State private selectedDevice: DeviceInfo | null = null;
  @State private sendStatus: string = '';
  
  // 分布式设备相关状态
  @State private distributedDevices: DistributedDevice[] = [];
  @State private isDiscovering: boolean = false;
  @State private selectedDistributedDevice: DistributedDevice | null = null;
  @State private hopState: HopState = 'idle';
  @State private hopMessage: string = '';
  @State private receivedHopData: HopData | null = null;
  @State private showDistributedPanel: boolean = false;
  
  private bluetoothManager: BluetoothManager = new BluetoothManager();
  private distributedDeviceManager: DistributedDeviceManager = new DistributedDeviceManager();
  private hopManager: HopManager = new HopManager();

  aboutToAppear() {
    hilog.info(DOMAIN, TAG, 'Index page aboutToAppear');
    this.initBluetooth();
    this.initDistributedDevice();
    this.initHopManager();
  }

  aboutToDisappear() {
    hilog.info(DOMAIN, TAG, 'Index page aboutToDisappear');
    this.bluetoothManager.cleanup();
    this.distributedDeviceManager.cleanup();
    this.hopManager.cleanup();
  }

  private async initBluetooth() {
    // 设置回调
    this.bluetoothManager.setOnDeviceFound((devices: DeviceInfo[]) => {
      this.devices = devices;
    });

    this.bluetoothManager.setOnScanStateChanged((isScanning: boolean) => {
      this.isScanning = isScanning;
      if (isScanning) {
        this.statusMessage = '正在扫描...';
      } else {
        this.statusMessage = '';
      }
    });

    // 检查蓝牙状态
    this.bluetoothEnabled = await this.bluetoothManager.isBluetoothEnabled();
    if (!this.bluetoothEnabled) {
      this.statusMessage = '蓝牙未开启';
    }
  }

  private async handleScanButton() {
    if (this.isScanning) {
      await this.bluetoothManager.stopScan();
    } else {
      if (!this.bluetoothEnabled) {
        const enabled = await this.bluetoothManager.enableBluetooth();
        if (enabled) {
          this.bluetoothEnabled = true;
          await this.bluetoothManager.startScan();
        } else {
          this.statusMessage = '无法开启蓝牙';
        }
      } else {
        await this.bluetoothManager.startScan();
      }
    }
  }

  // 处理广播按钮
  private async handleAdvertiseButton() {
    if (!this.deviceNameInput) {
      this.statusMessage = '请输入喜爱的角色内容';
      return;
    }

    if (this.isAdvertising) {
      await this.bluetoothManager.stopAdvertising();
      this.isAdvertising = false;
      this.statusMessage = '已停止广播';
    } else {
      if (!this.bluetoothEnabled) {
        const enabled = await this.bluetoothManager.enableBluetooth();
        if (!enabled) {
          this.statusMessage = '无法开启蓝牙';
          return;
        }
        this.bluetoothEnabled = true;
      }

      const success = await this.bluetoothManager.startAdvertising(
        'ArkTentacle',
        this.deviceNameInput
      );
      
      if (success) {
        this.isAdvertising = true;
        this.statusMessage = '正在广播: ' + this.deviceNameInput;
      } else {
        this.statusMessage = '广播启动失败';
      }
    }
  }

  // 处理发送按钮
  private async handleSendButton() {
    if (!this.secretMessageInput) {
      this.sendStatus = '请输入游戏ID';
      return;
    }

    if (!this.selectedDevice) {
      this.sendStatus = '请先选择目标设备';
      return;
    }

    // 发送数据到选中的设备
    const success = await this.bluetoothManager.sendDataToDevice(
      this.selectedDevice.deviceId,
      this.secretMessageInput
    );

    if (success) {
      this.sendStatus = '已发送: ' + this.secretMessageInput + ' 到 ' + this.selectedDevice.deviceName;
    } else {
      this.sendStatus = '发送失败';
    }
  }

  // 初始化分布式设备管理器
  private initDistributedDevice() {
    this.distributedDeviceManager.setOnDeviceFound((devices: DistributedDevice[]) => {
      this.distributedDevices = devices;
    });

    this.distributedDeviceManager.setOnDeviceStateChanged((device: DistributedDevice, state: 'online' | 'offline') => {
      if (state === 'online') {
        this.hopMessage = '设备上线: ' + device.deviceName;
      } else {
        this.hopMessage = '设备离线: ' + device.deviceName;
      }
    });
  }

  // 初始化流转管理器
  private initHopManager() {
    this.hopManager.setOnHopStateChanged((state: HopState, message: string) => {
      this.hopState = state;
      this.hopMessage = message;

      // 如果接收到流转数据，更新UI
      if (state === 'completed') {
        const data = this.hopManager.restoreHopData();
        if (data) {
          this.receivedHopData = data;
          this.deviceNameInput = data.deviceName;
          this.secretMessageInput = data.message;
        }
      }
    });
  }

  // 处理分布式设备发现按钮
  private async handleDiscoverButton() {
    if (this.isDiscovering) {
      await this.distributedDeviceManager.stopDeviceDiscovery();
      this.isDiscovering = false;
    } else {
      const success = await this.distributedDeviceManager.startDeviceDiscovery();
      if (success) {
        this.isDiscovering = true;
        this.hopMessage = '正在发现分布式设备...';
      } else {
        this.hopMessage = '发现设备失败';
      }
    }
  }

  // 处理一键流转按钮
  private async handleHopButton() {
    if (!this.selectedDistributedDevice) {
      this.hopMessage = '请先选择目标设备';
      return;
    }

    if (!this.deviceNameInput && !this.secretMessageInput) {
      this.hopMessage = '请输入要流转的内容';
      return;
    }

    // 准备流转数据
    this.hopManager.prepareHopData(
      this.deviceNameInput,
      this.secretMessageInput,
      'current_device_id'
    );

    // 执行流转
    const success = await this.hopManager.hopToDevice(this.selectedDistributedDevice);
    
    if (success) {
      this.hopMessage = '流转成功！';
    } else {
      this.hopMessage = '流转失败';
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('ArkTentacle-粥批触须')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_color'))
      }
      .width('100%')
      .height(60)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.background_color'))

      // 状态信息
      Column() {
        // 蓝牙状态
        Row() {
          Text('蓝牙状态: ')
            .fontSize(16)
          Text(this.bluetoothEnabled ? '已开启' : '未开启')
            .fontSize(16)
            .fontColor(this.bluetoothEnabled ? '#00AA00' : '#FF0000')
        }
        .margin({ top: 20, bottom: 10 })

        // 扫描状态
        if (this.statusMessage !== '') {
          Text(this.statusMessage)
            .fontSize(16)
            .fontColor('#007DFF')
            .margin({ bottom: 10 })
        }

        // 设备数量
        Row() {
          Text($r('app.string.device_count'))
            .fontSize(16)
          Text(': ')
            .fontSize(16)
          Text(this.devices.length.toString())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#007DFF')
        }
        .margin({ bottom: 20 })

        // 可见内容输入框（设备名）
        TextInput({ placeholder: '可以输入喜爱的角色等内容', text: this.deviceNameInput })
          .width('100%')
          .height(45)
          .fontSize(16)
          .placeholderColor('#999999')
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onChange((value: string) => {
            this.deviceNameInput = value;
          })
          .margin({ bottom: 15 })

        // 待发送内容输入框（密信）
        TextInput({ placeholder: '请输入游戏ID', text: this.secretMessageInput })
          .width('100%')
          .height(45)
          .fontSize(16)
          .placeholderColor('#999999')
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onChange((value: string) => {
            this.secretMessageInput = value;
          })
          .margin({ bottom: 20 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      // 扫描按钮
      Button(this.isScanning ? $r('app.string.stop_button') : $r('app.string.scan_button'))
        .width('80%')
        .height(50)
        .fontSize(18)
        .backgroundColor(this.isScanning ? '#FF5555' : '#007DFF')
        .onClick(() => {
          this.handleScanButton();
        })
        .margin({ bottom: 10 })

      // 广播按钮
      Button(this.isAdvertising ? '停止广播' : '开始广播')
        .width('80%')
        .height(50)
        .fontSize(18)
        .backgroundColor(this.isAdvertising ? '#FF5555' : '#00AA00')
        .onClick(() => {
          this.handleAdvertiseButton();
        })
        .margin({ bottom: 10 })

      // 发送按钮
      Button('发送游戏ID')
        .width('80%')
        .height(50)
        .fontSize(18)
        .backgroundColor('#FF9900')
        .onClick(() => {
          this.handleSendButton();
        })
        .margin({ bottom: 10 })

      // 分隔线
      Divider()
        .width('80%')
        .height(2)
        .color('#E0E0E0')
        .margin({ top: 10, bottom: 10 })

      // 多端流转区域标题
      Row() {
        Text('多端流转')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_color'))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 10, bottom: 10 })

      // 流转状态提示
      if (this.hopMessage !== '') {
        Row() {
          Text('流转状态: ')
            .fontSize(14)
          Text(this.hopMessage)
            .fontSize(14)
            .fontColor(this.getHopStateColor())
        }
        .margin({ bottom: 10 })
      }

      // 接收到的流转数据显示
      if (this.receivedHopData !== null) {
        Column() {
          Text('接收到流转数据:')
            .fontSize(14)
            .fontColor('#007DFF')
            .margin({ bottom: 5 })
          Text('角色: ' + this.receivedHopData.deviceName)
            .fontSize(14)
          Text('游戏ID: ' + this.receivedHopData.message)
            .fontSize(14)
        }
        .width('80%')
        .padding(10)
        .backgroundColor('#E3F2FD')
        .borderRadius(8)
        .margin({ bottom: 10 })
      }

      // 发现分布式设备按钮
      Button(this.isDiscovering ? '停止发现' : '发现分布式设备')
        .width('80%')
        .height(50)
        .fontSize(18)
        .backgroundColor(this.isDiscovering ? '#FF5555' : '#9C27B0')
        .onClick(() => {
          this.handleDiscoverButton();
        })
        .margin({ bottom: 10 })

      // 一键流转按钮
      Button('一键流转')
        .width('80%')
        .height(50)
        .fontSize(18)
        .backgroundColor('#E91E63')
        .onClick(() => {
          this.handleHopButton();
        })
        .margin({ bottom: 10 })

      // 分布式设备列表
      if (this.distributedDevices.length > 0) {
        Text('可流转设备列表:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 10, bottom: 5 })

        List() {
          ForEach(this.distributedDevices, (device: DistributedDevice) => {
            ListItem() {
              this.DistributedDeviceItem(device)
            }
          }, (device: DistributedDevice) => device.deviceId)
        }
        .width('100%')
        .height(180)
        .padding({ left: 20, right: 20 })
      }

      // 发送状态提示
      if (this.sendStatus !== '') {
        Text(this.sendStatus)
          .fontSize(14)
          .fontColor('#FF9900')
          .margin({ bottom: 10 })
      }

      // 设备列表
      if (this.devices.length > 0) {
        List() {
          ForEach(this.devices, (device: DeviceInfo) => {
            ListItem() {
              this.DeviceItem(device)
            }
          }, (device: DeviceInfo) => device.deviceId)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 20, right: 20 })
      } else {
        // 空状态
        Column() {
          Text($r('app.string.no_devices'))
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 50 })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  DeviceItem(device: DeviceInfo) {
    Row() {
      Column() {
        Text(device.deviceName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_color'))
        
        Text('ID: ' + device.deviceId)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        Text('RSSI: ' + device.rssi + ' dBm')
          .fontSize(14)
          .fontColor(this.getRssiColor(device.rssi))
        
        // 显示选中状态
        if (this.selectedDevice && this.selectedDevice.deviceId === device.deviceId) {
          Text('已选中')
            .fontSize(12)
            .fontColor('#007DFF')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(15)
    .margin({ top: 10 })
    .borderRadius(8)
    .backgroundColor(this.selectedDevice && this.selectedDevice.deviceId === device.deviceId ? '#E3F2FD' : '#F5F5F5')
    .onClick(() => {
      // 点击选择设备
      this.selectedDevice = device;
      this.sendStatus = '已选择设备: ' + device.deviceName;
    })
  }

  private getRssiColor(rssi: number): string {
    if (rssi > -60) {
      return '#00AA00'; // 信号强 - 绿色
    } else if (rssi > -80) {
      return '#FFAA00'; // 信号中等 - 黄色
    } else {
      return '#FF0000'; // 信号弱 - 红色
    }
  }

  // 分布式设备列表项
  @Builder
  DistributedDeviceItem(device: DistributedDevice) {
    Row() {
      Column() {
        Text(device.deviceName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_color'))
        
        Row() {
          Text('类型: ' + device.deviceType)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ right: 10 })
          
          Text('状态: ' + device.deviceState)
            .fontSize(12)
            .fontColor(device.deviceState === 'online' ? '#00AA00' : '#FF0000')
        }
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        // 显示选中状态
        if (this.selectedDistributedDevice && this.selectedDistributedDevice.deviceId === device.deviceId) {
          Text('已选中')
            .fontSize(12)
            .fontColor('#E91E63')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(15)
    .margin({ top: 10 })
    .borderRadius(8)
    .backgroundColor(this.selectedDistributedDevice && this.selectedDistributedDevice.deviceId === device.deviceId ? '#FCE4EC' : '#F5F5F5')
    .onClick(() => {
      // 点击选择设备
      this.selectedDistributedDevice = device;
      this.hopMessage = '已选择设备: ' + device.deviceName;
    })
  }

  // 获取流转状态颜色
  private getHopStateColor(): string {
    switch (this.hopState) {
      case 'idle':
        return '#999999';
      case 'preparing':
        return '#FFAA00';
      case 'hopping':
        return '#007DFF';
      case 'completed':
        return '#00AA00';
      case 'failed':
        return '#FF0000';
      default:
        return '#999999';
    }
  }
}
