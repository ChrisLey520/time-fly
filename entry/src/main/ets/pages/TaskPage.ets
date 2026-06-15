import { idleTimerState, TimerState } from '../models/TimerState';
import { Task } from '../models/Task';
import { AppStateService } from '../services/AppStateService';
import { PromptService } from '../services/PromptService';
import { TaskService } from '../services/TaskService';
import { TimerService } from '../services/TimerService';
import { WidgetService } from '../services/WidgetService';

type TaskFilter = 'active' | 'completed' | 'archived';

@Component
export struct TaskPage {
  @State tasks: Task[] = [];
  @State showCreateForm: boolean = false;
  @State selectedFilter: TaskFilter = 'active';
  @State draftTitle: string = '';
  @State draftEstimate: number = 2;
  @State editingTaskId: string = '';
  @State editTitle: string = '';
  @State editEstimate: number = 1;
  @State timerState: TimerState = idleTimerState;
  private ticker: number = -1;

  aboutToAppear(): void {
    this.refresh();
    this.startTicker();
  }

  aboutToDisappear(): void {
    this.stopTicker();
  }

  private async loadTasks(): Promise<void> {
    this.tasks = await TaskService.listAll();
  }

  private async refresh(): Promise<void> {
    this.timerState = await TimerService.restore();
    await this.loadTasks();
  }

  private startTicker(): void {
    this.stopTicker();
    this.ticker = setInterval(async () => {
      this.timerState = await TimerService.restore();
    }, 500);
  }

  private stopTicker(): void {
    if (this.ticker !== -1) {
      clearInterval(this.ticker);
      this.ticker = -1;
    }
  }

  private activeTasks(): Task[] {
    return this.tasks.filter((task: Task) => task.status === 'active');
  }

  private completedTasks(): Task[] {
    return this.tasks.filter((task: Task) => task.status === 'completed');
  }

  private archivedTasks(): Task[] {
    return this.tasks.filter((task: Task) => task.status === 'archived');
  }

  private filteredTasks(): Task[] {
    if (this.selectedFilter === 'completed') {
      return this.completedTasks();
    }

    if (this.selectedFilter === 'archived') {
      return this.archivedTasks();
    }

    return this.activeTasks();
  }

  private async addTask(): Promise<void> {
    const task = await TaskService.add(this.draftTitle, this.draftEstimate);
    if (!task) {
      PromptService.showToast('先写一个任务名称');
      return;
    }

    this.draftTitle = '';
    this.draftEstimate = 2;
    this.showCreateForm = false;
    this.selectedFilter = 'active';
    await this.loadTasks();
    await WidgetService.refreshAllForms();
  }

  private async startTask(task: Task): Promise<void> {
    if (this.isTaskInCurrentTimer(task)) {
      AppStateService.setSelectedTabIndex(0);
      PromptService.showToast('已切到当前专注');
      return;
    }

    const result = await TimerService.tryStartFocus(undefined, task.id, task.title);
    this.timerState = result.state;
    AppStateService.setSelectedTabIndex(0);
    PromptService.showToast(result.didStart ? '已开始专注' : result.message);
    await WidgetService.refreshAllForms();
  }

  private async completeTask(task: Task): Promise<void> {
    await TaskService.markCompleted(task.id);
    await this.refresh();
    await WidgetService.refreshAllForms();
  }

  private async restoreTask(task: Task): Promise<void> {
    await TaskService.restore(task.id);
    this.selectedFilter = 'active';
    await this.refresh();
    await WidgetService.refreshAllForms();
    PromptService.showToast('已恢复到待办');
  }

  private async archiveTask(task: Task): Promise<void> {
    const result = await PromptService.showDialog({
      title: '归档任务？',
      message: task.title,
      buttons: [
        {
          text: '取消',
          color: '#5F9E8A'
        },
        {
          text: '归档',
          color: '#7B8785'
        }
      ]
    });

    if (result.index === 1) {
      await TaskService.archive(task.id);
      this.cancelEdit();
      await this.refresh();
      await WidgetService.refreshAllForms();
      PromptService.showToast('任务已归档');
    }
  }

