import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TaskItem } from '../model/TaskItem';
import { TaskStore } from '../common/TaskStore';
import {
  COLOR_BG,
  COLOR_CARD,
  COLOR_DANGER,
  COLOR_LINE,
  COLOR_PRIMARY,
  COLOR_PRIMARY_LIGHT,
  COLOR_TEXT,
  COLOR_TEXT_SUB,
  COLOR_TEXT_WEAK
} from '../common/Theme';
import { priorityText } from '../common/Theme';

/**
 * 关于与设置页：展示版本信息、管理本地数据、说明使用方法。
 */
@Entry
@Component
struct AboutPage {
  @State taskCount: number = 0;
  @State doneCount: number = 0;

  aboutToAppear(): void {
    TaskStore.init(getContext(this) as common.UIAbilityContext);
    this.refreshCount();
  }

  onPageShow(): void {
    this.refreshCount();
  }

  private refreshCount(): void {
    const list: TaskItem[] = TaskStore.load();
    this.taskCount = list.length;
    let done: number = 0;
    for (let i = 0; i < list.length; i++) {
      if (list[i].done) {
        done = done + 1;
      }
    }
    this.doneCount = done;
  }

  /** 把当前任务清单整理为纯文本并写入系统剪贴板 */
  private copyToClipboard(): void {
    const list: TaskItem[] = TaskStore.sort(TaskStore.load());
    if (list.length === 0) {
      promptAction.showToast({ message: '当前没有任务可复制' });
      return;
    }
    let text: string = '轻记清单（共 ' + list.length.toString() + ' 项）\n';
    for (let i = 0; i < list.length; i++) {
      const item: TaskItem = list[i];
      const flag: string = item.done ? '[已完成]' : '[待办]';
      text = text + (i + 1).toString() + '. ' + flag + item.title +
        '（' + item.category + '/' + priorityText(item.priority) + '优先级）';
      if (item.dueDate.length > 0) {
        text = text + ' 截止 ' + item.dueDate;
      }
      text = text + '\n';
    }
    try {
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      pasteboard.getSystemPasteboard().setData(data)
        .then(() => {
          promptAction.showToast({ message: '任务清单已复制到剪贴板' });
        })
        .catch((err: BusinessError) => {
          promptAction.showToast({ message: '复制失败：' + err.message });
        });
    } catch (err) {
      const error = err as BusinessError;
      promptAction.showToast({ message: '复制失败：' + error.message });
    }
  }

