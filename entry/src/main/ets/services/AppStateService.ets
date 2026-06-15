export class AppStateService {
  private static selectedTabIndex: number = 0;

  static getSelectedTabIndex(): number {
    return AppStateService.selectedTabIndex;
  }

  static setSelectedTabIndex(index: number): void {
    AppStateService.selectedTabIndex = index;
  }
}
