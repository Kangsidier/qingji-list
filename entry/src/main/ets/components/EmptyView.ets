import { COLOR_TEXT_SUB, COLOR_TEXT_WEAK } from '../common/Theme';

/**
 * 列表空状态组件：数据为空或筛选无结果时展示，避免出现“白屏”。
 */
@Component
export struct EmptyView {
  @Prop title: string;
  @Prop subtitle: string;

  build() {
    Column({ space: 10 }) {
      Stack() {
        Text('✓')
          .fontSize(30)
          .fontColor(COLOR_TEXT_WEAK)
      }
      .width(72)
      .height(72)
      .borderRadius(36)
      .backgroundColor('#EFF2F5')

      Text(this.title)
        .fontSize(15)
        .fontColor(COLOR_TEXT_SUB)
        .fontWeight(FontWeight.Medium)

      Text(this.subtitle)
        .fontSize(12)
        .fontColor(COLOR_TEXT_WEAK)
        .textAlign(TextAlign.Center)
        .padding({ left: 40, right: 40 })
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .justifyContent(FlexAlign.Center)
  }
}
