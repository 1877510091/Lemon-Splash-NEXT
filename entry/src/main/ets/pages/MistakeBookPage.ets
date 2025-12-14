import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import DatabaseHelper from '../model/DatabaseHelper';
import TTSHelper from '../util/TTSHelper';
import { Word } from '../model/WordModel';

@Entry
@Component
struct MistakeBookPage {
  @State mistakeWords: Word[] = [];
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    try {
      this.mistakeWords = await DatabaseHelper.getMistakeWords();
    } catch (e) {
      console.error('错题加载失败:', JSON.stringify(e as object));
    } finally {
      this.isLoading = false;
    }
  }

  async removeMistake(index: number) {
    let word = this.mistakeWords[index];
    if (word.id !== null) {
      await DatabaseHelper.removeMistake(word.id);
      this.mistakeWords.splice(index, 1);
      try { promptAction.showToast({ message: '已移除错题' }); } catch(e) {}
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(24).fontColor([Color.Black]).onClick(() => router.back())
        Text(`错题本 (${this.mistakeWords.length})`).fontSize(20).fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .height(56).padding({ left: 16, right: 16 })

      if (this.isLoading) {
        Text("加载中...").margin({ top: 20 }).fontColor(Color.Gray)
      } else if (this.mistakeWords.length === 0) {
        // ✅ 核心修复：让 Column 占据剩余所有空间并居中对齐内容
        Column() {
          SymbolGlyph($r('sys.symbol.checkmark_circle')).fontSize(60).fontColor(['#FFB74D'])
          Text("太棒了，没有错题！").margin({ top: 10 }).fontColor(Color.Gray)
        }
        .width('100%')
        .layoutWeight(1) // 占据剩余空间
        .justifyContent(FlexAlign.Center) // 垂直居中内容
      } else {
        List({ space: 10 }) {
          ForEach(this.mistakeWords, (item: Word, index: number) => {
            ListItem() {
              Row() {
                Button({ type: ButtonType.Circle }) {
                  SymbolGlyph($r('sys.symbol.speaker_wave_2')).fontSize(18).fontColor(['#FF9800'])
                }
                .backgroundColor(Color.Transparent).width(40).height(40)
                .onClick(() => TTSHelper.speak(item.word))

                Column() {
                  Text(item.word).fontSize(18).fontWeight(FontWeight.Bold)
                  Text(item.definition).fontSize(14).fontColor(Color.Gray).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 10 })

                Button({ type: ButtonType.Circle }) {
                  SymbolGlyph($r('sys.symbol.trash')).fontSize(20).fontColor(['#BDBDBD'])
                }
                .backgroundColor(Color.Transparent).width(40).height(40)
                .onClick(() => {
                  this.removeMistake(index);
                })
              }
              .padding(16).backgroundColor(Color.White).borderRadius(16)
            }
          })
        }
        .layoutWeight(1).padding(20)
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#FFF3E0')
    .padding({ top: 48 })
  }
}