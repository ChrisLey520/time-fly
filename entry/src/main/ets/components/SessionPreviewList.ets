import { FocusSession } from '../models/FocusSession';
import { formatClockTime, formatDuration } from '../utils/dateTime';

@Component
export struct SessionPreviewList {
  @Prop sessions: FocusSession[];

  build() {
    Column({ space: 10 }) {
      Row() {
        Text('最近记录')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2A2A');
      }
      .width('100%');

      if (this.sessions.length === 0) {
        Text('还没有记录。先安放一小段时间。')
          .fontSize(14)
          .fontColor('#7B8785')
          .width('100%')
          .padding({ top: 8, bottom: 8 });
      } else {
        ForEach(this.sessions, (session: FocusSession) => {
          Row() {
            Column({ space: 4 }) {
              Text(session.taskTitle ? session.taskTitle : '自由专注')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1F2A2A');
              Text(`${formatClockTime(session.startedAt)} - ${formatClockTime(session.endedAt)}`)
                .fontSize(12)
                .fontColor('#7B8785');
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1);

            Column({ space: 4 }) {
              Text(session.status === 'completed' ? '已完成' : '已结束')
                .fontSize(13)
                .fontColor(session.status === 'completed' ? '#5F9E8A' : '#C96F5D');
              Text(formatDuration(session.actualDurationSeconds))
                .fontSize(12)
                .fontColor('#7B8785');
            }
            .alignItems(HorizontalAlign.End);
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .border({
            width: 1,
            color: '#DDE8EA'
          });
        }, (session: FocusSession) => session.id);
      }
    }
    .width('100%');
  }
}
