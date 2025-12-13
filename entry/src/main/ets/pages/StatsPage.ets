import router from '@ohos.router';
import DatabaseHelper from '../model/DatabaseHelper';

class MonthData {
  title: string;
  count: number;
  year: number;
  month: number;
  dailyData: Map<number, number>;
  maxCount: number;

  constructor(year: number, month: number) {
    this.year = year;
    this.month = month;
    this.title = `${year}年${month}月`;
    this.count = 0;
    this.dailyData = new Map();
    this.maxCount = 10;
  }
}

@Entry
@Component
struct StatsPage {
  @State expandedIndex: number = 0;
  @State months: MonthData[] = [];
  @State isLoading: boolean = true;
  @State selectedDayInfo: string = '';

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;

    // 调用数据库新方法
    let monthStrs = await DatabaseHelper.getAllMonthsWithData();

    let result: MonthData[] = [];

    for (let mStr of monthStrs) {
      let parts = mStr.split('-');
      let year = parseInt(parts[0]);
      let month = parseInt(parts[1]);

      let monthObj = new MonthData(year, month);

      let dataMap = await DatabaseHelper.getMonthlyData(year, month);
      monthObj.dailyData = dataMap;

      let total = 0;
      let max = 5;
      dataMap.forEach((v) => {
        total += v;
        if (v > max) max = v;
      });

      monthObj.count = total;
      monthObj.maxCount = Math.ceil(max / 10) * 10;

      result.push(monthObj);
    }

    this.months = result;
    this.isLoading = false;
  }

  private getDaysArray(year: number, month: number): number[] {
    let daysInMonth = new Date(year, month, 0).getDate();
    let days: number[] = [];
    for (let i = 1; i <= daysInMonth; i++) {
      days.push(i);
    }
    return days;
  }

  // 返回 ArkTS Polyline 所需的坐标数组
  private getPolylinePoints(item: MonthData, chartHeight: number, barWidth: number, gap: number): Array<[number, number]> {
    let points: Array<[number, number]> = [];
    let days = this.getDaysArray(item.year, item.month);

    days.forEach((day, index) => {
      let val = item.dailyData.get(day) || 0;
      let x = index * (barWidth + gap) + (barWidth / 2);
      let ratio = val / item.maxCount;
      let y = chartHeight - (ratio * chartHeight);
      points.push([x, y]);
    });
    return points;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24).fontColor(['#2E7D32'])
          .onClick(() => router.back())
        Text("学习足迹")
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#2E7D32')
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .height(56).width('100%').padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      if (this.selectedDayInfo) {
        Text(this.selectedDayInfo)
          .fontSize(14).fontColor(Color.White).backgroundColor('#66BB6A')
          .padding({ left: 12, right: 12, top: 4, bottom: 4 }).borderRadius(12)
          .margin({ top: 10 })
          .animation({ duration: 300 })
      } else {
        Blank().height(28).margin({ top: 10 })
      }

      if (this.isLoading) {
        Text("加载全量数据...").margin({top: 20}).fontColor(Color.Gray)
      } else if (this.months.length === 0) {
        Text("暂无数据，快去背单词吧！").margin({top: 50}).fontColor(Color.Gray)
      } else {
        List({ space: 15 }) {
          ForEach(this.months, (item: MonthData, index: number) => {
            ListItem() {
              Column() {
                // 月份标题行
                Row() {
                  Stack() {
                    Circle({ width: 40, height: 40 }).fill('#F0F4C3')
                    SymbolGlyph($r('sys.symbol.calendar')).fontColor(['#827717'])
                  }.margin({ right: 16 })

                  Text(item.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#00695C')
                  Blank()
                  if (item.count > 0) {
                    Text(`共 ${item.count} 词`).fontSize(12).fontColor('#558B2F').backgroundColor('#F1F8E9').padding(6).borderRadius(8)
                  }

                  // ✅ 修复：将 Color.Gray 改为 Hex 字符串 '#9E9E9E'，避免类型报错
                  SymbolGlyph(this.expandedIndex === index ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
                    .fontSize(16).fontColor(['#9E9E9E']).margin({ left: 10 })
                }
                .width('100%')
                .padding(16)
                .onClick(() => {
                  animateTo({ duration: 300 }, () => {
                    this.expandedIndex = this.expandedIndex === index ? -1 : index;
                    this.selectedDayInfo = '';
                  })
                })

                if (this.expandedIndex === index) {
                  Row() {
                    // Y轴
                    Column() {
                      Text(item.maxCount.toFixed(0)).fontSize(10).fontColor(Color.Gray)
                      Blank()
                      Text((item.maxCount / 2).toFixed(0)).fontSize(10).fontColor(Color.Gray)
                      Blank()
                      Text("0").fontSize(10).fontColor(Color.Gray)
                    }
                    .height(150)
                    .width(30)
                    .alignItems(HorizontalAlign.End)
                    .padding({ right: 5, top: 0, bottom: 20 })
                    .border({ width: { right: 1 }, color: '#E0E0E0' })

                    // 图表区
                    Scroll() {
                      Stack({ alignContent: Alignment.TopStart }) {
                        // 柱状图
                        Row({ space: 10 }) {
                          ForEach(this.getDaysArray(item.year, item.month), (day: number) => {
                            Column() {
                              Column() {
                                if (item.dailyData.has(day)) {
                                  Column()
                                    .width(12)
                                    .height(`${(item.dailyData.get(day) || 0) / item.maxCount * 100}%`)
                                    .backgroundColor('#80CBC4')
                                    .borderRadius({ topLeft: 4, topRight: 4 })
                                } else {
                                  Column().width(12).height(1).backgroundColor('transparent')
                                }
                              }
                              .height(130)
                              .width(20)
                              .justifyContent(FlexAlign.End)
                              .alignItems(HorizontalAlign.Center)

                              Text(day.toString()).fontSize(10).fontColor(Color.Gray).margin({ top: 5 })
                            }
                            .onClick(() => {
                              let count = item.dailyData.get(day) || 0;
                              this.selectedDayInfo = `${item.month}月${day}日: 学习 ${count} 词`;
                            })
                          })
                        }
                        .padding({ left: 10, right: 10 })

                        // 折线图
                        Polyline()
                          .points(this.getPolylinePoints(item, 130, 12, 10))
                          .fill('none')
                          .stroke('#009688')
                          .strokeWidth(1.5)
                          .strokeOpacity(0.8)
                          .margin({ left: 10 })
                          .width('100%')
                          .height(130)
                          .hitTestBehavior(HitTestMode.None)
                      }
                      .height(150)
                    }
                    .scrollable(ScrollDirection.Horizontal)
                    .scrollBar(BarState.Off)
                    .layoutWeight(1)
                  }
                  .height(160)
                  .width('100%')
                  .backgroundColor('rgba(255,255,255,0.5)')
                  .padding(10)
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
    .padding({ top: 48 })
  }
}