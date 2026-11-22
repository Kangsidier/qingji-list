import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TaskItem, cloneTask } from '../model/TaskItem';
import { TaskStats } from '../model/TaskStats';
import { CATEGORY_LIST } from '../model/TaskItem';
import { EditParams } from '../model/RouteParams';
import { TaskStore } from '../common/TaskStore';
import { TaskCard } from '../components/TaskCard';
import { EmptyView } from '../components/EmptyView';
import {
  COLOR_BG,
  COLOR_CARD,
  COLOR_DANGER,
  COLOR_PRIMARY,
  COLOR_PRIMARY_DARK,
  COLOR_TEXT_SUB,
  COLOR_TEXT_WEAK
} from '../common/Theme';
import { formatMonthDay, weekdayText } from '../common/DateUtil';

const FILTER_ALL: number = 0;
const FILTER_TODO: number = 1;
const FILTER_DONE: number = 2;
const FILTER_HIGH: number = 3;

/**
 * 首页：展示任务列表，支持搜索、按状态筛选、完成勾选、置顶与左滑删除。
 */
@Entry
@Component
struct Index {
  /** 全量任务 */
  @State tasks: TaskItem[] = [];
  /** 搜索关键字 */
  @State keyword: string = '';
  /** 当前筛选下标：0 全部、1 未完成、2 已完成、3 高优先级 */
  @State filterIndex: number = FILTER_ALL;
  /** 统计结果，用于顶部进度卡片 */
  @State stats: TaskStats = new TaskStats();
  /** 数据是否已加载，避免首次进入时空白闪烁 */
  @State loaded: boolean = false;

  aboutToAppear(): void {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    TaskStore.init(context);
    let list: TaskItem[] = TaskStore.load();
    if (list.length === 0) {
      // 首次启动写入示例数据，便于直接体验；设置页可一键清空
      const seeded: TaskItem[] = TaskStore.ensureSeedData();
      if (seeded.length > 0) {
        list = seeded;
      }
    }
    this.applyTasks(list);
    this.loaded = true;
  }

  /** 从编辑页返回时刷新，保证列表与存储一致 */
  onPageShow(): void {
    if (this.loaded) {
      this.applyTasks(TaskStore.load());
    }
  }

  /** 统一更新任务数组与统计结果 */
  private applyTasks(list: TaskItem[]): void {
    this.tasks = TaskStore.sort(list);
    this.stats = TaskStats.compute(this.tasks, CATEGORY_LIST);
  }

  /** 按筛选条件与关键字过滤，返回排序后的可见任务 */
  private visibleTasks(): TaskItem[] {
    const key: string = this.keyword.trim();
    const result: TaskItem[] = [];
    for (let i = 0; i < this.tasks.length; i++) {
      const item: TaskItem = this.tasks[i];
      // 关键字匹配标题或备注
      if (key.length > 0) {
        const hit: boolean = item.title.toLowerCase().indexOf(key.toLowerCase()) >= 0 ||
          item.note.toLowerCase().indexOf(key.toLowerCase()) >= 0;
        if (!hit) {
          continue;
        }
      }
      if (this.filterIndex === FILTER_TODO && item.done) {
        continue;
      }
      if (this.filterIndex === FILTER_DONE && !item.done) {
        continue;
      }
      if (this.filterIndex === FILTER_HIGH && item.priority !== 1) {
        continue;
      }
      result.push(item);
    }
    return result;
  }

  /** 按主键修改任务字段并持久化 */
  private updateTask(id: string, updater: (task: TaskItem) => void): void {
    const next: TaskItem[] = [];
    for (let i = 0; i < this.tasks.length; i++) {
      const copy: TaskItem = cloneTask(this.tasks[i]);
      if (copy.id === id) {
        updater(copy);
      }
      next.push(copy);
    }
    this.applyTasks(next);
    TaskStore.save(this.tasks);
  }

  /** 切换完成状态：勾选时记录完成时间，取消勾选时清零 */
  private toggleTask(id: string): void {
    this.updateTask(id, (task: TaskItem) => {
      task.done = !task.done;
      task.doneTime = task.done ? Date.now() : 0;
    });
  }

  /** 切换置顶状态 */
  private togglePin(id: string): void {
    this.updateTask(id, (task: TaskItem) => {
      task.pinned = !task.pinned;
    });
    promptAction.showToast({ message: '已更新置顶状态', duration: 1200 });
  }

