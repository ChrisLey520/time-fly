export interface PomodoroConfig {
  focusMinutes: number;
  shortBreakMinutes: number;
  longBreakMinutes: number;
  roundsBeforeLongBreak: number;
  notificationEnabled: boolean;
  vibrationEnabled: boolean;
  soundEnabled: boolean;
}

export const defaultPomodoroConfig: PomodoroConfig = {
  focusMinutes: 25,
  shortBreakMinutes: 5,
  longBreakMinutes: 15,
  roundsBeforeLongBreak: 4,
  notificationEnabled: true,
  vibrationEnabled: true,
  soundEnabled: true
};
