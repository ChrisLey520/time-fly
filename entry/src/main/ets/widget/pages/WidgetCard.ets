@Entry
@Component
struct WidgetCard {
  @LocalStorageProp('brandName') brandName: string = '栖时';
  @LocalStorageProp('headline') headline: string = '准备专注';
  @LocalStorageProp('detail') detail: string = '轻轻开始一段新的时间';
  @LocalStorageProp('taskTitle') taskTitle: string = '自由专注';
  @LocalStorageProp('remainingText') remainingText: string = '--:--';
  @LocalStorageProp('todayText') todayText: string = '今日 0 分钟';
  @LocalStorageProp('statusText') statusText: string = '空闲';

  build() {
    FormLink({
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        source: 'widget'
      }
    }) {
      Column({ space: 10 }) {
        Row() {
          Text(this.brandName)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2A2A')
            .layoutWeight(1);

          Text(this.statusText)
            .fontSize(12)
            .fontColor('#5F9E8A')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor('#EAF3F0')
            .borderRadius(12);
        }
        .width('100%');

        Text(this.headline)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2A2A')
          .width('100%');

        Text(this.detail)
          .fontSize(13)
          .fontColor('#7B8785')
          .width('100%');

        Row() {
          Column({ space: 4 }) {
            Text(this.remainingText)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F2A2A');
            Text(this.taskTitle)
              .fontSize(12)
              .fontColor('#7B8785')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Text(this.todayText)
            .fontSize(12)
            .fontColor('#7B8785');
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom);
      }
      .width('100%')
      .height('100%')
      .padding(16)
      .backgroundColor('#FFFFFF');
    }
  }
}
