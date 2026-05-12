import { BluetoothManager, DeviceInfo } from '../utils/BluetoothManager';
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
  
  private bluetoothManager: BluetoothManager = new BluetoothManager();

  aboutToAppear() {
    hilog.info(DOMAIN, TAG, 'Index page aboutToAppear');
    this.initBluetooth();
  }

  aboutToDisappear() {
    hilog.info(DOMAIN, TAG, 'Index page aboutToDisappear');
    this.bluetoothManager.cleanup();
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
}
