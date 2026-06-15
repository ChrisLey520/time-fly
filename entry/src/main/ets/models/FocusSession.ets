export type FocusSessionStatus = 'completed' | 'abandoned';

export interface FocusSession {
  id: string;
  taskId?: string;
  taskTitle?: string;
  plannedDurationSeconds: number;
  actualDurationSeconds: number;
  startedAt: number;
  endedAt: number;
  status: FocusSessionStatus;
}
