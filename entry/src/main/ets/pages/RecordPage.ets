import { FocusSession } from '../models/FocusSession';
import { SessionService } from '../services/SessionService';
import { StatsService } from '../services/StatsService';
import { formatClockTime, formatDuration } from '../utils/dateTime';

type RecordFilter = 'all' | 'completed' | 'abandoned';

@Component
export struct RecordPage {
  @State sessions: FocusSession[] = [];
  @State todaySeconds: number = 0;
  @State completedFocusCount: number = 0;
  @State completedTaskCount: number = 0;
  @State selectedFilter: RecordFilter = 'all';
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

  private filteredSessions(): FocusSession[] {
    if (this.selectedFilter === 'all') {
      return this.sessions;
    }

    return this.sessions.filter((session: FocusSession) => session.status === this.selectedFilter);
  }

  private completedSessions(): FocusSession[] {
    return this.sessions.filter((session: FocusSession) => session.status === 'completed');
  }

  private abandonedSessions(): FocusSession[] {
    return this.sessions.filter((session: FocusSession) => session.status === 'abandoned');
  }

  private completionRateText(): string {
    if (this.sessions.length === 0) {
      return '0%';
    }

    return `${Math.round(this.completedSessions().length * 100 / this.sessions.length)}%`;
  }

  private averageCompletedDurationText(): string {
    const completedSessions = this.completedSessions();
    if (completedSessions.length === 0) {
      return '--';
    }

    let totalSeconds = 0;
    completedSessions.forEach((session: FocusSession) => {
      totalSeconds += session.actualDurationSeconds;
    });

    return formatDuration(Math.round(totalSeconds / completedSessions.length));
  }

  private filterButtonColor(filter: RecordFilter): string {
    return this.selectedFilter === filter ? '#5F9E8A' : '#DDE8EA';
  }

  private filterButtonFontColor(filter: RecordFilter): string {
    return this.selectedFilter === filter ? '#FFFFFF' : '#1F2A2A';
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

          Row({ space: 8 }) {
            Column({ space: 3 }) {
              Text(this.completionRateText())
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#5F9E8A');
              Text('完成率')
                .fontSize(11)
                .fontColor('#7B8785');
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            Column({ space: 3 }) {
              Text(`${this.abandonedSessions().length}`)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#C96F5D');
              Text('已结束')
                .fontSize(11)
                .fontColor('#7B8785');
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            Column({ space: 3 }) {
              Text(this.averageCompletedDurationText())
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#4D7EA8');
              Text('平均时长')
                .fontSize(11)
                .fontColor('#7B8785');
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);
          }
          .width('100%')
          .padding({ top: 8 });
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

        Row({ space: 8 }) {
          Button(`全部 ${this.sessions.length}`)
            .height(36)
            .layoutWeight(1)
            .fontSize(13)
            .fontColor(this.filterButtonFontColor('all'))
            .backgroundColor(this.filterButtonColor('all'))
            .borderRadius(12)
            .onClick(() => {
              this.selectedFilter = 'all';
            });

          Button(`完成 ${this.completedSessions().length}`)
            .height(36)
            .layoutWeight(1)
            .fontSize(13)
            .fontColor(this.filterButtonFontColor('completed'))
            .backgroundColor(this.filterButtonColor('completed'))
            .borderRadius(12)
            .onClick(() => {
              this.selectedFilter = 'completed';
            });

          Button(`结束 ${this.abandonedSessions().length}`)
            .height(36)
            .layoutWeight(1)
            .fontSize(13)
            .fontColor(this.filterButtonFontColor('abandoned'))
            .backgroundColor(this.filterButtonColor('abandoned'))
            .borderRadius(12)
            .onClick(() => {
              this.selectedFilter = 'abandoned';
            });
        }
        .width('100%');

        if (this.filteredSessions().length === 0) {
          Text(this.sessions.length === 0 ? '完成一段专注后，记录会出现在这里。' : '当前筛选下没有记录。')
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
          ForEach(this.filteredSessions(), (session: FocusSession) => {
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
