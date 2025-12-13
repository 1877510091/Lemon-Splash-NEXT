import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

// ✅ 1. 定义明确的类，解决 "no-any" 错误
class BookItem {
  title: string;
  sub: string;
  file: string;
  color: string;

  constructor(title: string, sub: string, file: string, color: string) {
    this.title = title;
    this.sub = sub;
    this.file = file;
    this.color = color;
  }
}

@Entry
@Component
struct BookLibraryPage {
  // ✅ 2. 使用 Hex 颜色替换 Color.Teal 等非法值
  private books: BookItem[] = [
    new BookItem("四级词汇", "CET-4", "3-CET4-顺序.json", '#009688'),
    new BookItem("六级词汇", "CET-6", "4-CET6-顺序.json", '#3F51B5'),
    new BookItem("考研英语", "Postgraduate", "5-考研-顺序.json", '#FF5722'),
    new BookItem("雅思核心", "IELTS", "雅思真经.json", '#2196F3'),
    new BookItem("托福词汇", "TOEFL", "6-托福-顺序.json", '#9C27B0'),
    new BookItem("小学英语", "Grade 1-6", "小学英语1-6年级.json", '#4CAF50'),
    new BookItem("初中英语", "Junior High", "1-初中-顺序.json", '#8BC34A'),
    new BookItem("高中英语", "Senior High", "2-高中-顺序.json", '#CDDC39'),
    new BookItem("专业四级", "TEM-4", "专四.json", '#795548'),
    new BookItem("专业八级", "TEM-8", "专八.json", '#F44336'),
    new BookItem("SAT词汇", "SAT", "7-SAT-顺序.json", '#FFC107'),
    new BookItem("BEC商务", "Business", "BEC商务英语.json", '#607D8B'),
  ];

  dialogController: CustomDialogController = new CustomDialogController({
    builder: ModeSelectDialog({
      confirm: (isShuffle: boolean) => {
        AppStorage.SetOrCreate('currentBook', '新词书');
        try {
          promptAction.showToast({ message: isShuffle ? '已开启乱序模式' : '已开启顺序模式' });
        } catch (e) {}
        router.back();
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  build() {
    Stack() {
      Image($r('app.media.bg')).width('100%').height('100%').objectFit(ImageFit.Cover)

      Column().width('100%').height('100%')
        .linearGradient({ direction: GradientDirection.Bottom, colors: [['rgba(255,255,255,0.9)', 0], ['rgba(255,255,255,0.6)', 1]] })

      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24).fontColor(['#00695C']) // ✅ 修复：fontColor 必须是数组 []
            .onClick(() => router.back())
          Text("柠檬图书馆")
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#00695C')
            .layoutWeight(1).textAlign(TextAlign.Center)
          Blank().width(24)
        }
        .height(56).width('100%').padding({ left: 16, right: 16 })

        List({ space: 15 }) {
          ForEach(this.books, (item: BookItem) => {
            ListItem() {
              Row() {
                Stack() {
                  Rect().width(40).height(40).radius(12).fill(item.color).opacity(0.1)
                  // ✅ 修复：fontColor 必须是数组
                  SymbolGlyph($r('sys.symbol.book')).fontSize(20).fontColor([item.color])
                }
                .margin({ right: 16 })

                Column() {
                  Text(item.title).fontSize(18).fontWeight(FontWeight.Bold)
                  Text(item.sub).fontSize(14).fontColor(Color.Gray)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([Color.Gray]) // ✅ 修复数组
              }
              .padding(16)
              .width('100%')
              .backgroundColor(Color.White)
              .borderRadius(20)
              .onClick(() => {
                this.dialogController.open();
              })
            }
          })
        }
        .layoutWeight(1)
        .padding(20)
      }
      .width('100%').height('100%')
      .padding({ top: 10 })
    }
  }
}

@CustomDialog
struct ModeSelectDialog {
  controller: CustomDialogController;
  confirm: (isShuffle: boolean) => void = () => {};

  build() {
    Column() {
      Text("正在开启新词库").fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 10 })
      Text("请选择学习顺序：\n⚠️ 切换词库会重置该书的进度。")
        .fontSize(14).fontColor(Color.Gray).textAlign(TextAlign.Center).margin({ bottom: 20 })

      Row({ space: 10 }) {
        Button("顺序模式")
          .backgroundColor(Color.White)
          .fontColor('#009688')
          .border({ width: 1, color: '#009688' })
          .onClick(() => { this.controller.close(); this.confirm(false); })
          .layoutWeight(1)

        Button("乱序模式")
          .backgroundColor('#009688')
          .fontColor(Color.White)
          .onClick(() => { this.controller.close(); this.confirm(true); })
          .layoutWeight(1)
      }
      .width('100%')
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .width('80%')
  }
}