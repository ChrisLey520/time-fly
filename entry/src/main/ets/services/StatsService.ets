import { FocusSession } from '../models/FocusSession';
import { Task } from '../models/Task';
import { SessionService } from './SessionService';
import { TaskService } from './TaskService';

export interface TodayStats {
  focusSeconds: number;
  completedFocusCount: number;
  completedTaskCount: number;
}

function startOfTodayMs(): number {
  const date = new Date();
  date.setHours(0, 0, 0, 0);
  return date.getTime();
}

export class StatsService {
  static async getTodayStats(): Promise<TodayStats> {
    const sessions = await SessionService.listAll();
    const tasks = await TaskService.listAll();
    const todayStart = startOfTodayMs();
    const completedSessions = sessions.filter((session: FocusSession) => {
      return session.status === 'completed' && session.endedAt >= todayStart;
    });

    return {
      focusSeconds: completedSessions.reduce((sum: number, session: FocusSession) => {
        return sum + session.actualDurationSeconds;
      }, 0),
      completedFocusCount: completedSessions.length,
      completedTaskCount: tasks.filter((task: Task) => {
        return task.status === 'completed' && !!task.completedAt && task.completedAt >= todayStart;
      }).length
    };
  }
}
