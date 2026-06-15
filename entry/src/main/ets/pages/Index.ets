import { FocusPage } from './FocusPage';
import { RecordPage } from './RecordPage';
import { SettingsPage } from './SettingsPage';
import { TaskPage } from './TaskPage';
import { AppStateService } from '../services/AppStateService';
import { PromptService } from '../services/PromptService';

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;
  private tabsController: TabsController = new TabsController();
  private ticker: number = -1;

  aboutToAppear(): void {
    PromptService.bindContext(this.getUIContext());
    this.startTicker();
  }

  aboutToDisappear(): void {
    this.stopTicker();
  }

  private startTicker(): void {
    this.stopTicker();
    this.ticker = setInterval(() => {
      const nextIndex = AppStateService.getSelectedTabIndex();
      if (this.selectedIndex !== nextIndex) {
        this.selectedIndex = nextIndex;
        this.tabsController.changeIndex(nextIndex);
      }
    }, 200);
  }

  private stopTicker(): void {
    if (this.ticker !== -1) {
      clearInterval(this.ticker);
      this.ticker = -1;
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.selectedIndex, controller: this.tabsController }) {
      TabContent() {
        FocusPage();
      }
      .tabBar('专注');

      TabContent() {
        TaskPage();
      }
      .tabBar('任务');

      TabContent() {
        RecordPage();
      }
      .tabBar('记录');

      TabContent() {
        SettingsPage();
      }
      .tabBar('设置');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F8F7')
    .barBackgroundColor('#FFFFFF')
    .barMode(BarMode.Fixed)
    .onChange((index: number) => {
      this.selectedIndex = index;
      AppStateService.setSelectedTabIndex(index);
    });
  }
}