  private async deleteTask(task: Task): Promise<void> {
    const result = await PromptService.showDialog({
      title: '删除任务？',
      message: task.title,
      buttons: [
        {
          text: '取消',
          color: '#5F9E8A'
        },
        {
          text: '删除',
          color: '#C96F5D'
        }
      ]
    });

    if (result.index === 1) {
      await TaskService.delete(task.id);
      this.cancelEdit();
      await this.refresh();
      await WidgetService.refreshAllForms();
    }
  }

  private async saveEdit(task: Task): Promise<void> {
    const nextTitle = this.editTitle.trim();
    if (!nextTitle) {
      PromptService.showToast('任务名称不能为空');
      return;
    }

    await TaskService.update(task.id, nextTitle, this.editEstimate);
    this.cancelEdit();
    await this.refresh();
    await WidgetService.refreshAllForms();
    PromptService.showToast('任务已更新');
  }

  private toggleCreateForm(): void {
    this.showCreateForm = !this.showCreateForm;
    if (this.showCreateForm) {
      this.cancelEdit();
    }
  }

  private startEdit(task: Task): void {
    this.showCreateForm = false;
    this.editingTaskId = task.id;
    this.editTitle = task.title;
    this.editEstimate = Math.max(1, task.estimatedFocusCount);
  }

  private cancelEdit(): void {
    this.editingTaskId = '';
    this.editTitle = '';
    this.editEstimate = 1;
  }

  private changeDraftEstimate(delta: number): void {
    this.draftEstimate = Math.min(12, Math.max(1, this.draftEstimate + delta));
  }

  private changeEditEstimate(delta: number): void {
    this.editEstimate = Math.min(12, Math.max(1, this.editEstimate + delta));
  }

  private isFocusBlocked(): boolean {
    return TimerService.isFocusStartBlocked(this.timerState);
  }

  private isTaskInCurrentTimer(task: Task): boolean {
    return this.timerState.mode === 'focus' && this.timerState.status !== 'idle' && this.timerState.taskId === task.id;
  }

  private isEditing(task: Task): boolean {
    return this.editingTaskId === task.id;
  }

  private filterButtonColor(filter: TaskFilter): string {
    return this.selectedFilter === filter ? '#5F9E8A' : '#DDE8EA';
  }

  private filterButtonFontColor(filter: TaskFilter): string {
    return this.selectedFilter === filter ? '#FFFFFF' : '#1F2A2A';
  }

  private startButtonTitle(task: Task): string {
    if (this.isTaskInCurrentTimer(task)) {
      return '查看';
    }

    if (this.isFocusBlocked()) {
      return '查看';
    }

    return '开始';
  }

  private startButtonColor(task: Task): string {
    if (task.status !== 'active') {
      return '#DDE8EA';
    }

    if (this.isTaskInCurrentTimer(task)) {
      return '#4D7EA8';
    }

    if (this.isFocusBlocked()) {
      return '#7B8785';
    }

    return '#5F9E8A';
  }

  private taskProgressPercent(task: Task): number {
    if (task.estimatedFocusCount <= 0) {
      return 100;
    }

    return Math.min(100, Math.floor(task.completedFocusCount * 100 / task.estimatedFocusCount));
  }

  private taskProgressWidth(task: Task): string {
    return `${this.taskProgressPercent(task)}%`;
  }

  private taskProgressColor(task: Task): string {
    if (task.status === 'archived') {
      return '#9AA6A3';
    }

    if (task.status === 'completed') {
      return '#7B8785';
    }

    if (this.taskProgressPercent(task) >= 100) {
      return '#4D7EA8';
    }

    return '#5F9E8A';
  }

  private taskStatusText(task: Task): string {
    if (task.status === 'archived') {
      return '已归档';
    }

    if (task.status === 'completed') {
      return '已完成';
    }

    if (this.isTaskInCurrentTimer(task)) {
      return '专注中';
    }

    if (this.taskProgressPercent(task) >= 100) {
      return '目标达成';
    }

    return '进行中';
  }

  private taskStatusColor(task: Task): string {
    if (task.status === 'archived') {
      return '#9AA6A3';
    }

    if (task.status === 'completed') {
      return '#7B8785';
    }

    if (this.isTaskInCurrentTimer(task)) {
      return '#4D7EA8';
    }

    if (this.taskProgressPercent(task) >= 100) {
      return '#4D7EA8';
    }

    return '#5F9E8A';
  }

