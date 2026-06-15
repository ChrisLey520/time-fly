import { UIContext } from '@ohos.arkui.UIContext';

export interface DialogButton {
  text: string;
  color: string;
}

export interface DialogOptions {
  title: string;
  message: string;
  buttons: DialogButton[];
}

export interface DialogResult {
  index: number;
}

const dismissedDialogResult: DialogResult = {
  index: -1
};

export class PromptService {
  private static uiContext?: UIContext;

  static bindContext(uiContext: UIContext): void {
    PromptService.uiContext = uiContext;
  }

  static showToast(message: string): void {
    if (!PromptService.uiContext) {
      return;
    }

    try {
      PromptService.uiContext.getPromptAction().showToast({ message });
    } catch (error) {
      // Some previewer/emulator contexts reject transient prompts.
    }
  }

  static async showDialog(options: DialogOptions): Promise<DialogResult> {
    if (!PromptService.uiContext) {
      return dismissedDialogResult;
    }

    try {
      const result = await PromptService.uiContext.getPromptAction().showDialog({
          title: options.title,
          message: options.message,
          buttons: options.buttons
        });
      return {
        index: result.index
      };
    } catch (error) {
      return dismissedDialogResult;
    }
  }
}