  /** 删除任务前二次确认，避免误触 */
  private confirmDelete(item: TaskItem): void {
    AlertDialog.show({
      title: '删除任务',
      message: '确定删除「' + item.title + '」吗？删除后不可恢复。',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: COLOR_DANGER,
        action: () => {
          this.removeTask(item.id);
        }
      }
    });
  }

  private removeTask(id: string): void {
    const next: TaskItem[] = [];
    for (let i = 0; i < this.tasks.length; i++) {
      if (this.tasks[i].id !== id) {
        next.push(cloneTask(this.tasks[i]));
      }
    }
    this.applyTasks(next);
    TaskStore.save(this.tasks);
    promptAction.showToast({ message: '已删除', duration: 1500 });
  }

  /** 跳转编辑页：传入空 id 表示新增 */
  private openEdit(id: string): void {
    const params: EditParams = new EditParams();
    params.id = id;
    router.pushUrl({ url: 'pages/TaskEditPage', params: params })
      .catch((err: BusinessError) => {
        promptAction.showToast({ message: '页面跳转失败：' + err.message });
      });
  }

  private openStats(): void {
    router.pushUrl({ url: 'pages/StatsPage' })
      .catch((err: BusinessError) => {
        promptAction.showToast({ message: '页面跳转失败：' + err.message });
      });
  }

  private openAbout(): void {
    router.pushUrl({ url: 'pages/AboutPage' })
      .catch((err: BusinessError) => {
        promptAction.showToast({ message: '页面跳转失败：' + err.message });
      });
  }

  /** 顶部日期文案，如“11月10日 星期一” */
  private dateText(): string {
    const now: Date = new Date();
    return formatMonthDay(now) + ' ' + weekdayText(now);
  }

  /** 顶部提示语 */
  private summaryText(): string {
    if (this.stats.total === 0) {
      return '还没有任务，点击右下角开始记录';
    }
    if (this.stats.pendingCount === 0) {
      return '全部完成，今天可以放松一下了';
    }
    return '还有 ' + this.stats.pendingCount.toString() + ' 项待完成，其中今日 ' +
      this.stats.todayDueCount.toString() + ' 项';
  }

  @Builder
  headerAction(label: string, action: () => void) {
    Text(label)
      .fontSize(12)
      .fontColor(Color.White)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(14)
      .backgroundColor('#33FFFFFF')
      .onClick(() => {
        action();
      })
  }

  @Builder
  filterChip(label: string, index: number) {
    Text(label)
      .fontSize(13)
      .fontColor(this.filterIndex === index ? Color.White : COLOR_TEXT_SUB)
      .fontWeight(this.filterIndex === index ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 14, right: 14, top: 7, bottom: 7 })
      .borderRadius(16)
      .backgroundColor(this.filterIndex === index ? COLOR_PRIMARY : COLOR_CARD)
      .onClick(() => {
        this.filterIndex = index;
      })
  }

  @Builder
  deleteAction(item: TaskItem) {
    Column() {
      Text('删除')
        .fontSize(13)
        .fontColor(Color.White)
    }
    .width(72)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(COLOR_DANGER)
    .borderRadius(12)
    .onClick(() => {
      this.confirmDelete(item);
    })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // ===== 顶部渐变头部 =====
        Column({ space: 14 }) {
          Row() {
            Column({ space: 3 }) {
              Text('轻记清单')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text(this.dateText())
                .fontSize(12)
                .fontColor('#E6FFFFFF')
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            Row({ space: 8 }) {
              this.headerAction('统计', () => {
                this.openStats();
              })
              this.headerAction('关于', () => {
                this.openAbout();
              })
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 进度卡片
          Row({ space: 14 }) {
            Stack() {
              Progress({ value: this.stats.rate, total: 100, type: ProgressType.Ring })
                .width(58)
                .height(58)
                .color(Color.White)
                .backgroundColor('#33FFFFFF')
                .style({ strokeWidth: 5 })
              Text(this.stats.rate.toString() + '%')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }

            Column({ space: 5 }) {
              Text(this.summaryText())
                .fontSize(14)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text('共 ' + this.stats.total.toString() + ' 项 · 已完成 ' + this.stats.doneCount.toString() +
                ' 项 · 逾期 ' + this.stats.overdueCount.toString() + ' 项')
                .fontSize(11)
                .fontColor('#D9FFFFFF')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(14)
          .borderRadius(16)
          .backgroundColor('#26FFFFFF')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 18, bottom: 18 })
        .linearGradient({
          angle: 135,
          colors: [[COLOR_PRIMARY_DARK, 0.0], [COLOR_PRIMARY, 0.6], ['#57C99A', 1.0]]
        })
        .borderRadius({ bottomLeft: 24, bottomRight: 24 })

        // ===== 搜索与筛选 =====
        Column({ space: 10 }) {
          Search({ value: this.keyword, placeholder: '搜索任务标题或备注' })
            .width('100%')
            .height(42)
            .backgroundColor(COLOR_CARD)
            .placeholderColor(COLOR_TEXT_WEAK)
            .textFont({ size: 14 })
            .borderRadius(21)
            .onChange((value: string) => {
              this.keyword = value;
            })

          Scroll() {
            Row({ space: 8 }) {
              this.filterChip('全部', FILTER_ALL)
              this.filterChip('未完成', FILTER_TODO)
              this.filterChip('已完成', FILTER_DONE)
              this.filterChip('高优先级', FILTER_HIGH)
            }
          }
          .width('100%')
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .align(Alignment.Start)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14 })

        // ===== 任务列表 =====
        if (this.visibleTasks().length === 0) {
          EmptyView({
            title: this.tasks.length === 0 ? '还没有任何任务' : '没有符合条件的任务',
            subtitle: this.tasks.length === 0 ? '点击右下角「＋」新建第一条待办' : '换个关键字或筛选条件试试'
          })
        } else {
          List({ space: 10 }) {
            ForEach(this.visibleTasks(), (item: TaskItem) => {
              ListItem() {
                TaskCard({
                  item: item,
                  onToggle: (id: string) => {
                    this.toggleTask(id);
                  },
                  onPin: (id: string) => {
                    this.togglePin(id);
                  },
                  onOpen: (id: string) => {
                    this.openEdit(id);
                  }
                })
              }
              .swipeAction({ end: this.deleteAction.bind(this, item) })
            }, (item: TaskItem) => item.id + '_' + item.done + '_' + item.pinned + '_' + item.priority + '_' + item.dueDate)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 12, bottom: 88 })
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(COLOR_BG)

      // ===== 新建任务悬浮按钮 =====
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text('＋')
          .fontSize(28)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .width(56)
      .height(56)
      .backgroundColor(COLOR_PRIMARY)
      .shadow({ radius: 16, color: '#4D2BA275', offsetX: 0, offsetY: 6 })
      .margin({ right: 20, bottom: 28 })
      .onClick(() => {
        this.openEdit('');
      })
    }
    .width('100%')
    .height('100%')
  }
}
