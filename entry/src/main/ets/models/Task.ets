export type TaskStatus = 'active' | 'completed' | 'archived';

export interface Task {
  id: string;
  title: string;
  estimatedFocusCount: number;
  completedFocusCount: number;
  status: TaskStatus;
  createdAt: number;
  completedAt?: number;
}
