import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formInfo from '@ohos.app.form.formInfo';
import Want from '@ohos.app.ability.Want';
import { StorageService } from '../services/StorageService';
import { WidgetService } from '../services/WidgetService';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = this.getFormId(want);
    this.initAndRefresh(formId);
    return WidgetService.createBindingData(WidgetService.defaultCardData());
  }

  onUpdateForm(formId: string): void {
    this.initAndRefresh(formId);
  }

  onRemoveForm(formId: string): void {
    StorageService.init(this.context).then(async () => {
      await WidgetService.removeFormId(formId);
    });
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }

  private initAndRefresh(formId: string): void {
    StorageService.init(this.context).then(async () => {
      await WidgetService.addFormId(formId);
      await WidgetService.refreshForm(formId);
    });
  }

  private getFormId(want: Want): string {
    if (!want.parameters) {
      return '';
    }

    const formId = want.parameters[formInfo.FormParam.IDENTITY_KEY];
    return formId ? formId.toString() : '';
  }
}
