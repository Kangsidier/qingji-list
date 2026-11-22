import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CATEGORY_LIST, PRIORITY_LIST, TaskItem, cloneTask, createTaskId } from '../model/TaskItem';
import { EditParams } from '../model/RouteParams';
import { TaskStore } from '../common/TaskStore';
import {
  COLOR_BG,
  COLOR_CARD,
  COLOR_DANGER,
  COLOR_PRIMARY,
  COLOR_PRIMARY_LIGHT,
  COLOR_TEXT,
  COLOR_TEXT_SUB,
  COLOR_TEXT_WEAK,
  categoryColor,
  priorityColor,
  priorityText
} from '../common/Theme';
import { formatDate, formatDateTime, parseDateString } from '../common/DateUtil';

/**
 * 任务编辑页：既承担“新增”也承担“修改”，通过路由参数中的 id 区分。
 */
@Entry
@Component
struct TaskEditPage {
  @State taskId: string = '';
  @State title: string = '';
  @State note: string = '';
  @State category: string = CATEGORY_LIST[0];
  @State priority: number = 2;
  @State dueDate: string = '';
  @State pinned: boolean = false;
  @State createTime: number = 0;
  /** 是否为编辑模式 */
  @State isEdit: boolean = false;

  aboutToAppear(): void {
    TaskStore.init(getContext(this) as common.UIAbilityContext);
    const params: EditParams = router.getParams() as EditParams;
    if (params !== undefined && params !== null && params.id.length > 0) {
      this.taskId = params.id;
      this.isEdit = true;
      this.loadTask(params.id);
    }
  }

  /** 根据主键把任务内容回填到表单 */
  private loadTask(id: string): void {
    const list: TaskItem[] = TaskStore.load();
    for (let i = 0; i < list.length; i++) {
      if (list[i].id === id) {
        const item: TaskItem = list[i];
        this.title = item.title;
        this.note = item.note;
        this.category = item.category;
        this.priority = item.priority;
        this.dueDate = item.dueDate;
        this.pinned = item.pinned;
        this.createTime = item.createTime;
        return;
      }
    }
    promptAction.showToast({ message: '任务不存在，可能已被删除' });
  }

  /** 选择截止日期 */
  private pickDate(): void {
    const selectedTime: number = parseDateString(this.dueDate);
    const selected: Date = selectedTime > 0 ? new Date(selectedTime) : new Date();
    DatePickerDialog.show({
      start: new Date(2020, 0, 1),
      end: new Date(2035, 11, 31),
      selected: selected,
      onDateAccept: (value: Date) => {
        this.dueDate = formatDate(value);
      }
    });
  }

  /** 保存：新增时创建对象，编辑时替换原对象，最后统一写入 Preferences */
  private save(): void {
    const name: string = this.title.trim();
    if (name.length === 0) {
      promptAction.showToast({ message: '请输入任务标题' });
      return;
    }
    if (name.length > 40) {
      promptAction.showToast({ message: '标题不能超过 40 个字' });
      return;
    }

    const list: TaskItem[] = TaskStore.load();
    if (this.isEdit) {
      let found: boolean = false;
      for (let i = 0; i < list.length; i++) {
        if (list[i].id === this.taskId) {
          const item: TaskItem = cloneTask(list[i]);
          item.title = name;
          item.note = this.note.trim();
          item.category = this.category;
          item.priority = this.priority;
          item.dueDate = this.dueDate;
          item.pinned = this.pinned;
          list[i] = item;
          found = true;
          break;
        }
      }
      if (!found) {
        promptAction.showToast({ message: '保存失败：任务已不存在' });
        return;
      }
    } else {
      const item: TaskItem = new TaskItem(createTaskId(), name, this.category);
      item.note = this.note.trim();
      item.priority = this.priority;
      item.dueDate = this.dueDate;
      item.pinned = this.pinned;
      list.push(item);
    }

    if (TaskStore.save(TaskStore.sort(list))) {
      promptAction.showToast({ message: this.isEdit ? '修改已保存' : '任务已添加' });
      router.back();
    } else {
      promptAction.showToast({ message: '保存失败，请重试' });
    }
  }

