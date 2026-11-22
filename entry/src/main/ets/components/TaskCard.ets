import { TaskItem } from '../model/TaskItem';
import {
  COLOR_CARD,
  COLOR_DANGER,
  COLOR_LINE,
  COLOR_PRIMARY,
  COLOR_TEXT,
  COLOR_TEXT_SUB,
  COLOR_TEXT_WEAK,
  COLOR_WARN,
  CARD_RADIUS,
  categoryColor,
  priorityColor,
  priorityText
} from '../common/Theme';
import { dueDescription, isOverdue } from '../common/DateUtil';

/**
 * 任务卡片自定义组件，主页列表与统计页共用。
 * 通过回调把点击事件交回父组件处理，组件本身不直接改数据。
 */
@Component
export struct TaskCard {
  @Prop item: TaskItem;
  onToggle: (id: string) => void = (id: string) => {
  };
  onPin: (id: string) => void = (id: string) => {
  };
  /** 点击卡片主体进入编辑页 */
  onOpen: (id: string) => void = (id: string) => {
  };

  /** 分类标签底色：在分类色基础上加透明度 */
  private tint(color: string): string {
    return '#14' + color.substring(1);
  }

  /** 截止日期文案：已完成的任务不再提示“逾期”，统一显示已完成 */
  private dueText(): string {
    if (this.item.dueDate.length === 0) {
      return '';
    }
    if (this.item.done) {
      return '已完成';
    }
    return dueDescription(this.item.dueDate, this.item.done);
  }

  build() {
    Row({ space: 12 }) {
      // 完成状态复选框（自绘圆形）
      Stack() {
        if (this.item.done) {
          Text('✓')
            .fontSize(14)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
        }
      }
      .width(24)
      .height(24)
      .borderRadius(12)
      .borderWidth(1.5)
      .borderColor(this.item.done ? COLOR_PRIMARY : '#D1D5DB')
      .backgroundColor(this.item.done ? COLOR_PRIMARY : Color.Transparent)
      .margin({ top: 2 })
      .onClick(() => {
        this.onToggle(this.item.id);
      })

      Column({ space: 6 }) {
        Row() {
          Text(this.item.title)
            .fontSize(16)
            .fontColor(this.item.done ? COLOR_TEXT_WEAK : COLOR_TEXT)
            .fontWeight(FontWeight.Medium)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .decoration({
              type: this.item.done ? TextDecorationType.LineThrough : TextDecorationType.None,
              color: COLOR_TEXT_WEAK
            })
            .layoutWeight(1)

          Text(this.item.pinned ? '★' : '☆')
            .fontSize(18)
            .fontColor(this.item.pinned ? COLOR_WARN : '#D6DAE0')
            .margin({ left: 6 })
            .onClick(() => {
              this.onPin(this.item.id);
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.item.note.length > 0) {
          Text(this.item.note)
            .fontSize(12)
            .fontColor(COLOR_TEXT_SUB)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        Row({ space: 6 }) {
          Text(this.item.category)
            .fontSize(11)
            .fontColor(categoryColor(this.item.category))
            .backgroundColor(this.tint(categoryColor(this.item.category)))
            .borderRadius(6)
            .padding({ left: 7, right: 7, top: 2, bottom: 2 })

          Row({ space: 3 }) {
            Circle()
              .width(6)
              .height(6)
              .fill(priorityColor(this.item.priority))
            Text(priorityText(this.item.priority))
              .fontSize(11)
              .fontColor(priorityColor(this.item.priority))
          }
          .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          .borderRadius(6)
          .backgroundColor('#F3F4F6')

          Blank()

          Text(this.dueText())
            .fontSize(11)
            .fontColor(isOverdue(this.item.dueDate, this.item.done) ? COLOR_DANGER :
              (this.item.dueDate.length > 0 ? COLOR_TEXT_SUB : COLOR_TEXT_WEAK))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(14)
    .alignItems(VerticalAlign.Top)
    .backgroundColor(COLOR_CARD)
    .borderRadius(CARD_RADIUS)
    .border({ width: this.item.pinned ? 1 : 0, color: COLOR_LINE })
    .onClick(() => {
      this.onOpen(this.item.id);
    })
  }
}
