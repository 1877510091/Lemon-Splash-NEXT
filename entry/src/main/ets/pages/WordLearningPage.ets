import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import DatabaseHelper from '../model/DatabaseHelper';
import TTSHelper from '../util/TTSHelper';
import { Word, StudyProgress } from '../model/WordModel';

@Entry
@Component
struct WordLearningPage {
  @State progress: number = 0;
  @State currentWordIndex: number = 0;
  @State currentWords: Word[] = [];
  @State isLoading: boolean = true;
  @State currentGroup: number = 0;

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      let bookName = await DatabaseHelper.getLastBook();
      if (!bookName) bookName = "四级词汇";

      let progressObj = await DatabaseHelper.getStudyProgress(bookName);
      this.currentGroup = progressObj.currentGroup;

      let words = await DatabaseHelper.getWordsByGroup(bookName, this.currentGroup, 20);

      if (words.length === 0) {
        try {
          promptAction.showToast({ message: '本组单词为空，请检查词库' });
        } catch (error) {}
        this.isLoading = false;
        return;
      }

      let firstUnlearnedIndex = 0;
      for (let i = 0; i < words.length; i++) {
        if (words[i].status === 0) {
          firstUnlearnedIndex = i;
          break;
        }
      }

      this.currentWords = words;
      this.currentWordIndex = firstUnlearnedIndex;
      this.updateProgress();
      this.isLoading = false;