  /** 清空全部数据（二次确认） */
  private clearAll(): void {
    if (this.taskCount === 0) {
      promptAction.showToast({ message: '当前没有数据' });
      return;
    }
    AlertDialog.show({
      title: '清空全部数据',
      message: '将删除本地保存的全部任务，且无法恢复，确定继续吗？',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '清空',
        fontColor: COLOR_DANGER,
        action: () => {
          TaskStore.clear();
          this.refreshCount();
          promptAction.showToast({ message: '数据已清空' });
        }
      }
    });
  }

  /** 用示例数据覆盖当前数据，便于演示与回归测试 */
  private resetSample(): void {
    AlertDialog.show({
      title: '载入示例数据',
      message: '将用 9 条示例任务覆盖当前数据，确定继续吗？',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '载入',
        action: () => {
          TaskStore.save(TaskStore.sort(TaskStore.buildSampleTasks()));
          this.refreshCount();
          promptAction.showToast({ message: '示例数据已载入' });
        }
      }
    });
  }

  @Builder
  infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(COLOR_TEXT_SUB)
      Blank()
      Text(value)
        .fontSize(13)
        .fontColor(COLOR_TEXT)
    }
    .width('100%')
    .padding({ top: 11, bottom: 11 })
  }

  @Builder
  actionRow(label: string, color: string, action: () => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(color)
      Blank()
      Text('›')
        .fontSize(18)
        .fontColor(COLOR_TEXT_WEAK)
    }
    .width('100%')
    .padding({ top: 13, bottom: 13 })
    .onClick(() => {
      action();
    })
  }

  @Builder
  usageItem(index: number, text: string) {
    Row({ space: 10 }) {
      Text(index.toString())
        .fontSize(11)
        .fontColor(COLOR_PRIMARY)
        .width(18)
        .height(18)
        .textAlign(TextAlign.Center)
        .borderRadius(9)
        .backgroundColor(COLOR_PRIMARY_LIGHT)
      Text(text)
        .fontSize(13)
        .fontColor(COLOR_TEXT_SUB)
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 5, bottom: 5 })
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor(COLOR_TEXT)
          .width(40)
          .onClick(() => {
            router.back();
          })
        Text('关于与设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLOR_TEXT)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('')
          .width(40)
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(COLOR_CARD)

      Scroll() {
        Column({ space: 14 }) {
          // 应用信息
          Column({ space: 10 }) {
            Stack() {
              Text('✓')
                .fontSize(30)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
            }
            .width(64)
            .height(64)
            .borderRadius(18)
            .linearGradient({
              angle: 135,
              colors: [[COLOR_PRIMARY, 0.0], ['#57C99A', 1.0]]
            })

            Text('轻记清单')
              .fontSize(19)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLOR_TEXT)
            Text('一个轻量的待办事项管理应用')
              .fontSize(12)
              .fontColor(COLOR_TEXT_WEAK)
            Text('版本 1.0.0')
              .fontSize(11)
              .fontColor(COLOR_TEXT_WEAK)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(10)
              .backgroundColor('#F1F3F5')
          }
          .width('100%')
          .padding({ top: 24, bottom: 24 })
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)

          // 数据概览
          Column({ space: 6 }) {
            Row() {
              Text('数据概览')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(COLOR_TEXT)
            }
            .width('100%')
            .padding({ bottom: 6 })

            this.infoRow('任务总数', this.taskCount.toString() + ' 项')
            Divider().color(COLOR_LINE)
            this.infoRow('已完成', this.doneCount.toString() + ' 项')
            Divider().color(COLOR_LINE)
            this.infoRow('存储方式', 'Preferences（本地）')
            Divider().color(COLOR_LINE)
            this.infoRow('存储位置', '应用沙箱 /data/storage')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)
          .alignItems(HorizontalAlign.Start)

          // 数据操作
          Column({ space: 0 }) {
            Row() {
              Text('数据管理')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(COLOR_TEXT)
            }
            .width('100%')
            .padding({ bottom: 4 })

            this.actionRow('复制任务清单到剪贴板', COLOR_PRIMARY, () => {
              this.copyToClipboard();
            })
            Divider().color(COLOR_LINE)
            this.actionRow('载入示例数据', COLOR_TEXT, () => {
              this.resetSample();
            })
            Divider().color(COLOR_LINE)
            this.actionRow('清空全部数据', COLOR_DANGER, () => {
              this.clearAll();
            })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)
          .alignItems(HorizontalAlign.Start)

          // 使用说明
          Column({ space: 6 }) {
            Text('使用说明')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(COLOR_TEXT)
              .width('100%')
              .padding({ bottom: 4 })
            this.usageItem(1, '在首页点击右下角「＋」新建任务，标题为必填项')
            this.usageItem(2, '点击任务左侧圆圈切换完成状态，点击星标可置顶')
            this.usageItem(3, '在列表中向左滑动任务卡片可快速删除')
            this.usageItem(4, '点击任务卡片进入编辑页，可修改分类、优先级与截止日期')
            this.usageItem(5, '顶部「统计」入口可查看完成率、分类分布与近七日趋势')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)
          .alignItems(HorizontalAlign.Start)

          // 技术信息
          Column({ space: 6 }) {
            Text('技术信息')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(COLOR_TEXT)
              .width('100%')
              .padding({ bottom: 6 })
            this.infoRow('开发语言', 'ArkTS')
            Divider().color(COLOR_LINE)
            this.infoRow('UI 框架', 'ArkUI（声明式）')
            Divider().color(COLOR_LINE)
            this.infoRow('应用模型', 'Stage 模型')
            Divider().color(COLOR_LINE)
            this.infoRow('运行环境', 'HarmonyOS 6.0.1 / API 21')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)
          .alignItems(HorizontalAlign.Start)

          Text('本应用为《智能手机软件开发技术》课程结课作品，数据仅保存在本机')
            .fontSize(11)
            .fontColor(COLOR_TEXT_WEAK)
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 6, bottom: 10 })
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
