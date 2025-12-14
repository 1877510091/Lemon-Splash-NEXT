import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import DatabaseHelper from '../model/DatabaseHelper';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State todayCount: number = 0;
  @State isDevMode: boolean = false;

  // 用于双击退出计时
  private lastBackTime: number = 0;

  private controller: TabsController = new TabsController();

  // ----------------------------------------------------
  // ✅ 【修改： aboutToAppear】 确保设置了默认词库或空值引导
  // ----------------------------------------------------
  async aboutToAppear() {
    await DatabaseHelper.init(getContext(this) as common.UIAbilityContext);

    // 1. 获取上次使用的词库
    let currentBookName: string | null = await DatabaseHelper.getLastBook();

    // 2. 如果上次使用的词库不存在 (包括首次启动)
    if (!currentBookName) {
      // 3. 尝试获取第一个默认词库
      const defaultBook = await DatabaseHelper.getFirstBook();

      if (defaultBook) {
        // 如果数据库有词库，则设置为默认
        currentBookName = defaultBook;
      } else {
        // 🚨 关键：如果数据库中没有任何词库，设置一个特定的空值引导用户选择
        currentBookName = 'NO_BOOK_SELECTED';
      }
    }

    // 4. 将最终确定的值设置到 AppStorage
    AppStorage.SetOrCreate('currentBook', currentBookName);

    this.refreshData();
  }
  // ----------------------------------------------------
  // ✅ 【修改结束】
  // ----------------------------------------------------

  onPageShow() {
    this.refreshData();
  }

  onPageHide() {
    this.isDevMode = false;
  }

  onBackPress() {
    let now = Date.now();
    if (this.lastBackTime == 0 || (now - this.lastBackTime > 2000)) {
      this.lastBackTime = now;
      promptAction.showToast({ message: '再按一次退出应用', duration: 1500 });
      return true;
    }
    return false;
  }

  async refreshData() {
    const count = await DatabaseHelper.getTodayCount();
    this.todayCount = count;
  }

  build() {
    Stack() {
      // 1. 背景图
      Image($r('app.media.bg'))
        .width('100%').height('100%').objectFit(ImageFit.Cover)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // 2. 渐变遮罩
      Column()
        .width('100%').height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['rgba(255, 255, 255, 0.8)', 0.0], ['rgba(255, 255, 255, 0.4)', 1.0]]
        })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .hitTestBehavior(HitTestMode.None)

      // 3. 标签页
      Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
        TabContent() {
          HomePageContent({ todayCount: this.todayCount })
        }
        .tabBar(this.TabBuilder("学习", 0, $r('sys.symbol.circle_grid_2x2')))

        TabContent() {
          SettingsPageContent({ isDevMode: $isDevMode })
        }
        .tabBar(this.TabBuilder("我的", 1, $r('sys.symbol.person')))
      }
      .scrollable(false)
      .barHeight(60)
      .barBackgroundColor(this.currentIndex === 0 ? 'rgba(255, 255, 255, 0.6)' : Color.White)
      .barBackgroundEffect(this.currentIndex === 0 ? { radius: 20, saturation: 1.2 } : { radius: 0, saturation: 1.0 })
      .backgroundColor(Color.Transparent)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .onChange((index) => {
        this.currentIndex = index;
        if (index === 0) {
          this.refreshData();
        }
        if (index !== 1) {
          this.isDevMode = false;
        }
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
    .justifyContent(FlexAlign.Center).width('100%').height('100%')
    .onClick(() => {
      this.currentIndex = index;
      this.controller.changeIndex(index);
    })
  }
}

// ======================= 首页内容 =======================
@Component
struct HomePageContent {
  @StorageProp('currentBook') currentBook: string = "请选择词库"; // ⬅️ 提示用户选择
  @Prop todayCount: number;

