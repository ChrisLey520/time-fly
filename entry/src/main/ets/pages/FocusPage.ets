import promptAction from '@ohos.promptAction';
import { PrimaryButton } from '../components/PrimaryButton';
import { SessionPreviewList } from '../components/SessionPreviewList';
import { TimerDisplay } from '../components/TimerDisplay';
import { FocusSession } from '../models/FocusSession';
import { idleTimerState, TimerState } from '../models/TimerState';
import { Task } from '../models/Task';
import { SessionService } from '../services/SessionService';
import { TaskService } from '../services/TaskService';
import { TimerService } from '../services/TimerService';
import { StatsService, TodayStats } from '../services/StatsService';
import { PomodoroProgressService } from '../services/PomodoroProgressService';

@Component
export struct FocusPage {
  @State timerState: TimerState = idleTimerState;
  @State remainingSeconds: number = 0;
  @State recentSessions: FocusSession[] = [];
  @State activeTasks: Task[] = [];
  @State selectedTaskIndex: number = -1;
  @State todayStats: TodayStats = {
    focusSeconds: 0,
    completedFocusCount: 0,
    completedTaskCount: 0
  };
  @State completedFocusRounds: number = 0;
  private ticker: number = -1;

  aboutToAppear(): void {
    this.restoreTimer();
    this.startTicker();
  }

  aboutToDisappear(): void {
    this.stopTicker();
  }

  private async restoreTimer(): Promise<void> {
    this.timerState = await TimerService.restore();
    this.remainingSeconds = await TimerService.getRemainingSeconds();
    this.recentSessions = await SessionService.listRecent(3);
    this.activeTasks = await TaskService.listActive();
    this.todayStats = await StatsService.getTodayStats();
    this.completedFocusRounds = await PomodoroProgressService.getCompletedFocusRounds();
  }

  private startTicker(): void {
    this.stopTicker();
    this.ticker = setInterval(async () => {
      await this.restoreTimer();
    }, 500);
  }

  private stopTicker(): void {
    if (this.ticker !== -1) {
      clearInterval(this.ticker);
      this.ticker = -1;
    }
  }

  private async onStart(): Promise<void> {
    const task = this.selectedTaskIndex >= 0 ? this.activeTasks[this.selectedTaskIndex] : undefined;
    this.timerState = await TimerService.startFocus(undefined, task?.id, task?.title || '自由专注');
    this.remainingSeconds = await TimerService.getRemainingSeconds();
    await this.restoreTimer();
  }

  private async onStartQuickTest(): Promise<void> {
    const task = this.selectedTaskIndex >= 0 ? this.activeTasks[this.selectedTaskIndex] : undefined;
    this.timerState = await TimerService.startFocus(10, task?.id, task?.title || '自由专注');
    this.remainingSeconds = await TimerService.getRemainingSeconds();
    await this.restoreTimer();
  }

  private async onStartBreak(): Promise<void> {
    this.timerState = await TimerService.startBreak();
    this.remainingSeconds = await TimerService.getRemainingSeconds();
    await this.restoreTimer();
  }

  private async onPause(): Promise<void> {
    this.timerState = await TimerService.pause();
    this.remainingSeconds = await TimerService.getRemainingSeconds();
    await this.restoreTimer();
  }

  private async onResume(): Promise<void> {
    this.timerState = await TimerService.resume();
    this.remainingSeconds = await TimerService.getRemainingSeconds();
    await this.restoreTimer();
  }

  private async onAbandon(): Promise<void> {
    const title = this.timerState.mode === 'break' ? '结束歇息？' : '结束本次专注？';
    const message = this.timerState.mode === 'break'
      ? '会回到空闲状态。'
      : '这段时间会记录为已结束，不计入今日专注总时长。';
    const result = await promptAction.showDialog({
      title,
      message,
      buttons: [
        {
          text: this.timerState.mode === 'break' ? '继续歇息' : '继续专注',
          color: '#5F9E8A'
        },
        {
          text: '结束本次',
          color: '#C96F5D'
        }
      ]
    });

    if (result.index === 1) {
      await TimerService.abandon();
      await this.restoreTimer();
    }
  }

  private statusText(): string {
    if (this.timerState.mode === 'break' && this.timerState.status === 'idle') {
      return '可以歇息了';
    }

    if (this.timerState.mode === 'break' && this.timerState.status === 'running') {
      return '歇息中';
    }

    if (this.timerState.status === 'running') {
      return '专注中';
    }

    if (this.timerState.status === 'paused') {
      return '已暂停';
    }

    return '准备安放一段时间';
  }

  private selectedTaskTitle(): string {
    if (this.timerState.mode === 'break') {
      return this.timerState.taskTitle ? this.timerState.taskTitle : '歇息';
    }

    if (this.timerState.status !== 'idle') {
      return this.timerState.taskTitle ? this.timerState.taskTitle : '自由专注';
    }

    if (this.selectedTaskIndex >= 0 && this.activeTasks[this.selectedTaskIndex]) {
      return this.activeTasks[this.selectedTaskIndex].title;
    }

    return '自由专注';
  }

  private selectOptions(): Array<SelectOption> {
    const options: Array<SelectOption> = [{ value: '自由专注' }];
    this.activeTasks.forEach((task: Task) => {
      options.push({ value: task.title });
    });

    return options;
  }

