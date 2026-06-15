import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { FocusSession } from '../models/FocusSession';
import { defaultPomodoroConfig, PomodoroConfig } from '../models/PomodoroConfig';
import { Task } from '../models/Task';
import { idleTimerState, TimerState } from '../models/TimerState';

const PREFERENCES_NAME = 'qishi_preferences';

interface StorageKeys {
  config: string;
  timerState: string;
  sessions: string;
  tasks: string;
  progress: string;
}

const STORAGE_KEYS: StorageKeys = {
  config: 'qishi.config',
  timerState: 'qishi.timerState',
  sessions: 'qishi.sessions',
  tasks: 'qishi.tasks',
  progress: 'qishi.progress'
};

export interface PomodoroProgress {
  completedFocusRounds: number;
}

const defaultPomodoroProgress: PomodoroProgress = {
  completedFocusRounds: 0
};

export class StorageService {
  private static preferences?: dataPreferences.Preferences;

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (StorageService.preferences) {
      return;
    }

    StorageService.preferences = await dataPreferences.getPreferences(context, PREFERENCES_NAME);
  }

  private static getPreferences(): dataPreferences.Preferences {
    if (!StorageService.preferences) {
      throw new Error('StorageService.init(context) must be called before using storage.');
    }

    return StorageService.preferences;
  }

  private static readJson<T>(key: string, fallback: T): T {
    const preferences = StorageService.getPreferences();
    const rawValue = preferences.getSync(key, '') as string;

    if (!rawValue) {
      return fallback;
    }

    try {
      return JSON.parse(rawValue) as T;
    } catch (error) {
      return fallback;
    }
  }

  private static async writeJson<T>(key: string, value: T): Promise<void> {
    const preferences = StorageService.getPreferences();
    preferences.putSync(key, JSON.stringify(value));
    await preferences.flush();
  }

  static async getConfig(): Promise<PomodoroConfig> {
    return StorageService.readJson<PomodoroConfig>(STORAGE_KEYS.config, defaultPomodoroConfig);
  }

  static async saveConfig(config: PomodoroConfig): Promise<void> {
    await StorageService.writeJson<PomodoroConfig>(STORAGE_KEYS.config, config);
  }

  static async getTimerState(): Promise<TimerState> {
    return StorageService.readJson<TimerState>(STORAGE_KEYS.timerState, idleTimerState);
  }

  static async saveTimerState(state: TimerState): Promise<void> {
    await StorageService.writeJson<TimerState>(STORAGE_KEYS.timerState, state);
  }

  static async clearTimerState(): Promise<void> {
    await StorageService.saveTimerState(idleTimerState);
  }

  static async getSessions(): Promise<FocusSession[]> {
    return StorageService.readJson<FocusSession[]>(STORAGE_KEYS.sessions, []);
  }

  static async saveSessions(sessions: FocusSession[]): Promise<void> {
    await StorageService.writeJson<FocusSession[]>(STORAGE_KEYS.sessions, sessions);
  }

  static async addSession(session: FocusSession): Promise<void> {
    const sessions = await StorageService.getSessions();
    sessions.unshift(session);
    await StorageService.saveSessions(sessions);
  }

  static async getTasks(): Promise<Task[]> {
    return StorageService.readJson<Task[]>(STORAGE_KEYS.tasks, []);
  }

  static async saveTasks(tasks: Task[]): Promise<void> {
    await StorageService.writeJson<Task[]>(STORAGE_KEYS.tasks, tasks);
  }

  static async getProgress(): Promise<PomodoroProgress> {
    return StorageService.readJson<PomodoroProgress>(STORAGE_KEYS.progress, defaultPomodoroProgress);
  }

  static async saveProgress(progress: PomodoroProgress): Promise<void> {
    await StorageService.writeJson<PomodoroProgress>(STORAGE_KEYS.progress, progress);
  }

  static async clearAll(): Promise<void> {
    const preferences = StorageService.getPreferences();
    preferences.clearSync();
    await preferences.flush();
  }
}