  build() {
    Column() {
      // 顶部留白
      Blank().height(48)

      // Header
      Row() {
        SymbolGlyph($r('sys.symbol.leaf'))
          .fontSize(28).fontColor(['#9E9D24']).margin({ right: 10 })

        Column() {
          Text("Lemon").fontSize(24).fontWeight(FontWeight.Bold).fontColor('#00695C').fontFamily('Georgia').height(24)
          Text("Splash").fontSize(24).fontWeight(FontWeight.Bold).fontColor('#00695C').fontFamily('Georgia').height(24)
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Stack() {
          Circle({ width: 38, height: 38 }).fill(Color.Transparent).strokeWidth(2).stroke(Color.Green)
          Circle({ width: 34, height: 34 }).fill(Color.White)
          SymbolGlyph($r('sys.symbol.person')).fontSize(20).fontColor(['#9E9E9E'])
        }
      }
      .width('100%').padding({ top: 10, bottom: 10 })

      Blank().height(60)

      // 正在学习卡片 (点击跳转到词库库页面)
      LemonGlassCard({
        title: "正在学习",
        // 🚨 检查是否是空值，如果是则显示提示
        value: this.currentBook === 'NO_BOOK_SELECTED' ? '请选择词库' : this.currentBook,
        sysIcon: $r('sys.symbol.book'),
        themeColor: '#00BCD4',
        textColor: '#006064'
      })
        .onClick(() => { try { router.pushUrl({ url: 'pages/BookLibraryPage' }) } catch(e) {} })

      Blank().height(20)

      // 今日学习卡片
      LemonGlassCard({
        title: "今日学习",
        value: this.todayCount + " 个单词",
        sysIcon: $r('sys.symbol.drop'),
        themeColor: '#CDDC39',
        textColor: '#827717'
      })
        .onClick(() => { try { router.pushUrl({ url: 'pages/StatsPage' }) } catch(e) {} })

      Blank().layoutWeight(1)

      Row() {
        SymbolGlyph($r('sys.symbol.play')).fontSize(36).fontColor(['#00695C']).margin({ right: 10 })
        Text("开始学习").fontSize(22).fontWeight(900).fontColor('#00695C')
      }
      .width('100%').height(70).justifyContent(FlexAlign.Center)
      .linearGradient({ angle: 135, colors: [['#FFF176', 0.0], ['#DCE775', 1.0]] })
      .backgroundColor('#FFEE58').borderRadius(35)
      .shadow({ radius: 20, color: 'rgba(251, 192, 45, 0.4)', offsetY: 10 })
      // ----------------------------------------------------
      // ✅ 【修改： onClick】 添加词库空值判断
      // ----------------------------------------------------
      .onClick(() => {
        try {
          const currentBook = AppStorage.Get<string>('currentBook');

          if (currentBook && currentBook !== 'NO_BOOK_SELECTED') {
            // 状态正常，跳转到学习页面
            router.pushUrl({ url: 'pages/WordLearningPage' });
          } else {
            // 没有词库，强制跳转到词库选择页面并提示
            promptAction.showToast({ message: '请先选择或导入词库', duration: 1500 });
            router.pushUrl({ url: 'pages/BookLibraryPage' });
          }
        } catch(e) {
          console.error('Start learning click error:', JSON.stringify(e));
        }
      })
      // ----------------------------------------------------
      // ✅ 【修改结束】
      // ----------------------------------------------------

      Blank().height(20)

      Row({ space: 15 }) {
        SecondaryButton({ text: "智能复习", sysIcon: $r('sys.symbol.arrow_clockwise'), themeColor: '#2196F3' })
          .layoutWeight(1)
          .onClick(() => { try { router.pushUrl({ url: 'pages/ReviewPage' }) } catch(e) {} })

        SecondaryButton({ text: "错题本", sysIcon: $r('sys.symbol.doc'), themeColor: '#FF9800' })
          .layoutWeight(1)
          .onClick(() => { try { router.pushUrl({ url: 'pages/MistakeBookPage' }) } catch(e) {} })
      }
      .width('100%')

      Blank().height(30)
    }
    .width('100%').height('100%').padding({ left: 24, right: 24 }).backgroundColor(Color.Transparent)
  }
}

// ======================= 设置页内容 =======================
@Component
struct SettingsPageContent {
  @State clickCount: number = 0;
  // ✅ 修复：补全缺失的变量
  @State firstClickTime: number = 0;
  @Link isDevMode: boolean;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: DeveloperDialog({}),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  handleVersionClick() {
    let now = Date.now();
    if (this.clickCount === 0) {
      this.clickCount = 1;
      this.firstClickTime = now;
    } else {
      if (now - this.firstClickTime > 1500) {
        this.clickCount = 1;
        this.firstClickTime = now;
      } else {
        this.clickCount++;
      }
    }

    if (this.clickCount >= 5) {
      this.clickCount = 0;
      if (!this.isDevMode) {
        promptAction.showToast({ message: '🚀 开发者模式已激活！' });
        this.isDevMode = true;
      }
    } else if (this.clickCount > 2) {
      promptAction.showToast
    }
  }

