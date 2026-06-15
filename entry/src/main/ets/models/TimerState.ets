export type TimerMode = 'focus' | 'break';
export type TimerStatus = 'idle' | 'running' | 'paused';

export interface TimerState {
  id: string;
  mode: TimerMode;
  status: TimerStatus;
  taskId?: string;
  taskTitle?: string;
  startedAt?: number;
  pausedAt?: number;
  expectedEndAt?: number;
  durationSeconds: number;
  accumulatedPausedMs: number;
}

export const idleTimerState: TimerState = {
  id: '',
  mode: 'focus',
  status: 'idle',
  durationSeconds: 0,
  accumulatedPausedMs: 0
};
