import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { CATEGORY_LIST, TaskItem } from '../model/TaskItem';
import { CategoryStat, DailyStat, TaskStats } from '../model/TaskStats';
import { TaskStore } from '../common/TaskStore';
import {
  COLOR_BG,
  COLOR_CARD,
  COLOR_DANGER,
  COLOR_LINE,
  COLOR_PRIMARY,
  COLOR_TEXT,
  COLOR_TEXT_SUB,
  COLOR_TEXT_WEAK,
  COLOR_WARN,
  categoryColor
} from '../common/Theme';

/**
 * 统计页：展示任务总量、完成率、逾期情况、分类分布与近七日完成趋势。
 */
@Entry
@Component
struct StatsPage {
  @State stats: TaskStats = new TaskStats();
  @State tasks: TaskItem[] = [];

  aboutToAppear(): void {
    TaskStore.init(getContext(this) as common.UIAbilityContext);
    this.reload();
  }

  onPageShow(): void {
    this.reload();
  }

  private reload(): void {
    this.tasks = TaskStore.sort(TaskStore.load());
    this.stats = TaskStats.compute(this.tasks, CATEGORY_LIST);
  }

  /** 分类完成率（用于进度条宽度） */
  private categoryPercent(item: CategoryStat): number {
    if (item.total === 0) {
      return 0;
    }
    const percent: number = Math.round(item.done * 100 / item.total);
    return percent < 3 ? 3 : percent;
  }

  /** 近七日柱状图高度 */
  private barHeight(item: DailyStat): number {
    let max: number = 1;
    for (let i = 0; i < this.stats.week.length; i++) {
      if (this.stats.week[i].count > max) {
        max = this.stats.week[i].count;
      }
    }
    if (item.count === 0) {
      return 8;
    }
    return 8 + Math.round(item.count * 72 / max);
  }