  build() {
    Column() {
      Row() {
        Text("设置").fontSize(20).fontWeight(FontWeight.Bold).fontColor('#2E7D32')
      }
      .width('100%').height(56).justifyContent(FlexAlign.Center).backgroundColor(Color.White)

      List() {
        ListItem() { SettingsItem({ sysIcon: $r('sys.symbol.book'), iconColor: '#2196F3', title: "软件信息", subtitle: "柠檬单词 Lemon-Splash" }) }
        ListItem() { SettingsItem({ sysIcon: $r('sys.symbol.person'), iconColor: '#FF9800', title: "作者", subtitle: "已关闭" }) }
        ListItem() {
          SettingsItem({ sysIcon: $r('sys.symbol.download'), iconColor: '#009688', title: "更新地址", subtitle: "GitHub/Lemon-Splash (HarmonyOS请在应用商店更新)", isLink: true })
        }
        ListItem() {
          Row() {
            SymbolGlyph($r('sys.symbol.heart')).fontSize(24).fontColor(['#E91E63']).margin({ right: 16 })
            Column() {
              Text("赞赏作者").fontSize(16).fontWeight(FontWeight.Bold).fontColor('#E91E63')
              Text("请我喝杯柠檬水 🍋").fontSize(12).fontColor(Color.Gray)
            }
            .alignItems(HorizontalAlign.Start).layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor(['#BDBDBD'])
          }
          .padding({ left: 16, right: 16, top: 16, bottom: 16 }).width('100%').backgroundColor(Color.White)
          .onClick(() => { try { router.pushUrl({ url: 'pages/DonationPage' }) } catch(e) {} })
        }
        ListItem() { Divider().color('#8FBC8F').strokeWidth(0.5) }

        // 版本号
        ListItem() {
          SettingsItem({ sysIcon: $r('sys.symbol.checkmark'), iconColor: '#9C27B0', title: "版本号", subtitle: "v1.3.0 NEXT适配版" })
        }
        .onClick(() => {
          this.handleVersionClick();
        })

        // 开发者模式按钮
        if (this.isDevMode) {
          ListItem() {
            Row() {
              Blank()

              Row() {
                SymbolGlyph($r('sys.symbol.gearshape_fill'))
                  .fontSize(12).fontColor(['#D32F2F']).margin({ right: 4 })
                Text("修改数据")
                  .fontSize(12).fontWeight(FontWeight.Bold).fontColor('#D32F2F')
              }
              .padding({ top: 6, bottom: 6, left: 12, right: 12 })
              .backgroundColor('#FFEBEE')
              .borderRadius(14)
              .onClick(() => {
                this.dialogController.open();
              })
            }
            .width('100%')
            .padding({ right: 16, bottom: 10 })
            .backgroundColor(Color.White)
          }
        }
      }
      .width('100%').layoutWeight(1).backgroundColor(Color.White)
    }
    .width('100%').height('100%').backgroundColor(Color.White).padding({ top: 48 })
  }
}

// 开发者模式弹窗
@CustomDialog
struct DeveloperDialog {
  controller: CustomDialogController;
  @State dateStr: string = '';
  @State countStr: string = '';

