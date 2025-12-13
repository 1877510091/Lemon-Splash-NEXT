import router from '@ohos.router';

// ✅ 定义类
class MonthData {
  title: string;
  count: number;
  constructor(title: string, count: number) {
    this.title = title;
    this.count = count;
  }
}

@Entry
@Component
struct StatsPage {
  @State expandedIndex: number = -1;
  private months: MonthData[] = [
    new MonthData("2025-12", 120),
    new MonthData("2025-11", 350),
    new MonthData("2025-10", 0)
  ];

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24).fontColor(['#2E7D32']) // ✅ 修复数组
          .onClick(() => router.back())
        Text("学习足迹")
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#2E7D32')
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .height(56).width('100%').padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      if (this.months.length === 0) {
        Column() {
          Text("暂无记录，快去背个单词吧！").fontColor(Color.Gray)
        }
        .justifyContent(FlexAlign.Center).layoutWeight(1).width('100%')
      } else {
        List({ space: 10 }) {
          ForEach(this.months, (item: MonthData, index: number) => {
            ListItem() {
              Column() {
                Row() {
                  Stack() {
                    Circle({ width: 40, height: 40 }).fill('#F0F4C3')
                    SymbolGlyph($r('sys.symbol.calendar')).fontColor(['#827717']) // ✅ 修复数组
                  }.margin({ right: 16 })

                  Text(item.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#00695C')
                  Blank()
                  if (item.count > 0) {
                    Text(item.count + "词").fontSize(12).fontColor('#558B2F').backgroundColor('#F1F8E9').padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(8)
                  }

                  SymbolGlyph(this.expandedIndex === index ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
                    .fontSize(16).fontColor([Color.Gray]).margin({ left: 10 }) // ✅ 修复数组
                }
                .width('100%')
                .padding(16)
                .onClick(() => {
                  animateTo({ duration: 300 }, () => {
                    this.expandedIndex = this.expandedIndex === index ? -1 : index;
                  })
                })

                if (this.expandedIndex === index) {
                  Column() {
                    if (item.count > 0) {
                      Text("📈 每日学习趋势图").fontSize(12).fontColor('#009688').margin({ bottom: 10 })
                      Row({ space: 5 }) {
                        ForEach([20, 50, 30, 80, 40, 60, 20], (h: number) => {
                          Column().width(10).height(h).backgroundColor('#80CBC4').borderRadius(2)
                        })
                      }.alignItems(VerticalAlign.Bottom).height(100)
                    } else {
                      Text("本月无记录").fontSize(12).fontColor(Color.Gray)
                    }
                  }
                  .height(150)
                  .width('100%')
                  .backgroundColor('rgba(255,255,255,0.5)')
                  .justifyContent(FlexAlign.Center)
                  .margin({ bottom: 10 })
                }
              }
              .backgroundColor(Color.White)
              .borderRadius(16)
            }
          })
        }
        .layoutWeight(1)
        .padding(20)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F8E9')
    .padding({ top: 10 })
  }
}