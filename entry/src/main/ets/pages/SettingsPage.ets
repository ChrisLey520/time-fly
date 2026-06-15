import promptAction from '@ohos.promptAction';
import { PomodoroConfig } from '../models/PomodoroConfig';
import { StorageService } from '../services/StorageService';

@Component
export struct SettingsPage {
  @State config: PomodoroConfig = {
    focusMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    roundsBeforeLongBreak: 4,
    notificationEnabled: true,
    vibrationEnabled: true,
    soundEnabled: true
  };

  aboutToAppear(): void {
    this.loadConfig();
  }

  private async loadConfig(): Promise<void> {
    this.config = await StorageService.getConfig();
  }

  private async saveConfig(config: PomodoroConfig): Promise<void> {
    this.config = config;
    await StorageService.saveConfig(config);
  }

  private createConfig(
    focusMinutes: number,
    shortBreakMinutes: number,
    longBreakMinutes: number,
    roundsBeforeLongBreak: number,
    notificationEnabled: boolean,
    vibrationEnabled: boolean,
    soundEnabled: boolean
  ): PomodoroConfig {
    return {
      focusMinutes,
      shortBreakMinutes,
      longBreakMinutes,
      roundsBeforeLongBreak,
      notificationEnabled,
      vibrationEnabled,
      soundEnabled
    };
  }

  private async changeFocusMinutes(delta: number): Promise<void> {
    const nextMinutes = Math.min(120, Math.max(1, this.config.focusMinutes + delta));
    await this.saveConfig(this.createConfig(
      nextMinutes,
      this.config.shortBreakMinutes,
      this.config.longBreakMinutes,
      this.config.roundsBeforeLongBreak,
      this.config.notificationEnabled,
      this.config.vibrationEnabled,
      this.config.soundEnabled
    ));
  }

  private async changeShortBreakMinutes(delta: number): Promise<void> {
    const nextMinutes = Math.min(60, Math.max(1, this.config.shortBreakMinutes + delta));
    await this.saveConfig(this.createConfig(
      this.config.focusMinutes,
      nextMinutes,
      this.config.longBreakMinutes,
      this.config.roundsBeforeLongBreak,
      this.config.notificationEnabled,
      this.config.vibrationEnabled,
      this.config.soundEnabled
    ));
  }

  private async changeLongBreakMinutes(delta: number): Promise<void> {
    const nextMinutes = Math.min(120, Math.max(1, this.config.longBreakMinutes + delta));
    await this.saveConfig(this.createConfig(
      this.config.focusMinutes,
      this.config.shortBreakMinutes,
      nextMinutes,
      this.config.roundsBeforeLongBreak,
      this.config.notificationEnabled,
      this.config.vibrationEnabled,
      this.config.soundEnabled
    ));
  }

  private async changeRoundsBeforeLongBreak(delta: number): Promise<void> {
    const nextRounds = Math.min(12, Math.max(2, this.config.roundsBeforeLongBreak + delta));
    await this.saveConfig(this.createConfig(
      this.config.focusMinutes,
      this.config.shortBreakMinutes,
      this.config.longBreakMinutes,
      nextRounds,
      this.config.notificationEnabled,
      this.config.vibrationEnabled,
      this.config.soundEnabled
    ));
  }

  private async toggleNotification(isOn: boolean): Promise<void> {
    await this.saveConfig(this.createConfig(
      this.config.focusMinutes,
      this.config.shortBreakMinutes,
      this.config.longBreakMinutes,
      this.config.roundsBeforeLongBreak,
      isOn,
      this.config.vibrationEnabled,
      this.config.soundEnabled
    ));
  }

  private async toggleVibration(isOn: boolean): Promise<void> {
    await this.saveConfig(this.createConfig(
      this.config.focusMinutes,
      this.config.shortBreakMinutes,
      this.config.longBreakMinutes,
      this.config.roundsBeforeLongBreak,
      this.config.notificationEnabled,
      isOn,
      this.config.soundEnabled
    ));
  }

  private async toggleSound(isOn: boolean): Promise<void> {
    await this.saveConfig(this.createConfig(
      this.config.focusMinutes,
      this.config.shortBreakMinutes,
      this.config.longBreakMinutes,
      this.config.roundsBeforeLongBreak,
      this.config.notificationEnabled,
      this.config.vibrationEnabled,
      isOn
    ));
  }

