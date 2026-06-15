import { Task } from '../models/Task';
import { createId } from '../utils/id';
import { StorageService } from './StorageService';

export class TaskService {
  static async listAll(): Promise<Task[]> {
    return StorageService.getTasks();
  }

  static async listActive(): Promise<Task[]> {
    const tasks = await StorageService.getTasks();
    return tasks.filter((task: Task) => task.status === 'active');
  }

  static async add(title: string, estimatedFocusCount: number = 1): Promise<Task | null> {
    const trimmedTitle = title.trim();
    if (!trimmedTitle) {
      return null;
    }

    const task: Task = {
      id: createId('task'),
      title: trimmedTitle,
      estimatedFocusCount: Math.max(1, estimatedFocusCount),
      completedFocusCount: 0,
      status: 'active',
      createdAt: Date.now()
    };
    const tasks = await StorageService.getTasks();
    tasks.unshift(task);
    await StorageService.saveTasks(tasks);

    return task;
  }

  static async update(taskId: string, title: string, estimatedFocusCount: number): Promise<Task | null> {
    const tasks = await StorageService.getTasks();
    const index = tasks.findIndex((task: Task) => task.id === taskId);
    if (index < 0) {
      return null;
    }

    tasks[index].title = title.trim() || tasks[index].title;
    tasks[index].estimatedFocusCount = Math.max(1, estimatedFocusCount);
    await StorageService.saveTasks(tasks);

    return tasks[index];
  }

  static async delete(taskId: string): Promise<void> {
    const tasks = await StorageService.getTasks();
    await StorageService.saveTasks(tasks.filter((task: Task) => task.id !== taskId));
  }

  static async markCompleted(taskId: string): Promise<Task | null> {
    const tasks = await StorageService.getTasks();
    const task = tasks.find((item: Task) => item.id === taskId);
    if (!task) {
      return null;
    }

    task.status = 'completed';
    task.completedAt = Date.now();
    await StorageService.saveTasks(tasks);

    return task;
  }

  static async incrementCompletedFocusCount(taskId?: string): Promise<Task | null> {
    if (!taskId) {
      return null;
    }

    const tasks = await StorageService.getTasks();
    const task = tasks.find((item: Task) => item.id === taskId);
    if (!task) {
      return null;
    }

    task.completedFocusCount += 1;
    if (task.completedFocusCount >= task.estimatedFocusCount) {
      task.status = 'completed';
      task.completedAt = Date.now();
    }

    await StorageService.saveTasks(tasks);
    return task;
  }
}
