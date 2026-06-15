export function formatSeconds(totalSeconds: number): string {
  const safeSeconds = Math.max(0, Math.floor(totalSeconds));
  const minutes = Math.floor(safeSeconds / 60);
  const seconds = safeSeconds % 60;
  const minuteText = minutes < 10 ? `0${minutes}` : `${minutes}`;
  const secondText = seconds < 10 ? `0${seconds}` : `${seconds}`;

  return `${minuteText}:${secondText}`;
}

export function formatDuration(totalSeconds: number): string {
  const safeSeconds = Math.max(0, Math.floor(totalSeconds));
  const hours = Math.floor(safeSeconds / 3600);
  const minutes = Math.floor((safeSeconds % 3600) / 60);
  const seconds = safeSeconds % 60;

  if (hours > 0) {
    return `${hours}小时${minutes}分`;
  }

  if (minutes > 0) {
    return `${minutes}分${seconds}秒`;
  }

  return `${seconds}秒`;
}

export function formatClockTime(timestamp: number): string {
  const date = new Date(timestamp);
  const hours = date.getHours();
  const minutes = date.getMinutes();
  const hourText = hours < 10 ? `0${hours}` : `${hours}`;
  const minuteText = minutes < 10 ? `0${minutes}` : `${minutes}`;

  return `${hourText}:${minuteText}`;
}
