import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct DonationPage {
  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(24).fontColor([Color.Black]).onClick(() => router.back()) // ✅ 修复
        Text("支持作者").fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .height(56).padding({ left: 16, right: 16 })

      Column() {
        Text("如果觉得好用，\n请我喝杯柠檬水吧 🍋")
          .textAlign(TextAlign.Center).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#009688')

        Text("(长按图片可保存到相册)").fontSize(12).fontColor(Color.Gray).margin({ top: 10, bottom: 40 })

        Row({ space: 20 }) {
          // 微信
          Column() {
            Rect().width(140).height(140).fill('#E0E0E0').radius(12)
            Text("微信支付").fontSize(12).fontColor('#4CAF50').margin({ top: 10 }).backgroundColor('#E8F5E9').padding({ left: 10, right: 10, top: 4, bottom: 4 }).borderRadius(10)
          }
          .onClick(() => { try{ promptAction.showToast({ message: '长按保存' }); }catch(e){} })

          // 支付宝
          Column() {
            Rect().width(140).height(140).fill('#E0E0E0').radius(12)
            Text("支付宝").fontSize(12).fontColor('#2196F3').margin({ top: 10 }).backgroundColor('#E3F2FD').padding({ left: 10, right: 10, top: 4, bottom: 4 }).borderRadius(10)
          }
        }

        Blank().height(50)
        Text("感谢您的支持！❤️").fontColor(Color.Gray)
      }
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor(Color.White)
    .padding({ top: 10 })
  }
}