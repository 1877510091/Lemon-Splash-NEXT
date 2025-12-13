import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct ReviewPage {
  @State showAnswer: boolean = false;

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(24).fontColor(['#0D47A1']).onClick(() => router.back()) // ✅ 修复
        Text("智能复习").fontSize(18).fontColor('#0D47A1').fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .height(56).padding({ left: 16, right: 16 })

      Progress({ value: 80, total: 100 }).color('#2196F3').backgroundColor(Color.White).height(4).width('100%')

      Blank().layoutWeight(1)

      Column() {
        Text("ambitious")
          .fontSize(48).fontWeight(FontWeight.Bold).fontColor('#0D47A1').fontFamily('Georgia').textAlign(TextAlign.Center)

        Row() {
          SymbolGlyph($r('sys.symbol.speaker_wave_2')).fontSize(24).fontColor(['#2196F3']) // ✅ 修复
            .onClick(() => { try{ promptAction.showToast({ message: '播放...' }); }catch(e){} })
        }.margin({ top: 10 })

        if (this.showAnswer) {
          Text("/æmˈbɪʃəs/").fontSize(20).fontColor('#1976D2').margin({ top: 20, bottom: 20 })
          Text("adj. 有雄心的，野心勃勃的；费劲的")
            .fontSize(18).fontColor('#757575').textAlign(TextAlign.Center)
        } else {
          Blank().height(50)
          Text("点击查看释义").fontSize(14).fontColor(Color.Gray).margin({ top: 30, bottom: 30 })
          Blank().height(50)
        }
      }
      .width('85%')
      .padding({ top: 60, bottom: 60, left: 30, right: 30 })
      .backgroundColor(Color.White)
      .borderRadius(40)
      .shadow({ radius: 30, color: 'rgba(33, 150, 243, 0.1)', offsetY: 15 })

      Blank().layoutWeight(2)

      if (!this.showAnswer) {
        Button("查看答案")
          .backgroundColor('#BBDEFB')
          .fontColor('#0D47A1')
          .fontWeight(FontWeight.Bold)
          .width(160)
          .height(50)
          .onClick(() => this.showAnswer = true)
      } else {
        Row() {
          Column() {
            Stack() {
              Circle({ width: 70, height: 70 }).fill('#FFEBEE')
              SymbolGlyph($r('sys.symbol.xmark')).fontSize(30).fontColor(['#E57373']) // ✅ 修复
            }
            Text("忘记了").fontSize(14).fontWeight(FontWeight.Bold).fontColor('#E57373').margin({ top: 8 })
          }
          .onClick(() => this.showAnswer = false)

          Blank().width(50)

          Column() {
            Stack() {
              Circle({ width: 70, height: 70 }).fill('#F0F4C3')
              SymbolGlyph($r('sys.symbol.checkmark')).fontSize(30).fontColor(['#9E9D24']) // ✅ 修复
            }
            Text("记得").fontSize(14).fontWeight(FontWeight.Bold).fontColor('#9E9D24').margin({ top: 8 })
          }
          .onClick(() => this.showAnswer = false)
        }
      }

      Blank().height(50)
    }
    .width('100%').height('100%')
    .backgroundColor('#E3F2FD')
    .padding({ top: 10 })
  }
}