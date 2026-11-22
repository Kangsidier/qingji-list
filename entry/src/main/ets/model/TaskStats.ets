import { TaskItem } from './TaskItem';
import { isOverdue, todayString, recentDates } from '../common/DateUtil';

/** 单个分类的统计项 */
export class CategoryStat {
  category: string;
  total: number;
  done: number;

  constructor(category: string) {
    this.category = category;
    this.total = 0;
    this.done = 0;
  }
}

/** 单日完成数量统计项 */
export class DailyStat {
  date: string;
  label: string;
  count: number;

  constructor(date: string, label: string) {
    this.date = date;
    this.label = label;
    this.count = 0;
  }
}

/**
 * 统计结果模型：由任务数组一次性计算得出，页面只负责展示。
 */
export class TaskStats {
  total: number = 0;
  doneCount: number = 0;
  pendingCount: number = 0;
  overdueCount: number = 0;
  todayDueCount: number = 0;
  todayDoneCount: number = 0;
  highPriorityPending: number = 0;
  /** 完成率，0~100 的整数 */
  rate: number = 0;
  categories: CategoryStat[] = [];
  week: DailyStat[] = [];

  /** 计算统计结果 */
  static compute(list: TaskItem[], categoryNames: string[]): TaskStats {
    const stats: TaskStats = new TaskStats();
    const today: string = todayString();

    // 分类统计初始化，保证没有数据的分类也占一行
    for (let i = 0; i < categoryNames.length; i++) {
      stats.categories.push(new CategoryStat(categoryNames[i]));
    }

    // 近七天日期轴
    const dates: string[] = recentDates(7);
    for (let i = 0; i < dates.length; i++) {
      const parts: string[] = dates[i].split('-');
      stats.week.push(new DailyStat(dates[i], parts[1] + '/' + parts[2]));
    }

    for (let i = 0; i < list.length; i++) {
      const item: TaskItem = list[i];
      stats.total = stats.total + 1;
      if (item.done) {
        stats.doneCount = stats.doneCount + 1;
        // 完成时间落在近七天，计入柱状图
        if (item.doneTime > 0) {
          const doneDay: Date = new Date(item.doneTime);
          const doneDate: string = doneDay.getFullYear().toString() + '-' +
            (doneDay.getMonth() + 1 < 10 ? '0' : '') + (doneDay.getMonth() + 1).toString() + '-' +
            (doneDay.getDate() < 10 ? '0' : '') + doneDay.getDate().toString();
          for (let j = 0; j < stats.week.length; j++) {
            if (stats.week[j].date === doneDate) {
              stats.week[j].count = stats.week[j].count + 1;
            }
          }
        }
      } else {
        stats.pendingCount = stats.pendingCount + 1;
        if (isOverdue(item.dueDate, item.done)) {
          stats.overdueCount = stats.overdueCount + 1;
        }
        if (item.priority === 1) {
          stats.highPriorityPending = stats.highPriorityPending + 1;
        }
        if (item.dueDate === today) {
          stats.todayDueCount = stats.todayDueCount + 1;
        }
      }
      // 分类统计
      for (let k = 0; k < stats.categories.length; k++) {
        if (stats.categories[k].category === item.category) {
          stats.categories[k].total = stats.categories[k].total + 1;
          if (item.done) {
            stats.categories[k].done = stats.categories[k].done + 1;
          }
        }
      }
    }

    // 今日完成数
    for (let i = 0; i < list.length; i++) {
      const item: TaskItem = list[i];
      if (item.done && item.doneTime > 0) {
        const d: Date = new Date(item.doneTime);
        const value: string = d.getFullYear().toString() + '-' +
          (d.getMonth() + 1 < 10 ? '0' : '') + (d.getMonth() + 1).toString() + '-' +
          (d.getDate() < 10 ? '0' : '') + d.getDate().toString();
        if (value === today) {
          stats.todayDoneCount = stats.todayDoneCount + 1;
        }
      }
    }

    if (stats.total > 0) {
      stats.rate = Math.round(stats.doneCount * 100 / stats.total);
    }
    return stats;
  }
}
