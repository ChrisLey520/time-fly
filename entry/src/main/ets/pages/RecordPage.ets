import { FocusSession } from '../models/FocusSession';
import { AppStateService } from '../services/AppStateService';
import { PromptService } from '../services/PromptService';
import { SessionService } from '../services/SessionService';
import { DayStats, GoalStats, StatsService, WeeklyStats } from '../services/StatsService';
import { WidgetService } from '../services/WidgetService';
import { formatClockTime, formatDuration } from '../utils/dateTime';

type RecordFilter = 'all' | 'completed' | 'abandoned';

const DAY_MS = 24 * 60 * 60 * 1000;

interface SessionDayGroup {
  startAt: number;
  title: string;
  detail: string;
  sessions: FocusSession[];
  focusSeconds: number;
  completedCount: number;
  abandonedCount: number;
}

@Component
export struct RecordPage {
  @State sessions: FocusSession[] = [];
  @State todaySeconds: number = 0;
  @State completedFocusCount: number = 0;
  @State completedTaskCount: number = 0;
  @State goalStats: GoalStats = {
    goalMinutes: 120,
    focusSeconds: 0,
    progressPercent: 0,
    remainingSeconds: 120 * 60,
    isCompleted: false
  };
  @State weeklyStats: WeeklyStats = {
    days: [],
    totalFocusSeconds: 0,
    totalCompletedFocusCount: 0,
    bestDayLabel: '--',
    bestDayFocusSeconds: 0,
    activeDayCount: 0
  };
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
    }, 10000);
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
    const goalStats = await StatsService.getGoalStats();
    const weeklyStats = await StatsService.getWeeklyStats();

    this.sessions = sessions;
    this.todaySeconds = stats.focusSeconds;
    this.completedFocusCount = stats.completedFocusCount;
    this.completedTaskCount = stats.completedTaskCount;
    this.goalStats = goalStats;
    this.weeklyStats = weeklyStats;
  }

  private filteredSessions(): FocusSession[] {
    if (this.selectedFilter === 'all') {
      const allSessions = this.sessions.slice();
      allSessions.sort((left: FocusSession, right: FocusSession) => right.endedAt - left.endedAt);
      return allSessions;
    }

    const sessions = this.sessions.filter((session: FocusSession) => session.status === this.selectedFilter);
    sessions.sort((left: FocusSession, right: FocusSession) => right.endedAt - left.endedAt);
    return sessions;
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

  private filterEmptyText(): string {
    if (this.sessions.length === 0) {
      return '完成一段专注后，记录会出现在这里。';
    }

    if (this.selectedFilter === 'completed') {
      return '还没有完成的专注记录。';
    }

    if (this.selectedFilter === 'abandoned') {
      return '当前没有已结束记录。';
    }

    return '当前筛选下没有记录。';
  }

  private goalProgressWidth(): string {
    return `${this.goalStats.progressPercent}%`;
  }

  private goalStatusText(): string {
    if (this.goalStats.isCompleted) {
      return '今日目标已完成';
    }

    return `还差 ${formatDuration(this.goalStats.remainingSeconds)}`;
  }

  private weeklyAverageText(): string {
    if (this.weeklyStats.activeDayCount === 0) {
      return '--';
    }

    return formatDuration(Math.floor(this.weeklyStats.totalFocusSeconds / this.weeklyStats.activeDayCount));
  }

  private dayBarHeight(day: DayStats): number {
    if (this.weeklyStats.bestDayFocusSeconds <= 0) {
      return 8;
    }

    return Math.max(8, Math.floor(day.focusSeconds * 56 / this.weeklyStats.bestDayFocusSeconds));
  }

  private dayBarColor(day: DayStats): string {
    return day.focusSeconds > 0 ? '#5F9E8A' : '#DDE8EA';
  }

  private sessionDayStartAt(timestamp: number): number {
    const date = new Date(timestamp);
    date.setHours(0, 0, 0, 0);
    return date.getTime();
  }

  private sessionDayTitle(startAt: number): string {
    const todayStart = this.sessionDayStartAt(Date.now());
    if (startAt === todayStart) {
      return '今天';
    }

    if (startAt === todayStart - DAY_MS) {
      return '昨天';
    }

    const date = new Date(startAt);
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }

  private sessionDayDetail(startAt: number): string {
    const date = new Date(startAt);
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`;
  }

  private sessionGroups(): SessionDayGroup[] {
    const sessions = this.filteredSessions();
    const groups: SessionDayGroup[] = [];

    sessions.forEach((session: FocusSession) => {
      const startAt = this.sessionDayStartAt(session.endedAt);
      let group = groups.find((item: SessionDayGroup) => item.startAt === startAt);
      if (!group) {
        group = {
          startAt,
          title: this.sessionDayTitle(startAt),
          detail: this.sessionDayDetail(startAt),
          sessions: [],
          focusSeconds: 0,
          completedCount: 0,
          abandonedCount: 0
        };
        groups.push(group);
      }

      group.sessions.push(session);
      if (session.status === 'completed') {
        group.completedCount += 1;
        group.focusSeconds += Math.max(0, Math.floor(session.actualDurationSeconds));
      } else {
        group.abandonedCount += 1;
      }
    });

    return groups;
  }

  private sessionTitle(session: FocusSession): string {
    return session.taskTitle ? session.taskTitle : '自由专注';
  }

  private sessionStatusText(session: FocusSession): string {
    return session.status === 'completed' ? '已完成' : '已结束';
  }

  private sessionStatusColor(session: FocusSession): string {
    return session.status === 'completed' ? '#5F9E8A' : '#C96F5D';
  }

  private sessionStatusBgColor(session: FocusSession): string {
    return session.status === 'completed' ? '#EAF3F0' : '#FFF0EC';
  }

  private sessionMetaText(session: FocusSession): string {
    return `${formatClockTime(session.startedAt)} - ${formatClockTime(session.endedAt)} · 计划 ${formatDuration(session.plannedDurationSeconds)}`;
  }

  private async deleteSession(session: FocusSession): Promise<void> {
    const result = await PromptService.showDialog({
      title: '删除这条记录？',
      message: `${this.sessionTitle(session)} · ${formatDuration(session.actualDurationSeconds)}`,
      buttons: [
        {
          text: '取消',
          color: '#5F9E8A'
        },
        {
          text: '删除',
          color: '#C96F5D'
        }
      ]
    });

    if (result.index === 1) {
      await SessionService.delete(session.id);
      await this.loadSessions();
      await WidgetService.refreshAllForms();
      PromptService.showToast('已删除记录');
    }
  }

  private async clearSessions(): Promise<void> {
    const result = await PromptService.showDialog({
      title: '清空全部记录？',
      message: `将删除 ${this.sessions.length} 条专注记录，任务本身会保留。`,
      buttons: [
        {
          text: '取消',
          color: '#5F9E8A'
        },
        {
          text: '清空',
          color: '#C96F5D'
        }
      ]
    });

    if (result.index === 1) {
      await SessionService.clearAll();
      await this.loadSessions();
      await WidgetService.refreshAllForms();
      PromptService.showToast('记录已清空');
    }
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Row() {
          Text('记录')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2A2A')
            .layoutWeight(1);

          if (this.sessions.length > 0) {
            Button('清空')
              .height(34)
              .fontSize(13)
              .fontColor('#C96F5D')
              .backgroundColor('#FFF0EC')
              .borderRadius(12)
              .onClick(() => {
                this.clearSessions();
              });
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center);

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

          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(8)
              .backgroundColor('#EEF3F2')
              .borderRadius(4);

            Row()
              .width(this.goalProgressWidth())
              .height(8)
              .backgroundColor(this.goalStats.isCompleted ? '#4D7EA8' : '#5F9E8A')
              .borderRadius(4);
          }
          .width('100%')
          .height(8)
          .padding({ top: 4 });

          Text(`${this.goalStatusText()} / 目标 ${this.goalStats.goalMinutes} 分钟`)
            .fontSize(12)
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

        Column({ space: 14 }) {
          Row() {
            Text('本周洞察')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2A2A')
              .layoutWeight(1);
            Text(`活跃 ${this.weeklyStats.activeDayCount}/7 天`)
              .fontSize(12)
              .fontColor('#7B8785');
          }
          .width('100%');

          Row({ space: 8 }) {
            Column({ space: 3 }) {
              Text(formatDuration(this.weeklyStats.totalFocusSeconds))
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1F2A2A');
              Text('本周总计')
                .fontSize(11)
                .fontColor('#7B8785');
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            Column({ space: 3 }) {
              Text(this.weeklyAverageText())
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#4D7EA8');
              Text('活跃日均')
                .fontSize(11)
                .fontColor('#7B8785');
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            Column({ space: 3 }) {
              Text(this.weeklyStats.bestDayLabel)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#5F9E8A');
              Text(`最佳 ${formatDuration(this.weeklyStats.bestDayFocusSeconds)}`)
                .fontSize(11)
                .fontColor('#7B8785');
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);
          }
          .width('100%');

          Row({ space: 8 }) {
            ForEach(this.weeklyStats.days, (day: DayStats) => {
              Column({ space: 6 }) {
                Stack({ alignContent: Alignment.Bottom }) {
                  Row()
                    .width('100%')
                    .height(64)
                    .backgroundColor('#F6F8F7')
                    .borderRadius(8);

                  Row()
                    .width('100%')
                    .height(this.dayBarHeight(day))
                    .backgroundColor(this.dayBarColor(day))
                    .borderRadius(8);
                }
                .width('100%')
                .height(64);

                Text(day.label)
                  .fontSize(10)
                  .fontColor('#7B8785')
                  .maxLines(1)
                  .textAlign(TextAlign.Center);
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center);
            }, (day: DayStats) => `${day.startAt}`);
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
          Column({ space: 12 }) {
            Text(this.sessions.length === 0 ? '暂无记录' : '没有匹配记录')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2A2A');
            Text(this.filterEmptyText())
              .fontSize(14)
              .fontColor('#7B8785')
              .textAlign(TextAlign.Center);

            Button(this.sessions.length === 0 ? '去专注' : '查看全部')
              .height(38)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#5F9E8A')
              .borderRadius(12)
              .onClick(() => {
                if (this.sessions.length === 0) {
                  AppStateService.setSelectedTabIndex(0);
                } else {
                  this.selectedFilter = 'all';
                }
              });
          }
            .width('100%')
            .padding(18)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor('#FFFFFF')
            .borderRadius(18)
            .border({
              width: 1,
              color: '#DDE8EA'
            });
        } else {
          ForEach(this.sessionGroups(), (group: SessionDayGroup) => {
            Column({ space: 12 }) {
              Row() {
                Column({ space: 3 }) {
                  Text(group.title)
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1F2A2A');
                  Text(group.detail)
                    .fontSize(11)
                    .fontColor('#7B8785');
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Column({ space: 3 }) {
                  Text(formatDuration(group.focusSeconds))
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#5F9E8A');
                  Text(`完成 ${group.completedCount} / 结束 ${group.abandonedCount}`)
                    .fontSize(11)
                    .fontColor('#7B8785');
                }
                .alignItems(HorizontalAlign.End);
              }
              .width('100%');

              ForEach(group.sessions, (session: FocusSession) => {
                Row({ space: 10 }) {
                  Column({ space: 6 }) {
                    Row({ space: 8 }) {
                      Text(this.sessionTitle(session))
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#1F2A2A')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1);

                      Text(this.sessionStatusText(session))
                        .fontSize(11)
                        .fontColor(this.sessionStatusColor(session))
                        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                        .backgroundColor(this.sessionStatusBgColor(session))
                        .borderRadius(10);
                    }
                    .width('100%');

                    Text(this.sessionMetaText(session))
                      .fontSize(12)
                      .fontColor('#7B8785')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis });
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1);

                  Column({ space: 6 }) {
                    Text(formatDuration(session.actualDurationSeconds))
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1F2A2A');

                    Button('删除')
                      .height(28)
                      .fontSize(12)
                      .fontColor('#C96F5D')
                      .backgroundColor('#FFF0EC')
                      .borderRadius(10)
                      .onClick(() => {
                        this.deleteSession(session);
                      });
                  }
                  .alignItems(HorizontalAlign.End);
                }
                .width('100%')
                .padding(14)
                .backgroundColor('#F6F8F7')
                .borderRadius(14);
              }, (session: FocusSession) => session.id);
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(18)
            .border({
              width: 1,
              color: '#DDE8EA'
            });
          }, (group: SessionDayGroup) => `${group.startAt}`);
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
