import promptAction from '@ohos.promptAction';
import { Task } from '../models/Task';
import { AppStateService } from '../services/AppStateService';
import { TaskService } from '../services/TaskService';
import { TimerService } from '../services/TimerService';

@Component
export struct TaskPage {
  @State tasks: Task[] = [];
  @State showCreateForm: boolean = false;
  @State draftTitle: string = '';
  @State draftEstimate: number = 2;

  aboutToAppear(): void {
    this.loadTasks();
  }

  private async loadTasks(): Promise<void> {
    this.tasks = await TaskService.listAll();
  }

  private async addTask(): Promise<void> {
    const task = await TaskService.add(this.draftTitle, this.draftEstimate);
    if (!task) {
      promptAction.showToast({ message: '先写一个任务名称' });
      return;
    }

    this.draftTitle = '';
    this.draftEstimate = 2;
    this.showCreateForm = false;
    await this.loadTasks();
  }

  private async startTask(task: Task): Promise<void> {
    await TimerService.startFocus(undefined, task.id, task.title);
    AppStateService.setSelectedTabIndex(0);
    promptAction.showToast({ message: '已开始专注' });
  }

  private async completeTask(task: Task): Promise<void> {
    await TaskService.markCompleted(task.id);
    await this.loadTasks();
  }

  private async deleteTask(task: Task): Promise<void> {
    const result = await promptAction.showDialog({
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
      await this.loadTasks();
    }
  }

  private changeDraftEstimate(delta: number): void {
    this.draftEstimate = Math.min(12, Math.max(1, this.draftEstimate + delta));
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
              this.showCreateForm = !this.showCreateForm;
            });
        }
        .width('100%');

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

        if (this.tasks.length === 0) {
          Column({ space: 10 }) {
            Text('今天还没有任务')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2A2A');
            Text('可以先创建一个任务，也可以回到专注页开始自由专注。')
              .fontSize(14)
              .fontColor('#7B8785')
              .textAlign(TextAlign.Center);
          }
          .width('100%')
          .padding(24)
          .backgroundColor('#FFFFFF')
          .borderRadius(18)
          .border({
            width: 1,
            color: '#DDE8EA'
          });
        } else {
          ForEach(this.tasks, (task: Task) => {
            Column({ space: 14 }) {
              Row() {
                Column({ space: 6 }) {
                  Text(task.title)
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(task.status === 'completed' ? '#7B8785' : '#1F2A2A')
                    .decoration({ type: task.status === 'completed' ? TextDecorationType.LineThrough : TextDecorationType.None });

                  Text(`已完成 ${task.completedFocusCount}/${task.estimatedFocusCount} 次专注`)
                    .fontSize(13)
                    .fontColor('#7B8785');
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Text(task.status === 'completed' ? '已完成' : '进行中')
                  .fontSize(13)
                  .fontColor(task.status === 'completed' ? '#7B8785' : '#5F9E8A');
              }
              .width('100%');

              Row({ space: 10 }) {
                Button('开始')
                  .height(40)
                  .layoutWeight(1)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .backgroundColor(task.status === 'active' ? '#5F9E8A' : '#DDE8EA')
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
                  .enabled(task.status === 'active')
                  .onClick(() => {
                    this.completeTask(task);
                  });

                Button('删除')
                  .height(40)
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
