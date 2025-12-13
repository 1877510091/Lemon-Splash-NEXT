import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  private controller: TabsController = new TabsController();

  build() {
    Stack() {
      // 1. 全局背景图 (仅在学习页生效，设置页会被白色遮挡)
      Image($r('app.media.bg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // 2. 全局渐变遮罩
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['rgba(255, 255, 255, 0.8)', 0.0],
            ['rgba(255, 255, 255, 0.4)', 1.0]
          ]
        })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .hitTestBehavior(HitTestMode.None)

      // 3. Tabs 内容
      Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
        // ================= Tab 1: 学习 =================
        TabContent() {
          HomePageContent()
        }
        .tabBar(this.TabBuilder("学习", 0, $r('sys.symbol.circle_grid_2x2')))

        // ================= Tab 2: 我的 =================
        TabContent() {
          SettingsPageContent()
        }
        .tabBar(this.TabBuilder("我的", 1, $r('sys.symbol.person')))
      }
      .scrollable(false)
      .barHeight(60)

      // ✅ 动态底栏背景色：学习页透明度0.6，设置页纯白
      .barBackgroundColor(this.currentIndex === 0 ? 'rgba(255, 255, 255, 0.6)' : Color.White)

      // ✅ 动态毛玻璃：学习页开启，设置页关闭
      .barBackgroundEffect(this.currentIndex === 0 ? { radius: 20, saturation: 1.2 } : { radius: 0, saturation: 1.0 })

      .backgroundColor(Color.Transparent)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .onChange((index) => {
        this.currentIndex = index
      })
    }
  }

  @Builder TabBuilder(title: string, index: number, iconResource: Resource) {
    Column() {
      SymbolGlyph(iconResource)
        .fontSize(24)
        .fontColor([this.currentIndex === index ? '#9E9D24' : '#BDBDBD'])
        .margin({ bottom: 4 })

      Text(title)
        .fontSize(10)
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentIndex === index ? '#9E9D24' : '#BDBDBD')
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }
}

// ======================= 首页内容 =======================
@Component
struct HomePageContent {
  @State currentBook: string = "四级词汇";
  @State todayCount: number = 0;

  build() {
    Column() {
      // --- 顶部 Header ---
      Blank().height(45)
      Row() {
        SymbolGlyph($r('sys.symbol.leaf'))
          .fontSize(28)
          .fontColor(['#9E9D24'])
          .margin({ right: 10 })

        Column() {
          Text("Lemon")
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00695C')
            .fontFamily('Georgia')
            .height(24)
          Text("Splash")
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00695C')
            .fontFamily('Georgia')
            .height(24)
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Stack() {
          Circle({ width: 38, height: 38 })
            .fill(Color.Transparent)
            .strokeWidth(2)
            .stroke(Color.Green)

          Circle({ width: 34, height: 34 })
            .fill(Color.White)

          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(20)
            .fontColor(['#9E9E9E'])
        }
        .onClick(() => {
          try {
            promptAction.showToast({ message: '🚧 前方正在施工，暂不开放' });
          } catch (e) {}
        })
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })

      Blank().height(75)

      // --- 正在学习卡片 ---
      LemonGlassCard({
        title: "正在学习",
        value: this.currentBook,
        sysIcon: $r('sys.symbol.book'),
        themeColor: '#00BCD4',
        textColor: '#006064'
      })
        .onClick(() => {
          // router.pushUrl({ url: 'pages/BookLibraryPage' })
        })

      Blank().height(20)

      // --- 今日学习卡片 ---
      LemonGlassCard({
        title: "今日学习",
        value: this.todayCount + " 个单词",
        sysIcon: $r('sys.symbol.drop'),
        themeColor: '#CDDC39',
        textColor: '#827717'
      })
        .onClick(() => {
          // router.pushUrl({ url: 'pages/StatsPage' })
        })

      Blank().layoutWeight(1)

      // --- 开始学习按钮 ---
      Row() {
        SymbolGlyph($r('sys.symbol.play'))
          .fontSize(36)
          .fontColor(['#00695C'])
          .margin({ right: 10 })
        Text("开始学习")
          .fontSize(22)
          .fontWeight(900)
          .fontColor('#00695C')
      }
      .width('100%')
      .height(70)
      .justifyContent(FlexAlign.Center)
      .linearGradient({
        angle: 135,
        colors: [
          ['#FFF176', 0.0],
          ['#DCE775', 1.0]
        ]
      })
      .backgroundColor('#FFEE58')
      .borderRadius(35)
      .shadow({ radius: 20, color: 'rgba(251, 192, 45, 0.4)', offsetY: 10 })
      .onClick(() => {
        // router.pushUrl({ url: 'pages/WordLearningPage' });
      })

      Blank().height(20)

      // --- 底部双按钮 ---
      Row({ space: 15 }) {
        SecondaryButton({
          text: "智能复习",
          sysIcon: $r('sys.symbol.arrow_clockwise'),
          themeColor: '#2196F3'
        })
          .layoutWeight(1)
          .onClick(() => {
            // router.pushUrl({ url: 'pages/ReviewPage' })
          })

        SecondaryButton({
          text: "错题本",
          sysIcon: $r('sys.symbol.doc'),
          themeColor: '#FF9800'
        })
          .layoutWeight(1)
          .onClick(() => {
            // router.pushUrl({ url: 'pages/MistakeBookPage' })
          })
      }
      .width('100%')

      Blank().height(30)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24 })
    .backgroundColor(Color.Transparent)
  }
}