  /** 编辑模式下删除当前任务 */
  private confirmDelete(): void {
    AlertDialog.show({
      title: '删除任务',
      message: '删除后不可恢复，确定删除吗？',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: COLOR_DANGER,
        action: () => {
          const list: TaskItem[] = TaskStore.load();
          const rest: TaskItem[] = [];
          for (let i = 0; i < list.length; i++) {
            if (list[i].id !== this.taskId) {
              rest.push(list[i]);
            }
          }
          TaskStore.save(rest);
          promptAction.showToast({ message: '已删除' });
          router.back();
        }
      }
    });
  }

  private goBack(): void {
    router.back();
  }

  @Builder
  sectionTitle(text: string) {
    Text(text)
      .fontSize(13)
      .fontColor(COLOR_TEXT_SUB)
      .fontWeight(FontWeight.Medium)
      .width('100%')
  }

  @Builder
  categoryChip(name: string) {
    Text(name)
      .fontSize(13)
      .fontColor(this.category === name ? Color.White : categoryColor(name))
      .fontWeight(this.category === name ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 14, right: 14, top: 7, bottom: 7 })
      .borderRadius(16)
      .backgroundColor(this.category === name ? categoryColor(name) : '#F3F5F7')
      .onClick(() => {
        this.category = name;
      })
  }

  @Builder
  priorityChip(value: number) {
    Row({ space: 5 }) {
      Circle()
        .width(7)
        .height(7)
        .fill(this.priority === value ? Color.White : priorityColor(value))
      Text(priorityText(value) + '优先级')
        .fontSize(13)
        .fontColor(this.priority === value ? Color.White : COLOR_TEXT_SUB)
    }
    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
    .borderRadius(16)
    .backgroundColor(this.priority === value ? priorityColor(value) : '#F3F5F7')
    .onClick(() => {
      this.priority = value;
    })
  }

  build() {
    Column() {
      // ===== 自定义标题栏 =====
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor(COLOR_TEXT)
          .width(40)
          .textAlign(TextAlign.Start)
          .onClick(() => {
            this.goBack();
          })
        Text(this.isEdit ? '编辑任务' : '新建任务')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLOR_TEXT)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('保存')
          .fontSize(15)
          .fontColor(COLOR_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .width(40)
          .textAlign(TextAlign.End)
          .onClick(() => {
            this.save();
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(COLOR_CARD)

      Scroll() {
        Column({ space: 14 }) {
          // 任务标题
          Column({ space: 10 }) {
            this.sectionTitle('任务标题')
            TextInput({ text: this.title, placeholder: '例如：完成课程报告初稿' })
              .width('100%')
              .height(46)
              .backgroundColor('#F5F7F9')
              .borderRadius(10)
              .fontSize(15)
              .maxLength(40)
              .placeholderColor(COLOR_TEXT_WEAK)
              .onChange((value: string) => {
                this.title = value;
              })
            Row() {
              Blank()
              Text(this.title.length.toString() + '/40')
                .fontSize(11)
                .fontColor(COLOR_TEXT_WEAK)
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)

          // 备注
          Column({ space: 10 }) {
            this.sectionTitle('备注说明（选填）')
            TextArea({ text: this.note, placeholder: '补充任务的具体要求、联系人等信息' })
              .width('100%')
              .height(96)
              .backgroundColor('#F5F7F9')
              .borderRadius(10)
              .fontSize(14)
              .maxLength(200)
              .placeholderColor(COLOR_TEXT_WEAK)
              .onChange((value: string) => {
                this.note = value;
              })
          }
          .alignItems(HorizontalAlign.Start)
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)

          // 分类
          Column({ space: 12 }) {
            this.sectionTitle('所属分类')
            Row({ space: 8 }) {
              ForEach(CATEGORY_LIST, (name: string) => {
                this.categoryChip(name)
              }, (name: string) => name)
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)

          // 优先级
          Column({ space: 12 }) {
            this.sectionTitle('优先级')
            Row({ space: 8 }) {
              ForEach(PRIORITY_LIST, (value: number) => {
                this.priorityChip(value)
              }, (value: number) => value.toString())
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)

          // 截止日期
          Column({ space: 12 }) {
            this.sectionTitle('截止日期')
            Row() {
              Text(this.dueDate.length > 0 ? this.dueDate : '未设置')
                .fontSize(15)
                .fontColor(this.dueDate.length > 0 ? COLOR_TEXT : COLOR_TEXT_WEAK)
                .layoutWeight(1)
              if (this.dueDate.length > 0) {
                Text('清除')
                  .fontSize(13)
                  .fontColor(COLOR_TEXT_WEAK)
                  .margin({ right: 14 })
                  .onClick(() => {
                    this.dueDate = '';
                  })
              }
              Text('选择日期')
                .fontSize(13)
                .fontColor(COLOR_PRIMARY)
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .borderRadius(8)
                .backgroundColor(COLOR_PRIMARY_LIGHT)
                .onClick(() => {
                  this.pickDate();
                })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
          }
          .alignItems(HorizontalAlign.Start)
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)

          // 置顶
          Row() {
            Column({ space: 3 }) {
              Text('置顶显示')
                .fontSize(15)
                .fontColor(COLOR_TEXT)
              Text('开启后该任务始终排在列表最前')
                .fontSize(11)
                .fontColor(COLOR_TEXT_WEAK)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.pinned })
              .selectedColor(COLOR_PRIMARY)
              .onChange((isOn: boolean) => {
                this.pinned = isOn;
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)
          .alignItems(VerticalAlign.Center)

          if (this.isEdit) {
            Column({ space: 6 }) {
              Text('创建于 ' + formatDateTime(this.createTime))
                .fontSize(11)
                .fontColor(COLOR_TEXT_WEAK)
              Text('删除任务')
                .fontSize(15)
                .fontColor(COLOR_DANGER)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 12, bottom: 12 })
                .borderRadius(16)
                .backgroundColor(COLOR_CARD)
                .onClick(() => {
                  this.confirmDelete();
                })
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 32 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BG)
  }
}
