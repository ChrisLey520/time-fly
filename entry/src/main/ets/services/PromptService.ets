import promptAction from '@ohos.promptAction';

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
  static showToast(message: string): void {
    try {
      promptAction.showToast({ message });
    } catch (error) {
      // Some previewer/emulator contexts reject transient prompts.
    }
  }

  static async showDialog(options: DialogOptions): Promise<DialogResult> {
    try {
      const result = await promptAction.showDialog({
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
