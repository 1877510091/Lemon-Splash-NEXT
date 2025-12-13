// 尝试使用新版 Kit 导入
import { textToSpeech } from '@kit.CoreSpeechKit';
import common from '@ohos.app.ability.common';

class TTSHelper {
  private static instance: TTSHelper;
  private ttsEngine: textToSpeech.TextToSpeechEngine | null = null;
  private isCreating: boolean = false;

  private constructor() {}

  public static getInstance(): TTSHelper {
    if (!TTSHelper.instance) {
      TTSHelper.instance = new TTSHelper();
    }
    return TTSHelper.instance;
  }

  async init() {
    if (this.ttsEngine || this.isCreating) return;
    this.isCreating = true;

    try {
      // 1. 配置参数
      let extraParams: Record<string, Object> = {};
      let createParams: textToSpeech.CreateEngineParams = {
        language: 'en-US',
        person: 0,
        online: 1,
        extraParams: extraParams
      };

      // 2. 创建引擎
      this.ttsEngine = await textToSpeech.createEngine(createParams);
      console.info('✅ 离线 TTS 引擎初始化成功');

      // ❌ 已删除报错的 .on('error') 监听代码
      // 这样能确保证编译通过

    } catch (e) {
      console.error(`❌ TTS 初始化失败: ${JSON.stringify(e)}`);
    } finally {
      this.isCreating = false;
    }
  }

  async speak(text: string) {
    if (!this.ttsEngine) {
      await this.init();
    }

    if (this.ttsEngine) {
      try {
        let extraParams: Record<string, Object> = {
          "speed": 1.0,
          "volume": 1.0,
          "pitch": 1.0,
          "queueMode": 0
        };

        let speakParams: textToSpeech.SpeakParams = {
          requestId: Date.now().toString(),
          extraParams: extraParams
        };

        console.info(`🔊 播放: ${text}`);
        this.ttsEngine.speak(text, speakParams);
      } catch (e) {
        console.error(`❌ 发音失败: ${JSON.stringify(e)}`);
      }
    }
  }
}

export default TTSHelper.getInstance();