  aboutToAppear() {
    const now = new Date();
    const y = now.getFullYear();
    const m = (now.getMonth() + 1).toString().padStart(2, '0');
    const d = now.getDate().toString().padStart(2, '0');
    this.dateStr = `${y}-${m}-${d}`;
  }

  build() {
    Column() {
      Text("修改数据 (Developer)").fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 20 })
      TextInput({ placeholder: '日期 YYYY-MM-DD', text: this.dateStr }).onChange((val) => { this.dateStr = val; }).margin({ bottom: 10 }).height(50).backgroundColor('#F5F5F5').borderRadius(8)
      TextInput({ placeholder: '数量', text: this.countStr }).type(InputType.Number).onChange((val) => { this.countStr = val; }).margin({ bottom: 20 }).height(50).backgroundColor('#F5F5F5').borderRadius(8)
      Row({ space: 20 }) {
        Button("取消").backgroundColor('#CFD8DC').fontColor(Color.Black).onClick(() => { this.controller.close(); }).layoutWeight(1)
        Button("确定").backgroundColor('#009688').onClick(async () => {
          if (this.dateStr && this.countStr) {
            await DatabaseHelper.setDailyCount(this.dateStr, parseInt(this.countStr));
            promptAction.showToast({ message: '✅ 修改成功' });
            this.controller.close();
          } else {
            promptAction.showToast({ message: '请输入完整信息' });
          }
        }).layoutWeight(1)
      }.width('100%')
    }
    .padding(24).width('80%').backgroundColor(Color.White).borderRadius(16).shadow({ radius: 20, color: 'rgba(0,0,0,0.2)' })
  }
}

// ======================= 通用组件 =======================
@Component
struct LemonGlassCard {
  @Prop title: string;
  @Prop value: string;
  @Prop sysIcon: Resource;
  @Prop themeColor: string;
  @Prop textColor: string;
  build() {
    Stack() {
      Rect().fill('rgba(255, 255, 255, 0.55)').width('100%').height('100%')
      Row() {
        Stack() {
          Circle({ width: 50, height: 50 }).fill(this.themeColor).opacity(0.1)
          SymbolGlyph(this.sysIcon).fontSize(28).fontColor([this.themeColor])
        }
        .margin({ right: 20 })
        Column() {
          Text(this.title).fontSize(14).fontColor('#424242').margin({ bottom: 4 })
          Text(this.value).fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.textColor).fontFamily('Georgia')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([this.textColor])
          .opacity(0.4)
      }
      .width('100%').padding({ left: 24, right: 24 })
    }
    .width('100%').height(90).borderRadius(24).clip(true).backdropBlur(10).shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetY: 5 })
  }
}

@Component
struct SecondaryButton {
  @Prop text: string;
  @Prop sysIcon: Resource;
  @Prop themeColor: string;
  build() {
    Row() {
      SymbolGlyph(this.sysIcon).fontSize(22).fontColor([this.themeColor]).margin({ right: 8 })
      Text(this.text).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.themeColor)
    }
    .justifyContent(FlexAlign.Center).height(60).width('100%').backgroundColor('rgba(255, 255, 255, 0.8)').borderRadius(20).shadow({ radius: 10, color: 'rgba(158, 158, 158, 0.1)', offsetY: 5 })
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
      SymbolGlyph(this.sysIcon).fontSize(24).fontColor([this.iconColor]).margin({ right: 16 })
      Column() {
        Text(this.title).fontSize(16).fontWeight(FontWeight.Medium)
        Text(this.subtitle).fontSize(12).fontColor(this.isLink ? '#2196F3' : Color.Gray)
          .decoration({ type: this.isLink ? TextDecorationType.Underline : TextDecorationType.None, color: '#2196F3' })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .padding({ left: 16, right: 16, top: 16, bottom: 16 }).width('100%').backgroundColor(Color.White)
  }
}