  private breakDescription(): string {
    const minutes = Math.floor(this.remainingSeconds / 60);
    const seconds = this.remainingSeconds % 60;
    if (minutes > 0 && seconds === 0) {
      return `${minutes} 分钟`;
    }

    return `${minutes} 分 ${seconds} 秒`;
  }

  build() {
    Scroll() {
      Column({ space: 24 }) {
        Row() {
          Column({ space: 4 }) {
            Text('栖时')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F2A2A');
            Text('安放每一个专注时刻')
              .fontSize(14)
              .fontColor('#7B8785');
            Text(`今日 ${Math.floor(this.todayStats.focusSeconds / 60)} 分钟 / ${this.todayStats.completedFocusCount} 次`)
              .fontSize(13)
              .fontColor('#7B8785');
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Text(this.statusText())
            .fontSize(13)
            .fontColor('#5F9E8A')
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .backgroundColor('#EAF3F0')
            .borderRadius(14);
        }
        .width('100%');

        Column({ space: 20 }) {
          Text(this.selectedTaskTitle())
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F2A2A');

          if (this.timerState.status === 'idle' && this.timerState.mode === 'focus') {
            Column({ space: 8 }) {
              Text('选择任务')
                .fontSize(13)
                .fontColor('#7B8785')
                .width('100%');

              if (this.activeTasks.length === 0) {
                Text('当前没有任务，会开始一段自由专注。')
                  .fontSize(14)
                  .fontColor('#7B8785')
                  .width('100%')
                  .padding(12)
                  .backgroundColor('#F6F8F7')
                  .borderRadius(12);
              } else {
                Select(this.selectOptions())
                  .selected(this.selectedTaskIndex + 1)
                  .value(this.selectedTaskTitle())
                  .font({ size: 15 })
                  .fontColor('#1F2A2A')
                  .selectedOptionFont({ size: 15 })
                  .optionFont({ size: 15 })
                  .onSelect((index: number) => {
                    this.selectedTaskIndex = index - 1;
                  })
                  .width('100%')
                  .height(44)
                  .backgroundColor('#F6F8F7')
                  .borderRadius(12);
              }
            }
            .width('100%');
          }

          TimerDisplay({ remainingSeconds: this.remainingSeconds });

          if (this.timerState.status === 'idle' && this.timerState.mode === 'focus') {
            Column({ space: 10 }) {
              PrimaryButton({
                title: '开始专注',
                buttonEnabled: true,
                onTap: () => {
                  this.onStart();
                }
              });

              Button('快速验证 10 秒')
                .height(44)
                .width('100%')
                .fontSize(15)
                .fontColor('#5F9E8A')
                .backgroundColor('#FFFFFF')
                .borderRadius(14)
                .border({
                  width: 1,
                  color: '#DDE8EA'
                })
                .onClick(() => {
                  this.onStartQuickTest();
                });
            }
            .width('100%');
          } else if (this.timerState.status === 'idle' && this.timerState.mode === 'break') {
            Column({ space: 6 }) {
              Text('已完成一段专注')
                .fontSize(17)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1F2A2A')
                .width('100%')
                .textAlign(TextAlign.Center);

              Text(`第 ${this.completedFocusRounds} 次专注已安放，建议${this.selectedTaskTitle()} ${this.breakDescription()}`)
                .fontSize(14)
                .fontColor('#7B8785')
                .width('100%')
                .textAlign(TextAlign.Center);
            }
              .width('100%')
              .padding({ bottom: 4 });

            Row({ space: 12 }) {
              Button('开始歇息')
                .height(52)
                .layoutWeight(1)
                .fontSize(16)
                .fontColor('#FFFFFF')
                .backgroundColor('#5F9E8A')
                .borderRadius(16)
                .onClick(() => {
                  this.onStartBreak();
                });

              Button('跳过')
                .height(52)
                .layoutWeight(1)
                .fontSize(16)
                .fontColor('#1F2A2A')
                .backgroundColor('#DDE8EA')
                .borderRadius(16)
                .onClick(() => {
                  TimerService.clearTimer().then(() => {
                    this.restoreTimer();
                  });
                });
            }
            .width('100%');
          } else if (this.timerState.status === 'running') {
            Row({ space: 12 }) {
              Button('暂停')
                .height(52)
                .layoutWeight(1)
                .fontSize(16)
                .fontColor('#1F2A2A')
                .backgroundColor('#DDE8EA')
                .borderRadius(16)
                .onClick(() => {
                  this.onPause();
                });

              Button('结束本次')
                .height(52)
                .layoutWeight(1)
                .fontSize(16)
                .fontColor('#FFFFFF')
                .backgroundColor('#C96F5D')
                .borderRadius(16)
                .onClick(() => {
                  this.onAbandon();
                });
            }
            .width('100%');
          } else {
            Row({ space: 12 }) {
              Button('继续')
                .height(52)
                .layoutWeight(1)
                .fontSize(16)
                .fontColor('#FFFFFF')
                .backgroundColor('#5F9E8A')
                .borderRadius(16)
                .onClick(() => {
                  this.onResume();
                });

              Button('结束本次')
                .height(52)
                .layoutWeight(1)
                .fontSize(16)
                .fontColor('#FFFFFF')
                .backgroundColor('#C96F5D')
                .borderRadius(16)
                .onClick(() => {
                  this.onAbandon();
                });
            }
            .width('100%');
          }

        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .border({
          width: 1,
          color: '#DDE8EA'
        });

        SessionPreviewList({ sessions: this.recentSessions });
      }
      .width('100%')
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F8F7');
  }
}
