/**
 * 日期与时间工具方法，全部为纯函数，方便在各页面复用与测试。
 */

/** 补零：8 -> "08" */
export function pad2(value: number): string {
  return value < 10 ? '0' + value.toString() : value.toString();
}

/** 日期 => "2026-11-10" */
export function formatDate(date: Date): string {
  return date.getFullYear().toString() + '-' + pad2(date.getMonth() + 1) + '-' + pad2(date.getDate());
}

/** 日期 => "11月10日" */
export function formatMonthDay(date: Date): string {
  return (date.getMonth() + 1).toString() + '月' + date.getDate().toString() + '日';
}

/** 时间戳 => "11月10日 20:30" */
export function formatDateTime(timestamp: number): string {
  if (timestamp <= 0) {
    return '--';
  }
  const d: Date = new Date(timestamp);
  return formatMonthDay(d) + ' ' + pad2(d.getHours()) + ':' + pad2(d.getMinutes());
}

/** 今天，形如 "2026-11-10" */
export function todayString(): string {
  return formatDate(new Date());
}

/** 星期中文 */
export function weekdayText(date: Date): string {
  const names: string[] = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
  return names[date.getDay()];
}

/** 把 "2026-11-10" 解析为当天 0 点的时间戳，解析失败返回 0 */
export function parseDateString(value: string): number {
  if (value.length !== 10) {
    return 0;
  }
  const parts: string[] = value.split('-');
  if (parts.length !== 3) {
    return 0;
  }
  const year: number = Number.parseInt(parts[0]);
  const month: number = Number.parseInt(parts[1]);
  const day: number = Number.parseInt(parts[2]);
  if (Number.isNaN(year) || Number.isNaN(month) || Number.isNaN(day)) {
    return 0;
  }
  return new Date(year, month - 1, day).getTime();
}

/** 相差天数：to - from，单位天；参数为 "yyyy-MM-dd" 格式 */
export function diffDays(from: string, to: string): number {
  const fromTime: number = parseDateString(from);
  const toTime: number = parseDateString(to);
  if (fromTime === 0 || toTime === 0) {
    return 0;
  }
  return Math.round((toTime - fromTime) / (24 * 60 * 60 * 1000));
}

/** 截止日期的人类可读描述 */
export function dueDescription(dueDate: string, done: boolean): string {
  if (dueDate.length === 0) {
    return '无截止日期';
  }
  const delta: number = diffDays(todayString(), dueDate);
  if (delta === 0) {
    return done ? '今天截止' : '今天截止';
  }
  if (delta === 1) {
    return '明天截止';
  }
  if (delta === -1) {
    return '昨天截止';
  }
  if (delta < 0) {
    return '已逾期' + Math.abs(delta).toString() + '天';
  }
  return '还剩' + delta.toString() + '天';
}

/** 是否已逾期（未完成且截止日期早于今天） */
export function isOverdue(dueDate: string, done: boolean): boolean {
  if (done || dueDate.length === 0) {
    return false;
  }
  return diffDays(todayString(), dueDate) < 0;
}

/** 近 N 天的日期字符串数组，最后一项为今天 */
export function recentDates(days: number): string[] {
  const result: string[] = [];
  const now: Date = new Date();
  for (let i = days - 1; i >= 0; i--) {
    const d: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
    result.push(formatDate(d));
  }
  return result;
}
