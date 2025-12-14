
import router from '@ohos.router';
import DatabaseHelper from '../model/DatabaseHelper';

// ----------------------------------------------------
// MonthData 类定义 (保持不变)
// ----------------------------------------------------
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
    // 初始值应与 loadData 保持一致，避免零除或图表异常
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

  // 图表参数保持与Column/Row中的配置一致
  private readonly BAR_WIDTH: number = 20; // 柱状图宽度
  private readonly BAR_GAP: number = 10;  // Row的 space 属性
  private readonly CHART_HEIGHT: number = 130; // 柱状图/折线图主体高度

  // ⚠️ 新增：滚动控制器
  private scrollController: Scroller = new Scroller();

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;

    // 修复 TS/类型推断错误
    let monthStrs: string[] = await DatabaseHelper.getAllMonthsWithData();

    let result: MonthData[] = [];

    for (let mStr of monthStrs) {
      let parts = mStr.split('-');
      let year = parseInt(parts[0]);
      let month = parseInt(parts[1]);

      let monthObj = new MonthData(year, month);

      // 修复 TS/类型推断错误
      let dataMap: Map<number, number> = await DatabaseHelper.getMonthlyData(year, month);
      monthObj.dailyData = dataMap;

      let total = 0;
      let max = 5;
      dataMap.forEach((v: number) => { // 修复 TS/类型推断错误
        total += v;
        if (v > max) max = v;
      });

      monthObj.count = total;
      // 保证 MaxCount 是 10 的倍数向上取整
      monthObj.maxCount = Math.ceil(max / 10) * 10;
      if (monthObj.maxCount === 0) monthObj.maxCount = 10;

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

  private getPolylinePoints(item: MonthData): Array<[number, number]> {
    let points: Array<[number, number]> = [];
    let days = this.getDaysArray(item.year, item.month);

    const CELL_TOTAL_WIDTH = this.BAR_WIDTH + this.BAR_GAP;
    const CONTAINER_LEFT_PADDING = 10;

    days.forEach((day: number, index: number) => { // 修复 TS/类型推断错误
      let val = item.dailyData.get(day) || 0;

      // X 坐标：Row的左侧 padding + 之前所有单元格的总宽度 + 当前柱子宽度的一半
      let x = CONTAINER_LEFT_PADDING + (index * CELL_TOTAL_WIDTH) + (this.BAR_WIDTH / 2);

      let ratio = val / item.maxCount;
      // Y 坐标：从顶部开始计算，高度越低 Y 值越大
      let y = this.CHART_HEIGHT - (ratio * this.CHART_HEIGHT);

      points.push([x, y]);
    });
    return points;
  }

  // ⚠️ 新增：实现滚动到当前日期的方法
  private scrollToToday(item: MonthData): void {
    const currentDate = new Date();
    const currentYear = currentDate.getFullYear();
    const currentMonth = currentDate.getMonth() + 1;
    const currentDay = currentDate.getDate();

    // 仅在当前展开的月份是今天的月份时才滚动
    if (currentYear === item.year && currentMonth === item.month) {
      // 每一天占用的总宽度
      const CELL_TOTAL_WIDTH = this.BAR_WIDTH + this.BAR_GAP;
      // 计算滚动位置到当天柱子的左侧 X 坐标
      const dayPosition = (currentDay - 1) * CELL_TOTAL_WIDTH;

      // 使用延时确保 DOM 完成渲染
      setTimeout(() => {
        this.scrollController.scrollTo({
          xOffset: dayPosition - 100, // 减去100让当天居中或偏左显示
          yOffset: 0, // 保持 yOffset 为必需参数
          animation: {
            duration: 300
          }
        });
      }, 100);
    }
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
          // 修复 TS/类型推断错误
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
                  // ⚠️ 修复：在动画结束后调用滚动方法
                  if (this.expandedIndex === index) {
                    this.scrollToToday(item);
                  }
                })

                if (this.expandedIndex === index) {
                  Row() {
                    // Y轴
                    Column() {
                      Text(item.maxCount.toFixed(0)).fontSize(10).fontColor(Color.Gray)
                      Blank()
                      Text((item.maxCount / 2).toFixed(0)).fontSize(10).fontColor(Color.Gray)
                      Blank()
                      Text("0").fontSize(10).fontColor(Color.Gray).height(10)
                    }
                    .height(this.CHART_HEIGHT + 20)
                    .width(30)
                    .alignItems(HorizontalAlign.End)
                    .padding({ right: 5, top: 0, bottom: 10 })
                    .border({ width: { right: 1 }, color: '#E0E0E0' })

                    // 图表区
                    // ⚠️ 修复：关联 this.scrollController
                    Scroll(this.scrollController) {
                      Stack({ alignContent: Alignment.TopStart }) {
                        // 柱状图
                        Row({ space: this.BAR_GAP }) {
                          ForEach(this.getDaysArray(item.year, item.month), (day: number) => {
                            Column() {
                              // 柱子
                              Column() {
                                if (item.dailyData.has(day)) {
                                  Column()
                                    .width(this.BAR_WIDTH)
                                    .height(`${(item.dailyData.get(day) || 0) / item.maxCount * 100}%`)
                                    .backgroundColor('#80CBC4')
                                    .borderRadius({ topLeft: 4, topRight: 4 })
                                } else {
                                  Column().width(this.BAR_WIDTH).height(1).backgroundColor('transparent')
                                }
                              }
                              .height(this.CHART_HEIGHT)
                              .width(this.BAR_WIDTH)
                              .justifyContent(FlexAlign.End)
                              .alignItems(HorizontalAlign.Center)

                              // 日期数字
                              Text(day.toString()).fontSize(10).fontColor(Color.Gray).margin({ top: 5 })
                                .height(15)
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
                          .points(this.getPolylinePoints(item))
                          .fill('none')
                          .stroke('#009688')
                          .strokeWidth(1.5)
                          .strokeOpacity(0.8)
                          .margin({ left: 0 })
                          .width('100%')
                          .height(this.CHART_HEIGHT)
                          .hitTestBehavior(HitTestMode.None)
                      }
                      // 关键修复 1：将 Stack 的总高度增加 10vp，给数字留出更多绘制空间
                      .height(this.CHART_HEIGHT + 30)
                      // 关键修复 2：增加 Scroll 容器底部的内边距
                      .padding({ bottom: 20 })
                    }
                    .scrollable(ScrollDirection.Horizontal)
                    .scrollBar(BarState.Off)
                    .layoutWeight(1)
                  }
                  // 关键修复 3：增加外部 Row 的总高度，确保 Row 有足够的空间容纳 Scroll 的新高度
                  .height(this.CHART_HEIGHT + 40)
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