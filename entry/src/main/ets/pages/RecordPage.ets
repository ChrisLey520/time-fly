import { FocusSession } from '../models/FocusSession';
import { SessionService } from '../services/SessionService';
import { StatsService } from '../services/StatsService';
import { formatClockTime, formatDuration } from '../utils/dateTime';

@Component
export struct RecordPage {
  @State sessions: FocusSession[] = [];
  @State todaySeconds: number = 0;
  @State completedFocusCount: number = 0;
  @State completedTaskCount: number = 0;
  private ticker: number = -1;

  aboutToAppear(): void {
    this.loadSessions();
    this.startTicker();
  }

  aboutToDisappear(): void {
    this.stopTicker();
  }

  private startTicker(): void {
    this.stopTicker();
    this.ticker = setInterval(() => {
      this.loadSessions();
    }, 1000);
  }

  private stopTicker(): void {
    if (this.ticker !== -1) {
      clearInterval(this.ticker);
      this.ticker = -1;
    }
  }

  private async loadSessions(): Promise<void> {
    const sessions = await SessionService.listAll();
    const stats = await StatsService.getTodayStats();

    this.sessions = sessions;
    this.todaySeconds = stats.focusSeconds;
    this.completedFocusCount = stats.completedFocusCount;
    this.completedTaskCount = stats.completedTaskCount;
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Text('记录')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2A2A')
          .width('100%');

        Column({ space: 8 }) {
          Text('今日已专注')
            .fontSize(14)
            .fontColor('#7B8785');
          Text(formatDuration(this.todaySeconds))
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2A2A');
          Text(`完成 ${this.completedFocusCount} 次专注 / ${this.completedTaskCount} 个任务`)
            .fontSize(13)
            .fontColor('#7B8785');
        }
        .width('100%')
        .padding(18)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .border({
          width: 1,
          color: '#DDE8EA'
        });

        Text(`共 ${this.sessions.length} 条记录`)
          .fontSize(15)
          .fontColor('#7B8785')
          .width('100%');

        if (this.sessions.length === 0) {
          Text('完成一段专注后，记录会出现在这里。')
            .fontSize(14)
            .fontColor('#7B8785')
            .width('100%')
            .padding(18)
            .backgroundColor('#FFFFFF')
            .borderRadius(18)
            .border({
              width: 1,
              color: '#DDE8EA'
            });
        } else {
          ForEach(this.sessions, (session: FocusSession) => {
            Row() {
              Column({ space: 6 }) {
                Text(session.taskTitle ? session.taskTitle : '自由专注')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1F2A2A');
                Text(`${formatClockTime(session.startedAt)} - ${formatClockTime(session.endedAt)}`)
                  .fontSize(12)
                  .fontColor('#7B8785');
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1);

              Column({ space: 6 }) {
                Text(session.status === 'completed' ? '已完成' : '已结束')
                  .fontSize(13)
                  .fontColor(session.status === 'completed' ? '#5F9E8A' : '#C96F5D');
                Text(formatDuration(session.actualDurationSeconds))
                  .fontSize(12)
                  .fontColor('#7B8785');
                Text(`计划 ${formatDuration(session.plannedDurationSeconds)}`)
                  .fontSize(11)
                  .fontColor('#9AA6A3');
              }
              .alignItems(HorizontalAlign.End);
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(18)
            .border({
              width: 1,
              color: '#DDE8EA'
            });
          }, (session: FocusSession) => session.id);
        }
      }
      .width('100%')
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F8F7');
  }
}
