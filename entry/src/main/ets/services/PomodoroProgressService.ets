import { StorageService, PomodoroProgress } from './StorageService';

export class PomodoroProgressService {
  static async getCompletedFocusRounds(): Promise<number> {
    const progress = await StorageService.getProgress();
    return progress.completedFocusRounds;
  }

  static async incrementFocusRounds(): Promise<number> {
    const progress = await StorageService.getProgress();
    const nextProgress: PomodoroProgress = {
      completedFocusRounds: progress.completedFocusRounds + 1
    };

    await StorageService.saveProgress(nextProgress);
    return nextProgress.completedFocusRounds;
  }

  static async reset(): Promise<void> {
    const nextProgress: PomodoroProgress = {
      completedFocusRounds: 0
    };

    await StorageService.saveProgress(nextProgress);
  }
}