  private async clearAll(): Promise<void> {
    const result = await promptAction.showDialog({
      title: '清除本地数据？',
      message: '任务、记录和当前计时状态都会被清除。',
      buttons: [
        {
          text: '取消',
          color: '#5F9E8A'
        },
        {
          text: '清除',
          color: '#C96F5D'
        }
      ]
    });

    if (result.index === 1) {
      await StorageService.clearAll();
      await this.loadConfig();
      promptAction.showToast({ message: '已清除' });
    }
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Text('设置')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2A2A')
          .width('100%');

        Column({ space: 16 }) {
          Text('专注节奏')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F2A2A')
            .width('100%');

          Row() {
            Text('专注时长')
              .fontSize(15)
              .fontColor('#1F2A2A')
              .layoutWeight(1);
            Button('-')
              .width(36)
              .height(36)
              .fontSize(20)
              .fontColor('#1F2A2A')
              .backgroundColor('#DDE8EA')
              .borderRadius(18)
              .onClick(() => {
                this.changeFocusMinutes(-5);
              });
            Text(`${this.config.focusMinutes} 分钟`)
              .fontSize(15)
              .fontColor('#1F2A2A')
              .width(86)
              .textAlign(TextAlign.Center);
            Button('+')
              .width(36)
              .height(36)
              .fontSize(20)
              .fontColor('#FFFFFF')
              .backgroundColor('#5F9E8A')
              .borderRadius(18)
              .onClick(() => {
                this.changeFocusMinutes(5);
              });
          }
          .width('100%');

          Row() {
            Text('短歇息')
              .fontSize(15)
              .fontColor('#1F2A2A')
              .layoutWeight(1);
            Button('-')
              .width(36)
              .height(36)
              .fontSize(20)
              .fontColor('#1F2A2A')
              .backgroundColor('#DDE8EA')
              .borderRadius(18)
              .onClick(() => {
                this.changeShortBreakMinutes(-1);
              });
            Text(`${this.config.shortBreakMinutes} 分钟`)
              .fontSize(15)
              .fontColor('#1F2A2A')
              .width(86)
              .textAlign(TextAlign.Center);
            Button('+')
              .width(36)
              .height(36)
              .fontSize(20)
              .fontColor('#FFFFFF')
              .backgroundColor('#5F9E8A')
              .borderRadius(18)
              .onClick(() => {
                this.changeShortBreakMinutes(1);
              });
          }
          .width('100%');

          Row() {
            Text('长歇息')
              .fontSize(15)
              .fontColor('#1F2A2A')
              .layoutWeight(1);
            Button('-')
              .width(36)
              .height(36)
              .fontSize(20)
              .fontColor('#1F2A2A')
              .backgroundColor('#DDE8EA')
              .borderRadius(18)
              .onClick(() => {
                this.changeLongBreakMinutes(-5);
              });
            Text(`${this.config.longBreakMinutes} 分钟`)
              .fontSize(15)
              .fontColor('#1F2A2A')
              .width(86)
              .textAlign(TextAlign.Center);
            Button('+')
              .width(36)
              .height(36)
              .fontSize(20)
              .fontColor('#FFFFFF')
              .backgroundColor('#5F9E8A')
              .borderRadius(18)
              .onClick(() => {
                this.changeLongBreakMinutes(5);
              });
          }
          .width('100%');

          Row() {
            Text('长歇息间隔')
              .fontSize(15)
              .fontColor('#1F2A2A')
              .layoutWeight(1);
            Button('-')
              .width(36)
              .height(36)
              .fontSize(20)
              .fontColor('#1F2A2A')
              .backgroundColor('#DDE8EA')
              .borderRadius(18)
              .onClick(() => {
                this.changeRoundsBeforeLongBreak(-1);
              });
            Text(`${this.config.roundsBeforeLongBreak} 次`)
              .fontSize(15)
              .fontColor('#1F2A2A')
              .width(86)
              .textAlign(TextAlign.Center);
            Button('+')
              .width(36)
              .height(36)
              .fontSize(20)
              .fontColor('#FFFFFF')
              .backgroundColor('#5F9E8A')
              .borderRadius(18)
              .onClick(() => {
                this.changeRoundsBeforeLongBreak(1);
              });
          }
          .width('100%');
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .border({
          width: 1,
          color: '#DDE8EA'
        });

        Column({ space: 12 }) {
          Text('提醒')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F2A2A')
            .width('100%');

          Row() {
            Text('专注结束提醒')
              .fontSize(15)
              .fontColor('#1F2A2A')
              .layoutWeight(1);
            Toggle({ type: ToggleType.Switch, isOn: this.config.notificationEnabled })
              .selectedColor('#5F9E8A')
              .onChange((isOn: boolean) => {
                this.toggleNotification(isOn);
              });
          }
          .width('100%');

          Row() {
            Text('震动提醒')
              .fontSize(15)
              .fontColor('#1F2A2A')
              .layoutWeight(1);
            Toggle({ type: ToggleType.Switch, isOn: this.config.vibrationEnabled })
              .selectedColor('#5F9E8A')
              .onChange((isOn: boolean) => {
                this.toggleVibration(isOn);
              });
          }
          .width('100%');

          Row() {
            Text('提示音')
              .fontSize(15)
              .fontColor('#1F2A2A')
              .layoutWeight(1);
            Toggle({ type: ToggleType.Switch, isOn: this.config.soundEnabled })
              .selectedColor('#5F9E8A')
              .onChange((isOn: boolean) => {
                this.toggleSound(isOn);
              });
          }
          .width('100%');
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .border({
          width: 1,
          color: '#DDE8EA'
        });

        Button('清除本地数据')
          .height(50)
          .width('100%')
          .fontSize(16)
          .fontColor('#C96F5D')
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .border({
            width: 1,
            color: '#E8D3CE'
          })
          .onClick(() => {
            this.clearAll();
          });
      }
      .width('100%')
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F8F7');
  }
}
