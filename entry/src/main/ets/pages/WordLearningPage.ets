import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct WordLearningPage {
  @State progress: number = 0.3;

  build() {
    Column() {
      // 标题栏
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(24).fontColor(['#004D40']).onClick(() => router.back()) // ✅ 修复
        Text("分组: 1 | 进度: 5/20").fontSize(18).fontColor('#004D40').fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .height(56).padding({ left: 16, right: 16 })

      Progress({ value: 30, total: 100, type: ProgressType.Linear })
        .color('#CDDC39').backgroundColor(Color.White).height(4).width('100%')

      Blank().layoutWeight(1)

      // === 单词卡片 ===
      Column() {
        Text("abandon")
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#004D40')
          .fontFamily('Georgia')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.MARQUEE }) // ✅ 修复：必须大写 MARQUEE

        Row() {
          Text("/əˈbændən/").fontSize(20).fontColor('#827717').margin({ right: 10 })
          SymbolGlyph($r('sys.symbol.speaker_wave_2')).fontSize(24).fontColor(['#4DB6AC']) // ✅ 修复
            .onClick(() => {
              try { promptAction.showToast({ message: '播放发音...' }); } catch(e){}
            })
        }
        .margin({ top: 10, bottom: 30 })

        Scroll() {
          Text("v. 遗弃，抛弃；放弃，中止\nn. 放任，狂热")
            .fontSize(18).fontColor('#757575').textAlign(TextAlign.Center).lineHeight(28)
        }
        .height(120)
      }
      .width('85%')
      .padding({ top: 60, bottom: 60, left: 30, right: 30 })
      .backgroundColor(Color.White)
      .borderRadius(40)
      .shadow({ radius: 30, color: 'rgba(0, 150, 136, 0.1)', offsetY: 15 })

      Blank().layoutWeight(2)

      // === 底部按钮 ===
      Column() {
        Row() {
          Column() {
            Stack() {
              Circle({ width: 75, height: 75 }).fill('#FFEBEE')
              SymbolGlyph($r('sys.symbol.xmark')).fontSize(32).fontColor(['#E57373']) // ✅ 修复
            }
            Text("忘记").fontSize(16).fontWeight(FontWeight.Bold).fontColor('#E57373').margin({ top: 8 })
          }
          .onClick(() => { try{ promptAction.showToast({ message: '加入错题本' }); }catch(e){} })

          Blank().width(40)

          Column() {
            Stack() {
              Circle({ width: 75, height: 75 }).fill('#F0F4C3')
              SymbolGlyph($r('sys.symbol.checkmark')).fontSize(32).fontColor(['#9E9D24']) // ✅ 修复
            }
            Text("认识").fontSize(16).fontWeight(FontWeight.Bold).fontColor('#9E9D24').margin({ top: 8 })
          }
          .onClick(() => { try{ promptAction.showToast({ message: '太棒了！' }); }catch(e){} })
        }

        Blank().height(25)

        Row() {
          // ✅ 修复：arrow_uturn_backward -> arrow_left
          SymbolGlyph($r('sys.symbol.arrow_left')).fontSize(20).fontColor(['#757575']) // ✅ 修复
          Text("撤销").fontSize(14).fontWeight(FontWeight.Bold).fontColor('#757575').margin({ left: 6 })
        }
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .backgroundColor(Color.White)
        .borderRadius(20)
        .border({ width: 1, color: '#E0E0E0' })
      }
      .padding({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E0F2F1')
    .padding({ top: 10 })
  }
}