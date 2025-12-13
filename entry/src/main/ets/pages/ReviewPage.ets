import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import DatabaseHelper from '../model/DatabaseHelper';
import TTSHelper from '../util/TTSHelper';
import { Word } from '../model/WordModel';

@Entry
@Component
struct ReviewPage {
  @State showAnswer: boolean = false;
  @State reviewWords: Word[] = [];
  @State currentIndex: number = 0;
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.reviewWords = await DatabaseHelper.getWordsDueForReview();
      this.currentIndex = 0;
      this.showAnswer = false;

      if (this.reviewWords.length > 0) {
        TTSHelper.speak(this.reviewWords[0].word);
      }
    } catch (e) {
      console.error('复习数据加载失败:', JSON.stringify(e as object));
    } finally {
      this.isLoading = false;
    }
  }

  async handleResult(remembered: boolean) {
    if (this.currentIndex >= this.reviewWords.length) return;

    let word = this.reviewWords[this.currentIndex];

    if (word.id !== null) {
      await DatabaseHelper.processReview(word.id, remembered, word.reviewStage);
    }

    if (this.currentIndex < this.reviewWords.length - 1) {
      this.currentIndex++;
      this.showAnswer = false;
      TTSHelper.speak(this.reviewWords[this.currentIndex].word);
    } else {
      AlertDialog.show({
        title: '🎉 复习完成',
        message: '今天的复习任务已清空！',
        autoCancel: false,
        alignment: DialogAlignment.Center,
        confirm: {
          value: '返回首页',
          action: () => { router.back(); }
        }
      });
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(24).fontColor(['#0D47A1']).onClick(() => router.back())
        Text("智能复习").fontSize(18).fontColor('#0D47A1').fontWeight(FontWeight.Bold).layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(24)
      }
      .height(56).padding({ left: 16, right: 16 })

      if (this.reviewWords.length > 0) {
        Progress({ value: this.currentIndex + 1, total: this.reviewWords.length })
          .color('#2196F3').backgroundColor(Color.White).height(4).width('100%')
      }

      // ✅ 修复2：空状态页面居中 & 文案修改
      if (this.isLoading) {
        Column() {
          Text("正在计算复习队列...").fontColor(Color.Gray)
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.reviewWords.length === 0) {
        Column() {
          // 放在屏幕中间
          SymbolGlyph($r('sys.symbol.checkmark_circle')).fontSize(60).fontColor(['#4CAF50']).margin({ bottom: 20 })

          Text("复习算法会根据艾宾浩斯遗忘曲线\n在几天后整理需要复习的单词") // ✅ 文案修改
            .fontSize(16)
            .textAlign(TextAlign.Center)
            .fontColor(Color.Gray)
            .lineHeight(26) // 增加行高，更好看
        }
        .width('100%')
        .layoutWeight(1) // 占满剩余高度
        .justifyContent(FlexAlign.Center) // ✅ 垂直居中
        .padding({ bottom: 56 }) // 稍微往上提一点，视觉更平衡
      } else {
        Blank().layoutWeight(1)

        // === 复习卡片 ===
        Column() {
          Text(this.reviewWords[this.currentIndex].word)
            .fontSize(48).fontWeight(FontWeight.Bold).fontColor('#0D47A1').fontFamily('Georgia').textAlign(TextAlign.Center)

          Row() {
            SymbolGlyph($r('sys.symbol.speaker_wave_2')).fontSize(24).fontColor(['#2196F3'])
              .onClick(() => { TTSHelper.speak(this.reviewWords[this.currentIndex].word); })
          }.margin({ top: 10 })

          if (this.showAnswer) {
            Text(`/${this.reviewWords[this.currentIndex].phonetic}/`).fontSize(20).fontColor('#1976D2').margin({ top: 20, bottom: 20 })
            Text(this.reviewWords[this.currentIndex].definition)
              .fontSize(18).fontColor('#757575').textAlign(TextAlign.Center)
          } else {
            Blank().height(50)
            Text("点击查看释义").fontSize(14).fontColor(Color.Gray).margin({ top: 30, bottom: 30 })
            Blank().height(50)
          }
        }
        .width('85%')
        .padding({ top: 60, bottom: 60, left: 30, right: 30 })
        .backgroundColor(Color.White)
        .borderRadius(40)
        .shadow({ radius: 30, color: 'rgba(33, 150, 243, 0.1)', offsetY: 15 })

        Blank().layoutWeight(2)

        // === 底部按钮 ===
        if (!this.showAnswer) {
          Button("查看答案")
            .backgroundColor('#BBDEFB')
            .fontColor('#0D47A1')
            .fontWeight(FontWeight.Bold)
            .width(160)
            .height(50)
            .onClick(() => this.showAnswer = true)
        } else {
          Row() {
            Column() {
              Stack() {
                Circle({ width: 70, height: 70 }).fill('#FFEBEE')
                SymbolGlyph($r('sys.symbol.xmark')).fontSize(30).fontColor(['#E57373'])
              }
              Text("忘记了").fontSize(14).fontWeight(FontWeight.Bold).fontColor('#E57373').margin({ top: 8 })
            }
            .onClick(() => this.handleResult(false))

            Blank().width(50)

            Column() {
              Stack() {
                Circle({ width: 70, height: 70 }).fill('#F0F4C3')
                SymbolGlyph($r('sys.symbol.checkmark')).fontSize(30).fontColor(['#9E9D24'])
              }
              Text("记得").fontSize(14).fontWeight(FontWeight.Bold).fontColor('#9E9D24').margin({ top: 8 })
            }
            .onClick(() => this.handleResult(true))
          }
        }
        Blank().height(50)
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#E3F2FD')
    .padding({ top: 48 })
  }
}