import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { TaskItem, createTaskId } from '../model/TaskItem';
import { formatDate, todayString } from './DateUtil';

const DOMAIN: number = 0x0000;
const TAG: string = 'TaskStore';

/** 首选项文件名 */
const PREF_NAME: string = 'qingji_store';
/** 任务列表序列化后存放的键 */
const KEY_TASKS: string = 'task_list';
/** 是否已写入过示例数据的标记 */
const KEY_SEEDED: string = 'seeded';

/**
 * 本地数据仓库（单例式静态类）。
 * 使用 Preferences 以 JSON 字符串形式保存任务数组，实现应用重启后数据不丢失。
 */
export class TaskStore {
  private static store: preferences.Preferences | undefined = undefined;

  /** 在 Ability 或页面创建时调用一次，完成首选项实例初始化 */
  static init(context: common.Context): void {
    if (TaskStore.store !== undefined) {
      return;
    }
    try {
      const options: preferences.Options = { name: PREF_NAME };
      TaskStore.store = preferences.getPreferencesSync(context, options);
      hilog.info(DOMAIN, TAG, '%{public}s', 'preferences initialized');
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'init preferences failed, code=%{public}d, msg=%{public}s', error.code, error.message);
    }
  }

  /** 存储是否可用 */
  static isReady(): boolean {
    return TaskStore.store !== undefined;
  }

  /** 读取全部任务；数据损坏时返回空数组并记录日志，保证界面不崩溃 */
  static load(): TaskItem[] {
    if (TaskStore.store === undefined) {
      return [];
    }
    try {
      const raw: string = TaskStore.store.getSync(KEY_TASKS, '[]') as string;
      if (raw.length === 0) {
        return [];
      }
      const list: TaskItem[] = JSON.parse(raw) as TaskItem[];
      if (list === null || list === undefined) {
        return [];
      }
      return list;
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'load tasks failed, code=%{public}d, msg=%{public}s', error.code, error.message);
      return [];
    }
  }

  /** 写入全部任务，返回是否成功 */
  static save(list: TaskItem[]): boolean {
    if (TaskStore.store === undefined) {
      return false;
    }
    try {
      TaskStore.store.putSync(KEY_TASKS, JSON.stringify(list));
      TaskStore.store.flush((err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN, TAG, 'flush failed, code=%{public}d', err.code);
        }
      });
      return true;
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'save tasks failed, code=%{public}d, msg=%{public}s', error.code, error.message);
      return false;
    }
  }

  /** 清空全部任务（用于设置页的“清空数据”） */
  static clear(): boolean {
    return TaskStore.save([]);
  }

  /**
   * 排序规则：置顶优先 -> 未完成优先 -> 优先级高优先 -> 截止日期近优先 -> 创建时间新优先。
   * 返回新数组，不修改入参，便于与 @State 配合触发刷新。
   */
  static sort(list: TaskItem[]): TaskItem[] {
    const copy: TaskItem[] = list.slice(0);
    copy.sort((a: TaskItem, b: TaskItem): number => {
      if (a.pinned !== b.pinned) {
        return a.pinned ? -1 : 1;
      }
      if (a.done !== b.done) {
        return a.done ? 1 : -1;
      }
      if (a.priority !== b.priority) {
        return a.priority - b.priority;
      }
      if (a.dueDate !== b.dueDate) {
        if (a.dueDate.length === 0) {
          return 1;
        }
        if (b.dueDate.length === 0) {
          return -1;
        }
        return a.dueDate < b.dueDate ? -1 : 1;
      }
      return b.createTime - a.createTime;
    });
    return copy;
  }

  /** 首次启动写入示例数据，方便直接体验；已写入过则不再重复 */
  static ensureSeedData(): TaskItem[] {
    if (TaskStore.store === undefined) {
      return [];
    }
    const seeded: boolean = TaskStore.store.getSync(KEY_SEEDED, false) as boolean;
    if (seeded) {
      return [];
    }
    const list: TaskItem[] = TaskStore.buildSampleTasks();
    TaskStore.save(list);
    TaskStore.store.putSync(KEY_SEEDED, true);
    TaskStore.store.flush((err: BusinessError) => {
      if (err) {
        hilog.error(DOMAIN, TAG, 'seed flush failed, code=%{public}d', err.code);
      }
    });
    return list;
  }

  /** 生成一组覆盖“逾期 / 今日 / 已完成 / 置顶”等状态的示例任务 */
  static buildSampleTasks(): TaskItem[] {
    const now: Date = new Date();
    const dayMs: number = 24 * 60 * 60 * 1000;
    const today: string = todayString();
    const tomorrow: string = formatDate(new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1));
    const afterTomorrow: string = formatDate(new Date(now.getFullYear(), now.getMonth(), now.getDate() + 2));
    const yesterday: string = formatDate(new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1));
    const dayBeforeYesterday: string = formatDate(new Date(now.getFullYear(), now.getMonth(), now.getDate() - 2));

    const list: TaskItem[] = [];

    const t1: TaskItem = new TaskItem(createTaskId(), '完成《智能手机软件开发技术》课程报告', '学习');
    t1.note = '正文不少于 4000 字，包含系统设计、关键代码与测试记录';
    t1.priority = 1;
    t1.dueDate = afterTomorrow;
    t1.pinned = true;
    list.push(t1);

    const t2: TaskItem = new TaskItem(createTaskId(), '复习 ArkTS 状态管理 @State 与 @Link', '学习');
    t2.note = '重点理解状态变量驱动 UI 刷新的机制';
    t2.priority = 2;
    t2.dueDate = today;
    list.push(t2);

    const t3: TaskItem = new TaskItem(createTaskId(), '去图书馆归还借阅的两本书', '生活');
    t3.priority = 3;
    t3.dueDate = tomorrow;
    list.push(t3);

    const t4: TaskItem = new TaskItem(createTaskId(), '整理实验四的运行截图', '学习');
    t4.priority = 2;
    t4.dueDate = yesterday;
    list.push(t4);

    const t5: TaskItem = new TaskItem(createTaskId(), '小组会议：确定结课作品答辩分工', '工作');
    t5.note = '主讲、演示与问答各一人';
    t5.priority = 1;
    t5.dueDate = today;
    list.push(t5);

    const t6: TaskItem = new TaskItem(createTaskId(), '晚跑 3 公里', '生活');
    t6.priority = 3;
    t6.dueDate = today;
    t6.done = true;
    t6.doneTime = now.getTime() - 2 * 60 * 60 * 1000;
    list.push(t6);

    const t7: TaskItem = new TaskItem(createTaskId(), '提交课程实验报告 PDF', '学习');
    t7.priority = 1;
    t7.done = true;
    t7.doneTime = now.getTime() - dayMs;
    list.push(t7);

    const t8: TaskItem = new TaskItem(createTaskId(), '给宿舍买洗衣液和抽纸', '生活');
    t8.priority = 3;
    t8.done = true;
    t8.doneTime = now.getTime() - 2 * dayMs;
    list.push(t8);

    const t9: TaskItem = new TaskItem(createTaskId(), '备份手机相册到电脑', '其他');
    t9.priority = 2;
    t9.dueDate = dayBeforeYesterday;
    t9.done = true;
    t9.doneTime = now.getTime() - 3 * dayMs;
    list.push(t9);

    return TaskStore.sort(list);
  }
}
