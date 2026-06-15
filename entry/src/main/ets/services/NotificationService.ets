import notificationManager from '@ohos.notificationManager';
import common from '@ohos.app.ability.common';
import { PromptService } from './PromptService';
import { StorageService } from './StorageService';

interface NotificationTextPayload {
  title: string;
  text: string;
}

export class NotificationService {
  private static notificationId(): number {
    return Date.now() % 100000;
  }

  private static createTextRequest(payload: NotificationTextPayload): notificationManager.NotificationRequest {
    return {
      id: NotificationService.notificationId(),
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: payload.title,
          text: payload.text
        }
      }
    };
  }

  static async requestEnable(context: common.UIAbilityContext): Promise<void> {
    try {
      const enabled = await notificationManager.isNotificationEnabled();
      if (!enabled) {
        await notificationManager.requestEnableNotification(context);
      }
    } catch (error) {
      // The user may deny permission or the emulator may not support the prompt.
    }
  }

  static async notifyFocusCompleted(durationMinutes: number): Promise<void> {
    const config = await StorageService.getConfig();
    if (!config.notificationEnabled) {
      return;
    }

    const title = '一段专注已完成';
    const text = `${durationMinutes} 分钟被好好安放了`;

    try {
      await notificationManager.publish(NotificationService.createTextRequest({ title, text }));
    } catch (error) {
      PromptService.showToast(title);
    }
  }

  static async notifyBreakCompleted(): Promise<void> {
    const config = await StorageService.getConfig();
    if (!config.notificationEnabled) {
      return;
    }

    const title = '可以回来了';
    const text = '歇息结束，继续你的节奏';

    try {
      await notificationManager.publish(NotificationService.createTextRequest({ title, text }));
    } catch (error) {
      PromptService.showToast(title);
    }
  }
}
