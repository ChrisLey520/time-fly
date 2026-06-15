import { formatSeconds } from '../utils/dateTime';

@Component
export struct TimerDisplay {
  @Prop remainingSeconds: number;

  build() {
    Text(formatSeconds(this.remainingSeconds))
      .fontSize(72)
      .fontWeight(FontWeight.Bold)
      .fontColor('#1F2A2A')
      .letterSpacing(0)
      .textAlign(TextAlign.Center)
      .width('100%');
  }
}
