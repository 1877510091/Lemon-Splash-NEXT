import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import DatabaseHelper from '../model/DatabaseHelper';

// 定义数据结构
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
  // 定义词库列表
  // ⚠️ 请再次确认这里的 file 字段和 rawfile 里的文件名完全一致！
  private books: BookItem[] = [
    new BookItem("四级词汇", "CET-4", "3-CET4-顺序.json", '#009688'),
    new BookItem("六级词汇", "CET-6", "4-CET6-顺序.json", '#3F51B5'),
    new BookItem("考研英语", "Postgraduate", "5-考研-顺序.json", '#FF5722'), // index 2
    new BookItem("雅思核心", "IELTS", "雅思真经.json", '#2196F3'),
    new BookItem("托福词汇", "TOEFL", "6-托福-顺序.json", '#9C27B0'), // index 4
    new BookItem("小学英语", "Grade 1-6", "小学英语1-6年级.json", '#4CAF50'),
    new BookItem("初中英语", "Junior High", "1-初中-顺序.json", '#8BC34A'),
    new BookItem("高中英语", "Senior High", "2-高中-顺序.json", '#CDDC39'), // index 7
    new BookItem("专业四级", "TEM-4", "专四.json", '#795548'),
    new BookItem("专业八级", "TEM-8", "专八.json", '#F44336'), // index 9
    new BookItem("SAT词汇", "SAT", "7-SAT-顺序.json", '#FFC107'),
    new BookItem("BEC商务", "Business", "BEC商务英语.json", '#607D8B'),
  ];

  @State selectedBookName: string = '';
  @State selectedBookFile: string = '';

  dialogController: CustomDialogController = new CustomDialogController({
    builder: ModeSelectDialog({
      bookName: this.selectedBookName,
      confirm: async (isShuffle: boolean) => {
        // 先关闭选择弹窗
        this.dialogController.close();

        try {
          promptAction.showToast({ message: `正在导入 ${this.selectedBookName}...` });

          // ✅ 核心修改：接收返回的结果对象
          let result = await DatabaseHelper.importJsonData(this.selectedBookFile, this.selectedBookName, isShuffle);

          if (result.success) {
            // ✅ 成功：显示数量并跳转
            promptAction.showToast({ message: `✅ 导入成功！共 ${result.count} 词` });
            AppStorage.SetOrCreate('currentBook', this.selectedBookName);
            router.back();
          } else {
            // ❌ 失败：弹窗显示具体原因，方便排查
            AlertDialog.show({
              title: '导入失败',
              message: `原因：${result.message}\n\n请检查 rawfile 目录下是否存在文件：\n${this.selectedBookFile}`,
              confirm: {
                value: '知道了',
                action: () => {}
              }
            });
          }
        } catch (e) {
          promptAction.showToast({ message: '❌ 未知异常' });
        }
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  // ✅ 新增：定义虚线分割线组件
  @Builder DashedSeparator() {
    Column() {
      // 上方间距，比普通间距稍大，增加距离感
      Blank().height(20)
      // 虚线本体
      Line()
        .width('92%') // 略微缩进，不顶到头
        .height(1)
        .startPoint([0, 0])
        .endPoint(['100%', 0])
        .stroke(Color.Gray) // 使用灰色，保持界面统一和谐
        .strokeWidth(1)
        .strokeDashArray([6, 4]) // 实线6，空白4的虚线效果
        .opacity(0.4) // 半透明，视觉上更轻盈
      // 下方间距
      Blank().height(20)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Stack() {
      Image($r('app.media.bg')).width('100%').height('100%').objectFit(ImageFit.Cover)

      Column().width('100%').height('100%')
        .linearGradient({ direction: GradientDirection.Bottom, colors: [['rgba(255,255,255,0.9)', 0], ['rgba(255,255,255,0.6)', 1]] })

      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24).fontColor(['#00695C'])
            .onClick(() => router.back())
          Text("柠檬图书馆")
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#00695C')
            .layoutWeight(1).textAlign(TextAlign.Center)
          Blank().width(24)
        }
        .height(56).width('100%').padding({ left: 16, right: 16 })

        // ✅ 修改：List 的 space 改为 0，由内部手动控制间距
        List({ space: 0 }) {
          // ✅ 修改：引入 index 用于判断位置
          ForEach(this.books, (item: BookItem, index: number) => {
            ListItem() {
              // ✅ 修改：用 Column 包裹，以便在卡片下方放置分割线或普通间距
              Column() {
                // 原有的卡片 Row，保持不变
                Row() {
                  Stack() {
                    Rect().width(40).height(40).radius(12).fill(item.color).opacity(0.1)
                    SymbolGlyph($r('sys.symbol.book')).fontSize(20).fontColor([item.color])
                  }
                  .margin({ right: 16 })

                  Column() {
                    Text(item.title).fontSize(18).fontWeight(FontWeight.Bold)
                    Text(item.sub).fontSize(14).fontColor(Color.Gray)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([Color.Gray])
                }
                .padding(16)
                .width('100%')
                .backgroundColor(Color.White)
                .borderRadius(20)
                .onClick(() => {
                  this.selectedBookName = item.title;
                  this.selectedBookFile = item.file;
                  this.dialogController.open();
                })

                // ✅ 核心逻辑：判断并在特定分组后添加虚线
                // 分别在：考研(index 2)、托福(4)、高中(7)、专八(9) 之后添加
                if (index === 2 || index === 4 || index === 7 || index === 9) {
                  this.DashedSeparator()
                } else if (index !== this.books.length - 1) {
                  // 不是最后一项，且不是分组边界，添加普通的间距 (原 space: 15)
                  Blank().height(15)
                }
              }
            }
          })
        }
        .layoutWeight(1)
        .padding(20)
      }
      .width('100%').height('100%')
      .padding({ top: 48 })
    }
  }
}

@CustomDialog
struct ModeSelectDialog {
  controller: CustomDialogController;
  bookName: string = '';
  confirm: (isShuffle: boolean) => void = () => {};

  build() {
    Column() {
      Text(`正在开启《${this.bookName}》`).fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 10 })
      Text("请选择学习顺序：\n⚠️ 切换词库会重置该书的进度。")
        .fontSize(14).fontColor(Color.Gray).textAlign(TextAlign.Center).margin({ bottom: 20 })

      Row({ space: 10 }) {
        Button("顺序模式")
          .backgroundColor(Color.White)
          .fontColor('#009688')
          .border({ width: 1, color: '#009688' })
          .onClick(() => { this.confirm(false); })
          .layoutWeight(1)

        Button("乱序模式")
          .backgroundColor('#009688')
          .fontColor(Color.White)
          .onClick(() => { this.confirm(true); })
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