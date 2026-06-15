import notificationManager from '@ohos.notificationManager';
import notification from '@ohos.notification';
import common from '@ohos.app.ability.common';
import { PromptService } from './PromptService';
import { StorageService } from './StorageService';

export class NotificationService {
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
      await notificationManager.publish({
        id: Date.now() % 100000,
        content: {
          contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title,
            text
          }
        }
      });
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
      await notificationManager.publish({
        id: Date.now() % 100000,
        content: {
          contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title,
            text
          }
        }
      });
    } catch (error) {
      PromptService.showToast(title);
    }
  }
}
