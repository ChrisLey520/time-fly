import { TimerState } from '../models/TimerState';
import { StatsService } from './StatsService';
import { StorageService } from './StorageService';
import { TimerService } from './TimerService';

export interface WidgetSnapshot {
  todayFocusSeconds: number;
  currentTaskTitle: string;
  timerStatus: string;
  remainingSeconds: number;
  updatedAt: number;
}

export class WidgetService {
  static async getSnapshot(): Promise<WidgetSnapshot> {
    const stats = await StatsService.getTodayStats();
    const state: TimerState = await StorageService.getTimerState();
    const remainingSeconds = await TimerService.getRemainingSeconds();

    return {
      todayFocusSeconds: stats.focusSeconds,
      currentTaskTitle: state.taskTitle ? state.taskTitle : '自由专注',
      timerStatus: state.status,
      remainingSeconds,
      updatedAt: Date.now()
    };
  }
}
