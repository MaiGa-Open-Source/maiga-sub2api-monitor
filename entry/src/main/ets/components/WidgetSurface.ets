import { CardTheme, cardStyle } from '../model/CardPreferences';
import { cardTexturePath } from '../model/CardVisuals';

@Component
export struct WidgetSurface {
  @Prop theme: string = 'aurora';
  @Prop surface: string = '#FFE8E9F7';
  @Prop surfaceEnd: string = '#FFF8DDD8';
  @Prop edge: string = '#B9BFD5';
  @Prop line: string = '#B9BFD5';
  @Prop texture: string = '#4A4F91';
  @Prop highlight: string = '#FFFFFF';

  build() {
    Stack() {
      if (this.theme === 'pixel' || this.theme === 'chrome') {
        Shape() {
          Path({ width: '300px', height: '300px', commands: cardTexturePath(this.theme) })
            .fill(Color.Transparent).stroke(this.texture).strokeWidth(this.theme === 'pixel' ? 0.8 : 0.35)
            .opacity(this.theme === 'pixel' ? 0.09 : 0.06)
        }
        .viewPort({ x: 0, y: 0, width: '300px', height: '300px' }).width('100%').height('100%')
      }
      if (this.theme === 'label') {
        Stack() {
          Column().width('100%').height('100%')
            .border({ width: 1, color: this.line }).borderRadius(14)
        }.width('100%').height('100%').padding(4)
      }
      if (this.theme === 'chrome' || this.theme === 'pixel') {
        Stack() {
          Column().width('100%').height('100%')
            .border({ width: { top: 1, left: 1, bottom: 0, right: 0 }, color: this.highlight })
            .borderRadius(cardStyle(this.theme as CardTheme).radius - 2)
        }.width('100%').height('100%').padding(2)
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.surface)
    .linearGradient({ angle: 135, colors: [[this.surface, 0], [this.surfaceEnd, 1]] })
    .border({ width: this.theme === 'pixel' ? 3 : 1, color: this.edge })
    .borderRadius(cardStyle(this.theme as CardTheme).radius)
    .clip(true)
  }
}
