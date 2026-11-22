/**
 * 待办任务数据模型。
 * 该类的实例会被 JSON.stringify 序列化后写入 Preferences，
 * 因此不定义成员方法，所有逻辑放在工具函数或数据仓库中。
 */
export class TaskItem {
  /** 主键：创建时间戳 + 随机数，保证唯一 */
  id: string;
  /** 任务标题，必填，最长 40 字 */
  title: string;
  /** 备注说明，可为空 */
  note: string;
  /** 分类：学习 / 生活 / 工作 / 其他 */
  category: string;
  /** 优先级：1 高、2 中、3 低 */
  priority: number;
  /** 截止日期，格式 yyyy-MM-dd，空串表示不设置 */
  dueDate: string;
  /** 是否已完成 */
  done: boolean;
  /** 是否置顶 */
  pinned: boolean;
  /** 创建时间戳 */
  createTime: number;
  /** 完成时间戳，未完成为 0 */
  doneTime: number;

  constructor(id: string, title: string, category: string) {
    this.id = id;
    this.title = title;
    this.note = '';
    this.category = category;
    this.priority = 2;
    this.dueDate = '';
    this.done = false;
    this.pinned = false;
    this.createTime = Date.now();
    this.doneTime = 0;
  }
}

/** 分类候选值，顺序即界面展示顺序 */
export const CATEGORY_LIST: string[] = ['学习', '生活', '工作', '其他'];

/** 优先级候选值 */
export const PRIORITY_LIST: number[] = [1, 2, 3];

/** 主键生成器 */
export function createTaskId(): string {
  const random: number = Math.floor(Math.random() * 10000);
  return 't' + Date.now().toString() + '_' + random.toString();
}

/**
 * 深拷贝一条任务。
 * 修改状态时先拷贝再替换数组元素，配合 @State 触发界面刷新。
 */
export function cloneTask(source: TaskItem): TaskItem {
  const target: TaskItem = new TaskItem(source.id, source.title, source.category);
  target.note = source.note;
  target.priority = source.priority;
  target.dueDate = source.dueDate;
  target.done = source.done;
  target.pinned = source.pinned;
  target.createTime = source.createTime;
  target.doneTime = source.doneTime;
  return target;
}
