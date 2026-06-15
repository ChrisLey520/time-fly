@Component
export struct PrimaryButton {
  @Prop title: string;
  @Prop buttonEnabled: boolean = true;
  onTap: () => void = () => {};

  build() {
    Button(this.title)
      .width('100%')
      .height(52)
      .fontSize(17)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.buttonEnabled ? '#FFFFFF' : '#7B8785')
      .backgroundColor(this.buttonEnabled ? '#5F9E8A' : '#DDE8EA')
      .borderRadius(16)
      .enabled(this.buttonEnabled)
      .onClick(() => {
        if (this.buttonEnabled) {
          this.onTap();
        }
      });
  }
}