// ======================= 设置页面 =======================
@Component
struct SettingsPageContent {
  build() {
    Column() {
      // AppBar
      Row() {
        Text("设置")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2E7D32')
      }
      .width('100%')
      .height(56) // ✅ 核心修改：高度从100减小到56，拉近下方列表
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Color.White)

      List() {
        ListItem() {
          SettingsItem({ sysIcon: $r('sys.symbol.book'), iconColor: '#2196F3', title: "软件信息", subtitle: "柠檬单词 Lemon-Splash" })
        }

        ListItem() {
          SettingsItem({ sysIcon: $r('sys.symbol.person'), iconColor: '#FF9800', title: "作者", subtitle: "QQ: 187510091" })
        }

        ListItem() {
          SettingsItem({ sysIcon: $r('sys.symbol.download'), iconColor: '#009688', title: "更新地址", subtitle: "GitHub/Lemon-Splash (HarmonyOS请在应用商店更新)", isLink: true })
        }

        ListItem() {
          Row() {
            SymbolGlyph($r('sys.symbol.heart'))
              .fontSize(24)
              .fontColor(['#E91E63'])
              .margin({ right: 16 })

            Column() {
              Text("赞赏作者")
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E91E63')
              Text("请我喝杯柠檬水 🍋")
                .fontSize(12)
                .fontColor(Color.Gray)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(16)
              .fontColor(['#BDBDBD'])
          }
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .width('100%')
          .backgroundColor(Color.White)
        }

        ListItem() {
          Divider()
            .color('#8FBC8F')
            .strokeWidth(0.5)
        }

        ListItem() {
          SettingsItem({ sysIcon: $r('sys.symbol.checkmark'), iconColor: '#9C27B0', title: "版本号", subtitle: "v1.3 NEXT适配版" })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .padding({ top: 32 }) // ✅ 核心修改：顶部填充从10增加到32，保持标题位置视觉不变，但列表上移
  }
}

// ======================= 组件封装 =======================

@Component
struct LemonGlassCard {
  @Prop title: string;
  @Prop value: string;
  @Prop sysIcon: Resource;
  @Prop themeColor: string;
  @Prop textColor: string;

  build() {
    Stack() {
      Rect()
        .fill('rgba(255, 255, 255, 0.55)')
        .width('100%')
        .height('100%')

      Row() {
        Stack() {
          Circle({ width: 50, height: 50 })
            .fill(this.themeColor)
            .opacity(0.1)

          SymbolGlyph(this.sysIcon)
            .fontSize(28)
            .fontColor([this.themeColor])
        }
        .margin({ right: 20 })

        Column() {
          Text(this.title)
            .fontSize(14)
            .fontColor('#424242')
            .margin({ bottom: 4 })
          Text(this.value)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textColor)
            .fontFamily('Georgia')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(18)
          .fontColor(['#E0E0E0'])
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
    }
    .width('100%')
    .height(90)
    .borderRadius(24)
    .clip(true)
    .backdropBlur(10)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 5 })
  }
}

@Component
struct SecondaryButton {
  @Prop text: string;
  @Prop sysIcon: Resource;
  @Prop themeColor: string;

  build() {
    Row() {
      SymbolGlyph(this.sysIcon)
        .fontSize(22)
        .fontColor([this.themeColor])
        .margin({ right: 8 })

      Text(this.text)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColor)
    }
    .justifyContent(FlexAlign.Center)
    .height(60)
    .width('100%')
    .backgroundColor('rgba(255, 255, 255, 0.8)')
    .borderRadius(20)
    .shadow({ radius: 10, color: 'rgba(158, 158, 158, 0.1)', offsetY: 5 })
  }
}

@Component
struct SettingsItem {
  @Prop sysIcon: Resource;
  @Prop iconColor: string;
  @Prop title: string;
  @Prop subtitle: string;
  @Prop isLink: boolean = false;

  build() {
    Row() {
      SymbolGlyph(this.sysIcon)
        .fontSize(24)
        .fontColor([this.iconColor])
        .margin({ right: 16 })

      Column() {
        Text(this.title).fontSize(16).fontWeight(FontWeight.Medium)
        Text(this.subtitle)
          .fontSize(12)
          .fontColor(this.isLink ? '#2196F3' : Color.Gray)
          .decoration({ type: this.isLink ? TextDecorationType.Underline : TextDecorationType.None, color: '#2196F3' })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .width('100%')
    .backgroundColor(Color.White)
  }
}