      if (this.currentWords.length > 0) {
        TTSHelper.speak(this.currentWords[this.currentWordIndex].word);
      }

    } catch (e) {
      console.error('加载失败:', JSON.stringify(e as object));
      this.isLoading = false;
    }
  }

  updateProgress() {
    if (this.currentWords.length > 0) {
      this.progress = (this.currentWordIndex + 1) / this.currentWords.length * 100;
    } else {
      this.progress = 0;
    }
  }

  async handleUserAction(isKnown: boolean) {
    if (this.currentWordIndex >= this.currentWords.length) return;

    let word = this.currentWords[this.currentWordIndex];
    if (word.id !== null) {
      await DatabaseHelper.markWordAsLearned(word.id, !isKnown);
    }

    if (this.currentWordIndex < this.currentWords.length - 1) {
      this.currentWordIndex++;
      this.updateProgress();
      TTSHelper.speak(this.currentWords[this.currentWordIndex].word);
    } else {
      this.showFinishDialog();
    }
  }

  async startNextGroup() {
    if (this.currentWords.length > 0) {
      let bookName = this.currentWords[0].bookName;
      await DatabaseHelper.saveStudyProgress(new StudyProgress(bookName, this.currentGroup + 1));
      this.loadData();
    }
  }

  showFinishDialog() {
    AlertDialog.show({
      title: '🎉 本组完成',
      message: '太棒了！休息一下还是继续？',
      autoCancel: false,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '再复习一遍',
        action: () => {
          this.currentWordIndex = 0;
          this.updateProgress();
        }
      },
      secondaryButton: {
        value: '下一组',
        fontColor: '#009688',
        action: () => {
          this.startNextGroup();
        }
      }
    });
  }

  handleUndo() {
    if (this.currentWordIndex > 0) {
      this.currentWordIndex--;
      this.updateProgress();
      TTSHelper.speak(this.currentWords[this.currentWordIndex].word);
    } else {
      try { promptAction.showToast({ message: '已经是第一个了' }); } catch(e) {}
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24).fontColor(['#004D40'])
          .onClick(() => router.back())

        Text(`分组: ${this.currentGroup + 1} | 进度: ${this.currentWordIndex + 1}/${this.currentWords.length}`)
          .fontSize(18).fontColor('#004D40').fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)

        Blank().width(24)
      }
      .height(56).padding({ left: 16, right: 16 })

      // 进度条
      Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
        .color('#CDDC39').backgroundColor(Color.White).height(4).width('100%')

      Blank().layoutWeight(1)

      if (this.isLoading) {
        LoadingProgress().color('#009688').width(50).height(50)
        Text("加载中...").fontSize(14).fontColor(Color.Gray).margin({ top: 10 })
        Blank().layoutWeight(2)
      } else if (this.currentWords.length > 0) {
        // === 单词卡片 ===
        Column() {

          // ✅ 核心修改：智能弹性文本
          Text(this.currentWords[this.currentWordIndex].word)
            .fontWeight(FontWeight.Bold)
            .fontColor('#004D40')
            .fontFamily('Georgia')
            .textAlign(TextAlign.Center)
            // ⬇️ 关键属性配置
            .maxLines(2)                  // 1. 最多允许两行
            .minFontSize(32)              // 2. 最小字号限制在32，防止缩太小看不清
            .maxFontSize(48)              // 3. 正常最大字号48
            .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST) // 4. 策略：优先缩小字号，缩不动了再换行
            .textOverflow({ overflow: TextOverflow.Ellipsis }) // 5. 实在不行才省略号
            .width('100%')

          Row() {
            Text(`/${this.currentWords[this.currentWordIndex].phonetic}/`)
              .fontSize(20).fontColor('#827717').margin({ right: 10 })

            SymbolGlyph($r('sys.symbol.speaker_wave_2'))
              .fontSize(24).fontColor(['#4DB6AC'])
              .onClick(() => {
                TTSHelper.speak(this.currentWords[this.currentWordIndex].word);
              })
          }
          .margin({ top: 10, bottom: 30 })

          Scroll() {
            Column() {
              Text(this.currentWords[this.currentWordIndex].definition)
                .fontSize(18).fontColor('#757575').textAlign(TextAlign.Center).lineHeight(28)

              if (this.currentWords[this.currentWordIndex].example) {
                Divider().color('#BDBDBD').margin({ top: 15, bottom: 15 }).width('80%')
                Text(this.currentWords[this.currentWordIndex].example)
                  .fontSize(16).fontColor('#00695C').fontStyle(FontStyle.Italic).textAlign(TextAlign.Center)
              }
            }
          }
          .height(150)
        }
        .width('85%')
        .padding({ top: 40, bottom: 40, left: 30, right: 30 })
        .backgroundColor(Color.White)
        .borderRadius(40)
        .shadow({ radius: 30, color: 'rgba(0, 150, 136, 0.1)', offsetY: 15 })

        Blank().layoutWeight(2)

        // === 底部按钮区 ===
        Row() {
          // --- 左侧：忘记 + 撤销 ---
          Column() {
            // 忘记按钮
            Column() {
              Stack() {
                Circle({ width: 75, height: 75 }).fill('#FFEBEE')
                SymbolGlyph($r('sys.symbol.xmark')).fontSize(32).fontColor(['#E57373'])
              }
              Text("忘记").fontSize(16).fontWeight(FontWeight.Bold).fontColor('#E57373').margin({ top: 8 })
            }
            .onClick(() => this.handleUserAction(false))

            // 撤销按钮
            Row() {
              SymbolGlyph($r('sys.symbol.arrow_left')).fontSize(18).fontColor(['#757575'])
              Text("撤销").fontSize(14).fontWeight(FontWeight.Bold).fontColor('#757575').margin({ left: 4 })
            }
            .margin({ top: 20 })
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor(Color.White)
            .borderRadius(20)
            .border({ width: 1, color: '#E0E0E0' })
            .onClick(() => this.handleUndo())
          }

          // --- 中间间距 ---
          Blank().width(70)

          // --- 右侧：认识 ---
          Column() {
            Column() {
              Stack() {
                Circle({ width: 75, height: 75 }).fill('#F0F4C3')
                SymbolGlyph($r('sys.symbol.checkmark')).fontSize(32).fontColor(['#9E9D24'])
              }
              Text("认识").fontSize(16).fontWeight(FontWeight.Bold).fontColor('#9E9D24').margin({ top: 8 })
            }
            .onClick(() => this.handleUserAction(true))

            Blank().height(40).margin({ top: 20 })
          }
        }
        .alignItems(VerticalAlign.Top)
        .padding({ bottom: 40 })

      } else {
        // 空状态兜底
        Text("还没有选择词书，请先去图书馆选择一本吧！")
          .fontColor(Color.Gray)
          .margin({ top: 100 })
        Blank().layoutWeight(2)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E0F2F1')
    .padding({ top: 48 })
  }
}