  /** 清除全部已完成任务 */
  private clearDone(): void {
    if (this.stats.doneCount === 0) {
      promptAction.showToast({ message: '当前没有已完成的任务' });
      return;
    }
    AlertDialog.show({
      title: '清除已完成任务',
      message: '将删除 ' + this.stats.doneCount.toString() + ' 条已完成记录，确定继续吗？',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '清除',
        fontColor: COLOR_DANGER,
        action: () => {
          const rest: TaskItem[] = [];
          for (let i = 0; i < this.tasks.length; i++) {
            if (!this.tasks[i].done) {
              rest.push(this.tasks[i]);
            }
          }
          TaskStore.save(rest);
          this.reload();
          promptAction.showToast({ message: '已清除完成记录' });
        }
      }
    });
  }

  @Builder
  metricCard(label: string, value: string, color: string, suffix: string) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(12)
        .fontColor(COLOR_TEXT_SUB)
      Row({ space: 3 }) {
        Text(value)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
        Text(suffix)
          .fontSize(11)
          .fontColor(COLOR_TEXT_WEAK)
          .margin({ bottom: 3 })
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .width('48%')
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(COLOR_CARD)
    .borderRadius(14)
  }

  @Builder
  cardTitle(text: string, sub: string) {
    Row() {
      Text(text)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLOR_TEXT)
      Blank()
      Text(sub)
        .fontSize(11)
        .fontColor(COLOR_TEXT_WEAK)
    }
    .width('100%')
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor(COLOR_TEXT)
          .width(40)
          .onClick(() => {
            router.back();
          })
        Text('数据统计')
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
          // 完成率总览
          Row({ space: 16 }) {
            Stack() {
              Progress({ value: this.stats.rate, total: 100, type: ProgressType.Ring })
                .width(96)
                .height(96)
                .color(COLOR_PRIMARY)
                .backgroundColor('#EDF1F5')
                .style({ strokeWidth: 8 })
              Column({ space: 2 }) {
                Text(this.stats.rate.toString() + '%')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(COLOR_TEXT)
                Text('完成率')
                  .fontSize(10)
                  .fontColor(COLOR_TEXT_WEAK)
              }
            }

            Column({ space: 10 }) {
              Row({ space: 6 }) {
                Circle().width(8).height(8).fill(COLOR_PRIMARY)
                Text('已完成 ' + this.stats.doneCount.toString() + ' 项')
                  .fontSize(13)
                  .fontColor(COLOR_TEXT_SUB)
              }
              Row({ space: 6 }) {
                Circle().width(8).height(8).fill(COLOR_WARN)
                Text('待完成 ' + this.stats.pendingCount.toString() + ' 项')
                  .fontSize(13)
                  .fontColor(COLOR_TEXT_SUB)
              }
              Row({ space: 6 }) {
                Circle().width(8).height(8).fill(COLOR_DANGER)
                Text('已逾期 ' + this.stats.overdueCount.toString() + ' 项')
                  .fontSize(13)
                  .fontColor(COLOR_TEXT_SUB)
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)
          .alignItems(VerticalAlign.Center)

          // 关键指标
          Row({ space: 12 }) {
            this.metricCard('任务总数', this.stats.total.toString(), COLOR_TEXT, '项')
            this.metricCard('今日完成', this.stats.todayDoneCount.toString(), COLOR_PRIMARY, '项')
          }
          .width('100%')

          Row({ space: 12 }) {
            this.metricCard('高优先级待办', this.stats.highPriorityPending.toString(), COLOR_DANGER, '项')
            this.metricCard('今日到期', this.stats.todayDueCount.toString(), COLOR_WARN, '项')
          }
          .width('100%')

          // 分类分布
          Column({ space: 14 }) {
            this.cardTitle('分类完成情况', '已完成 / 总数')
            ForEach(this.stats.categories, (item: CategoryStat) => {
              Row({ space: 10 }) {
                Text(item.category)
                  .fontSize(12)
                  .fontColor(COLOR_TEXT_SUB)
                  .width(34)
                Stack({ alignContent: Alignment.Start }) {
                  Row()
                    .width('100%')
                    .height(8)
                    .borderRadius(4)
                    .backgroundColor('#EFF2F5')
                  Row()
                    .width(this.categoryPercent(item).toString() + '%')
                    .height(8)
                    .borderRadius(4)
                    .backgroundColor(categoryColor(item.category))
                }
                .layoutWeight(1)
                .height(8)

                Text(item.done.toString() + '/' + item.total.toString())
                  .fontSize(11)
                  .fontColor(COLOR_TEXT_WEAK)
                  .width(40)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
            }, (item: CategoryStat) => item.category)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)
          .alignItems(HorizontalAlign.Start)

          // 近七日完成趋势
          Column({ space: 16 }) {
            this.cardTitle('近七日完成趋势', '单位：项')
            Row() {
              ForEach(this.stats.week, (item: DailyStat) => {
                Column({ space: 6 }) {
                  Text(item.count > 0 ? item.count.toString() : '')
                    .fontSize(10)
                    .fontColor(COLOR_TEXT_SUB)
                  Column()
                    .width(18)
                    .height(this.barHeight(item))
                    .borderRadius(5)
                    .backgroundColor(item.count > 0 ? COLOR_PRIMARY : '#E8EBEE')
                  Text(item.label)
                    .fontSize(9)
                    .fontColor(COLOR_TEXT_WEAK)
                }
                .height(118)
                .layoutWeight(1)
                .justifyContent(FlexAlign.End)
              }, (item: DailyStat) => item.date)
            }
            .width('100%')
            .height(120)
            .alignItems(VerticalAlign.Bottom)

            Divider().color(COLOR_LINE)

            Row() {
              Text('累计完成 ' + this.stats.doneCount.toString() + ' 项，继续保持')
                .fontSize(11)
                .fontColor(COLOR_TEXT_WEAK)
              Blank()
              Text('清除已完成')
                .fontSize(12)
                .fontColor(COLOR_DANGER)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(12)
                .backgroundColor('#FDECEC')
                .onClick(() => {
                  this.clearDone();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(COLOR_CARD)
          .borderRadius(16)
          .alignItems(HorizontalAlign.Start)
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
