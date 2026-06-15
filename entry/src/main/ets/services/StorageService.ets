import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { FocusSession } from '../models/FocusSession';
import { defaultPomodoroConfig, PomodoroConfig } from '../models/PomodoroConfig';
import { Task } from '../models/Task';
import { idleTimerState, TimerMode, TimerState } from '../models/TimerState';

const PREFERENCES_NAME = 'qishi_preferences';

interface StorageKeys {
  config: string;
  timerState: string;
  sessions: string;
  tasks: string;
  progress: string;
  widgetFormIds: string;
  scheduledReminder: string;
}

const STORAGE_KEYS: StorageKeys = {
  config: 'qishi.config',
  timerState: 'qishi.timerState',
  sessions: 'qishi.sessions',
  tasks: 'qishi.tasks',
  progress: 'qishi.progress',
  widgetFormIds: 'qishi.widgetFormIds',
  scheduledReminder: 'qishi.scheduledReminder'
};

export interface PomodoroProgress {
  completedFocusRounds: number;
}

export interface WidgetFormIds {
  ids: string[];
}

export interface ScheduledReminderState {
  reminderId: number;
  timerId: string;
  expectedEndAt: number;
  mode: TimerMode;
}

const defaultPomodoroProgress: PomodoroProgress = {
  completedFocusRounds: 0
};

const defaultWidgetFormIds: WidgetFormIds = {
  ids: []
};

const defaultScheduledReminderState: ScheduledReminderState = {
  reminderId: -1,
  timerId: '',
  expectedEndAt: 0,
  mode: 'focus'
};

function cloneWidgetFormIds(formIds: WidgetFormIds): WidgetFormIds {
  return {
    ids: formIds.ids.slice()
  };
}

function cloneScheduledReminderState(state: ScheduledReminderState): ScheduledReminderState {
  return {
    reminderId: state.reminderId,
    timerId: state.timerId,
    expectedEndAt: state.expectedEndAt,
    mode: state.mode
  };
}

function normalizeConfig(config: PomodoroConfig): PomodoroConfig {
  return {
    focusMinutes: config.focusMinutes ? config.focusMinutes : defaultPomodoroConfig.focusMinutes,
    shortBreakMinutes: config.shortBreakMinutes ? config.shortBreakMinutes : defaultPomodoroConfig.shortBreakMinutes,
    longBreakMinutes: config.longBreakMinutes ? config.longBreakMinutes : defaultPomodoroConfig.longBreakMinutes,
    roundsBeforeLongBreak: config.roundsBeforeLongBreak
      ? config.roundsBeforeLongBreak
      : defaultPomodoroConfig.roundsBeforeLongBreak,
    dailyGoalMinutes: config.dailyGoalMinutes ? config.dailyGoalMinutes : defaultPomodoroConfig.dailyGoalMinutes,
    notificationEnabled: config.notificationEnabled === false ? false : defaultPomodoroConfig.notificationEnabled,
    vibrationEnabled: config.vibrationEnabled === false ? false : defaultPomodoroConfig.vibrationEnabled,
    soundEnabled: config.soundEnabled === false ? false : defaultPomodoroConfig.soundEnabled
  };
}

export class StorageService {
  private static preferences?: dataPreferences.Preferences;

  static async init(context: common.Context): Promise<void> {
    if (StorageService.preferences) {
      return;
    }

    try {
      StorageService.preferences = await dataPreferences.getPreferences(context, PREFERENCES_NAME);
    } catch (error) {
      throw new Error('StorageService failed to initialize preferences.');
    }
  }

  private static getPreferences(): dataPreferences.Preferences {
    if (!StorageService.preferences) {
      throw new Error('StorageService.init(context) must be called before using storage.');
    }

    return StorageService.preferences;
  }

  private static readJson<T>(key: string, fallback: T): T {
    const preferences = StorageService.getPreferences();
    let rawValue = '';

    try {
      rawValue = preferences.getSync(key, '') as string;
    } catch (error) {
      return fallback;
    }

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
    try {
      preferences.putSync(key, JSON.stringify(value));
      await preferences.flush();
    } catch (error) {
      // Persisting user state should fail softly; callers can continue using in-memory state.
    }
  }

  static async getConfig(): Promise<PomodoroConfig> {
    return normalizeConfig(StorageService.readJson<PomodoroConfig>(STORAGE_KEYS.config, defaultPomodoroConfig));
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

  static async getWidgetFormIds(): Promise<WidgetFormIds> {
    const formIds = StorageService.readJson<WidgetFormIds>(STORAGE_KEYS.widgetFormIds, defaultWidgetFormIds);
    return cloneWidgetFormIds(formIds);
  }

  static async saveWidgetFormIds(formIds: WidgetFormIds): Promise<void> {
    await StorageService.writeJson<WidgetFormIds>(STORAGE_KEYS.widgetFormIds, cloneWidgetFormIds(formIds));
  }

  static async getScheduledReminder(): Promise<ScheduledReminderState> {
    const reminder = StorageService.readJson<ScheduledReminderState>(
      STORAGE_KEYS.scheduledReminder,
      defaultScheduledReminderState
    );
    return cloneScheduledReminderState(reminder);
  }

  static async saveScheduledReminder(reminder: ScheduledReminderState): Promise<void> {
    await StorageService.writeJson<ScheduledReminderState>(
      STORAGE_KEYS.scheduledReminder,
      cloneScheduledReminderState(reminder)
    );
  }

  static async clearScheduledReminder(): Promise<void> {
    await StorageService.saveScheduledReminder(defaultScheduledReminderState);
  }

  static async clearAll(): Promise<void> {
    const preferences = StorageService.getPreferences();
    const widgetFormIds = await StorageService.getWidgetFormIds();
    try {
      preferences.clearSync();
      await preferences.flush();
    } catch (error) {
      // Keep the app usable even if the preference backend is temporarily unavailable.
    }
    await StorageService.saveWidgetFormIds(widgetFormIds);
  }
}