  private taskRemainingText(task: Task): string {
    if (task.status === 'archived') {
      return '任务已归档';
    }

    if (task.status === 'completed') {
      return '任务已完成';
    }

    const remainingCount = Math.max(0, task.estimatedFocusCount - task.completedFocusCount);
    if (remainingCount === 0) {
      return '已达到预计专注次数';
    }

    return `还差 ${remainingCount} 次`;
  }

  private emptyTitle(): string {
    if (this.selectedFilter === 'completed') {
      return '还没有完成任务';
    }

    if (this.selectedFilter === 'archived') {
      return '归档箱是空的';
    }

    return '今天还没有待办';
  }

  private emptyDescription(): string {
    if (this.selectedFilter === 'completed') {
      return '完成任务后会自动归到这里，随时可以恢复继续做。';
    }

    if (this.selectedFilter === 'archived') {
      return '不想看到但又不想删除的任务，可以先放进归档。';
    }

    return '可以先创建一个任务，也可以回到专注页开始自由专注。';
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Row() {
          Text('任务')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2A2A')
            .layoutWeight(1);

          Button(this.showCreateForm ? '×' : '+')
            .width(44)
            .height(44)
            .fontSize(24)
            .fontColor('#FFFFFF')
            .backgroundColor(this.showCreateForm ? '#7B8785' : '#5F9E8A')
            .borderRadius(22)
            .onClick(() => {
              this.toggleCreateForm();
            });
        }
        .width('100%');

        Row({ space: 8 }) {
          Button(`待办 ${this.activeTasks().length}`)
            .height(36)
            .layoutWeight(1)
            .fontSize(13)
            .fontColor(this.filterButtonFontColor('active'))
            .backgroundColor(this.filterButtonColor('active'))
            .borderRadius(12)
            .onClick(() => {
              this.selectedFilter = 'active';
            });

          Button(`完成 ${this.completedTasks().length}`)
            .height(36)
            .layoutWeight(1)
            .fontSize(13)
            .fontColor(this.filterButtonFontColor('completed'))
            .backgroundColor(this.filterButtonColor('completed'))
            .borderRadius(12)
            .onClick(() => {
              this.selectedFilter = 'completed';
            });

          Button(`归档 ${this.archivedTasks().length}`)
            .height(36)
            .layoutWeight(1)
            .fontSize(13)
            .fontColor(this.filterButtonFontColor('archived'))
            .backgroundColor(this.filterButtonColor('archived'))
            .borderRadius(12)
            .onClick(() => {
              this.selectedFilter = 'archived';
            });
        }
        .width('100%');

        if (this.isFocusBlocked()) {
          Row() {
            Column({ space: 4 }) {
              Text(this.timerState.mode === 'break' ? '当前在歇息' : '当前在专注')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1F2A2A');
              Text(this.timerState.taskTitle ? this.timerState.taskTitle : '自由专注')
                .fontSize(13)
                .fontColor('#7B8785');
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1);

            Button('查看')
              .height(36)
              .width(76)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#5F9E8A')
              .borderRadius(12)
              .onClick(() => {
                AppStateService.setSelectedTabIndex(0);
              });
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#EAF3F0')
          .borderRadius(16);
        }

        if (this.showCreateForm) {
          Column({ space: 14 }) {
            Text('新建任务')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2A2A')
              .width('100%');

            TextInput({ placeholder: '写下要专注完成的事', text: this.draftTitle })
              .height(48)
              .fontSize(15)
              .fontColor('#1F2A2A')
              .placeholderColor('#9AA6A3')
              .backgroundColor('#F6F8F7')
              .borderRadius(14)
              .onChange((value: string) => {
                this.draftTitle = value;
              });

            Row() {
              Text('预计专注')
                .fontSize(15)
                .fontColor('#1F2A2A')
                .layoutWeight(1);
              Button('-')
                .width(36)
                .height(36)
                .fontSize(20)
                .fontColor('#1F2A2A')
                .backgroundColor('#DDE8EA')
                .borderRadius(18)
                .onClick(() => {
                  this.changeDraftEstimate(-1);
                });
              Text(`${this.draftEstimate} 次`)
                .fontSize(15)
                .fontColor('#1F2A2A')
                .width(70)
                .textAlign(TextAlign.Center);
              Button('+')
                .width(36)
                .height(36)
                .fontSize(20)
                .fontColor('#FFFFFF')
                .backgroundColor('#5F9E8A')
                .borderRadius(18)
                .onClick(() => {
                  this.changeDraftEstimate(1);
                });
            }
            .width('100%');

            Button('保存任务')
              .height(48)
              .width('100%')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .backgroundColor('#5F9E8A')
              .borderRadius(14)
              .onClick(() => {
                this.addTask();
              });
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .border({
            width: 1,
            color: '#DDE8EA'
          });
        }

        if (this.filteredTasks().length === 0) {
          Column({ space: 12 }) {
            Text(this.emptyTitle())
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2A2A');
            Text(this.emptyDescription())
              .fontSize(14)
              .fontColor('#7B8785')
              .textAlign(TextAlign.Center);

            Button(this.selectedFilter === 'active' ? '新建任务' : '查看待办')
              .height(38)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#5F9E8A')
              .borderRadius(12)
              .onClick(() => {
                if (this.selectedFilter === 'active') {
                  this.showCreateForm = true;
                  this.cancelEdit();
                } else {
                  this.selectedFilter = 'active';
                }
              });
          }
          .width('100%')
          .padding(24)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .border({
            width: 1,
            color: '#DDE8EA'
          });
        } else {
          ForEach(this.filteredTasks(), (task: Task) => {
            Column({ space: 14 }) {
              Row() {
                Column({ space: 6 }) {
                  Text(task.title)
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(task.status === 'completed' || task.status === 'archived' ? '#7B8785' : '#1F2A2A')
                    .decoration({
                      type: task.status === 'completed' ? TextDecorationType.LineThrough : TextDecorationType.None
                    });

                  Text(`已完成 ${task.completedFocusCount}/${task.estimatedFocusCount} 次专注`)
                    .fontSize(13)
                    .fontColor('#7B8785');
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Text(this.taskStatusText(task))
                  .fontSize(13)
                  .fontColor(this.taskStatusColor(task));
              }
              .width('100%');

              Column({ space: 7 }) {
                Row() {
                  Text(`${this.taskProgressPercent(task)}%`)
                    .fontSize(12)
                    .fontColor(this.taskProgressColor(task))
                    .layoutWeight(1);

                  Text(this.taskRemainingText(task))
                    .fontSize(12)
                    .fontColor('#7B8785');
                }
                .width('100%');

                Stack({ alignContent: Alignment.Start }) {
                  Row()
                    .width('100%')
                    .height(8)
                    .backgroundColor('#EEF3F2')
                    .borderRadius(4);

                  Row()
                    .width(this.taskProgressWidth(task))
                    .height(8)
                    .backgroundColor(this.taskProgressColor(task))
                    .borderRadius(4);
                }
                .width('100%')
                .height(8);
              }
              .width('100%');

              if (this.isEditing(task)) {
                Column({ space: 12 }) {
                  TextInput({ placeholder: '任务名称', text: this.editTitle })
                    .height(46)
                    .fontSize(15)
                    .fontColor('#1F2A2A')
                    .placeholderColor('#9AA6A3')
                    .backgroundColor('#F6F8F7')
                    .borderRadius(14)
                    .onChange((value: string) => {
                      this.editTitle = value;
                    });

                  Row() {
                    Text('预计专注')
                      .fontSize(14)
                      .fontColor('#1F2A2A')
                      .layoutWeight(1);
                    Button('-')
                      .width(34)
                      .height(34)
                      .fontSize(18)
                      .fontColor('#1F2A2A')
                      .backgroundColor('#DDE8EA')
                      .borderRadius(17)
                      .onClick(() => {
                        this.changeEditEstimate(-1);
                      });
                    Text(`${this.editEstimate} 次`)
                      .fontSize(14)
                      .fontColor('#1F2A2A')
                      .width(68)
                      .textAlign(TextAlign.Center);
                    Button('+')
                      .width(34)
                      .height(34)
                      .fontSize(18)
                      .fontColor('#FFFFFF')
                      .backgroundColor('#5F9E8A')
                      .borderRadius(17)
                      .onClick(() => {
                        this.changeEditEstimate(1);
                      });
                  }
                  .width('100%');

                  Row({ space: 10 }) {
                    Button('取消')
                      .height(38)
                      .layoutWeight(1)
                      .fontSize(14)
                      .fontColor('#1F2A2A')
                      .backgroundColor('#DDE8EA')
                      .borderRadius(12)
                      .onClick(() => {
                        this.cancelEdit();
                      });

                    Button('保存')
                      .height(38)
                      .layoutWeight(1)
                      .fontSize(14)
                      .fontColor('#FFFFFF')
                      .backgroundColor('#5F9E8A')
                      .borderRadius(12)
                      .onClick(() => {
                        this.saveEdit(task);
                      });
                  }
                  .width('100%');
                }
                .width('100%')
                .padding(12)
                .backgroundColor('#F6F8F7')
                .borderRadius(14);
              } else if (task.status === 'active') {
                Column({ space: 10 }) {
                  Row({ space: 10 }) {
                    Button(this.startButtonTitle(task))
                      .height(40)
                      .layoutWeight(1)
                      .fontSize(14)
                      .fontColor('#FFFFFF')
                      .backgroundColor(this.startButtonColor(task))
                      .borderRadius(12)
                      .enabled(task.status === 'active')
                      .onClick(() => {
                        this.startTask(task);
                      });

                    Button('完成')
                      .height(40)
                      .layoutWeight(1)
                      .fontSize(14)
                      .fontColor('#1F2A2A')
                      .backgroundColor('#DDE8EA')
                      .borderRadius(12)
                      .onClick(() => {
                        this.completeTask(task);
                      });
                  }
                  .width('100%');

                  Row({ space: 10 }) {
                    Button('编辑')
                      .height(38)
                      .layoutWeight(1)
                      .fontSize(14)
                      .fontColor('#1F2A2A')
                      .backgroundColor('#FFFFFF')
                      .borderRadius(12)
                      .border({
                        width: 1,
                        color: '#DDE8EA'
                      })
                      .onClick(() => {
                        this.startEdit(task);
                      });

                    Button('归档')
                      .height(38)
                      .layoutWeight(1)
                      .fontSize(14)
                      .fontColor('#7B8785')
                      .backgroundColor('#FFFFFF')
                      .borderRadius(12)
                      .border({
                        width: 1,
                        color: '#DDE8EA'
                      })
                      .onClick(() => {
                        this.archiveTask(task);
                      });

                    Button('删除')
                      .height(38)
                      .layoutWeight(1)
                      .fontSize(14)
                      .fontColor('#C96F5D')
                      .backgroundColor('#FFFFFF')
                      .borderRadius(12)
                      .border({
                        width: 1,
                        color: '#E8D3CE'
                      })
                      .onClick(() => {
                        this.deleteTask(task);
                      });
                  }
                  .width('100%');
                }
                .width('100%');
              } else {
                Row({ space: 10 }) {
                  Button('恢复')
                    .height(40)
                    .layoutWeight(1)
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#5F9E8A')
                    .borderRadius(12)
                    .onClick(() => {
                      this.restoreTask(task);
                    });

                  Button('编辑')
                    .height(40)
                    .layoutWeight(1)
                    .fontSize(14)
                    .fontColor('#1F2A2A')
                    .backgroundColor('#DDE8EA')
                    .borderRadius(12)
                    .onClick(() => {
                      this.startEdit(task);
                    });

                  Button(task.status === 'completed' ? '归档' : '删除')
                    .height(40)
                    .layoutWeight(1)
                    .fontSize(14)
                    .fontColor(task.status === 'completed' ? '#7B8785' : '#C96F5D')
                    .backgroundColor('#FFFFFF')
                    .borderRadius(12)
                    .border({
                      width: 1,
                      color: task.status === 'completed' ? '#DDE8EA' : '#E8D3CE'
                    })
                    .onClick(() => {
                      if (task.status === 'completed') {
                        this.archiveTask(task);
                      } else {
                        this.deleteTask(task);
                      }
                    });
                }
                .width('100%');
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(18)
            .border({
              width: 1,
              color: '#DDE8EA'
            });
          }, (task: Task) => task.id);
        }
      }
      .width('100%')
      .padding(20);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F8F7');
  }
}
