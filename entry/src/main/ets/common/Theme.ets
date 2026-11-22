/**
 * 主题与配色常量，统一管理界面用色，避免颜色值散落在页面代码中。
 */
export const COLOR_PRIMARY: string = '#2BA275';
export const COLOR_PRIMARY_DARK: string = '#1F8A61';
export const COLOR_PRIMARY_LIGHT: string = '#E7F6EF';
export const COLOR_BG: string = '#F4F6F8';
export const COLOR_CARD: string = '#FFFFFF';
export const COLOR_TEXT: string = '#1F2937';
export const COLOR_TEXT_SUB: string = '#6B7280';
export const COLOR_TEXT_WEAK: string = '#9CA3AF';
export const COLOR_LINE: string = '#EEF1F4';
export const COLOR_DANGER: string = '#E5484D';
export const COLOR_WARN: string = '#F59E0B';
export const COLOR_INFO: string = '#3B82F6';
export const COLOR_PURPLE: string = '#8B5CF6';

export const PAGE_PADDING: number = 16;
export const CARD_RADIUS: number = 16;

/** 优先级 => 颜色（1 高、2 中、3 低） */
export function priorityColor(priority: number): string {
  if (priority === 1) {
    return COLOR_DANGER;
  }
  if (priority === 3) {
    return COLOR_TEXT_WEAK;
  }
  return COLOR_WARN;
}

/** 优先级 => 文本（1 高、2 中、3 低） */
export function priorityText(priority: number): string {
  if (priority === 1) {
    return '高';
  }
  if (priority === 3) {
    return '低';
  }
  return '中';
}

/** 分类 => 颜色 */
export function categoryColor(category: string): string {
  if (category === '学习') {
    return COLOR_INFO;
  }
  if (category === '生活') {
    return COLOR_PRIMARY;
  }
  if (category === '工作') {
    return COLOR_PURPLE;
  }
  return COLOR_WARN;
}
