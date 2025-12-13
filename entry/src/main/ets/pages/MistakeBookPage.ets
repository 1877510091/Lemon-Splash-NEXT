import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

// ✅ 定义类
class MistakeItem {
  word: string;
  def: string;
  constructor(word: string, def: string) {
    this.word = word;
    this.def = def;
  }
}

@Entry
@Component
struct MistakeBookPage {
  private words: MistakeItem[] = [
    new MistakeItem("abandon", "v. 遗弃"),
    new MistakeItem("ability", "n. 能力")
  ];

  build() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(24).fontColor([Color.Black]).onClick(() => router.back()) // ✅ 修复
        Text("错题本").fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .height(56).padding({ left: 16, right: 16 })

      List({ space: 10 }) {
        ForEach(this.words, (item: MistakeItem) => {
          ListItem() {
            Row() {
              Button({ type: ButtonType.Circle }) {
                SymbolGlyph($r('sys.symbol.speaker_wave_2')).fontSize(18).fontColor(['#FF9800']) // ✅ 修复
              }
              .backgroundColor(Color.Transparent)
              .width(40).height(40)
              .onClick(() => { try{ promptAction.showToast({ message: '播放...' }); }catch(e){} })

              Column() {
                Text(item.word).fontSize(18).fontWeight(FontWeight.Bold)
                Text(item.def).fontSize(14).fontColor(Color.Gray).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 10 })

              Button({ type: ButtonType.Circle }) {
                SymbolGlyph($r('sys.symbol.trash')).fontSize(20).fontColor(['#BDBDBD']) // ✅ 修复
              }
              .backgroundColor(Color.Transparent)
              .width(40).height(40)
              .onClick(() => {
                try{ promptAction.showToast({ message: '已移除' }); }catch(e){}
              })
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(16)
          }
        })
      }
      .layoutWeight(1)
      .padding(20)
    }
    .width('100%').height('100%')
    .backgroundColor('#FFF3E0')
    .padding({ top: 10 })
  }
}