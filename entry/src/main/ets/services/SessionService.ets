import { FocusSession } from '../models/FocusSession';
import { StorageService } from './StorageService';

export class SessionService {
  static async add(session: FocusSession): Promise<void> {
    await StorageService.addSession(session);
  }

  static async listAll(): Promise<FocusSession[]> {
    return StorageService.getSessions();
  }

  static async listRecent(limit: number = 3): Promise<FocusSession[]> {
    const sessions = await StorageService.getSessions();
    return sessions.slice(0, limit);
  }

  static async delete(sessionId: string): Promise<void> {
    await StorageService.deleteSession(sessionId);
  }

  static async clearAll(): Promise<void> {
    await StorageService.clearSessions();
  }
}
