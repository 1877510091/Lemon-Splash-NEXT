import media from '@ohos.multimedia.media';
import common from '@ohos.app.ability.common';

class AudioHelper {
  private static instance: AudioHelper;
  private avPlayer: media.AVPlayer | null = null;
  private isPlaying: boolean = false;

  private constructor() {}

  public static getInstance(): AudioHelper {
    if (!AudioHelper.instance) {
      AudioHelper.instance = new AudioHelper();
    }
    return AudioHelper.instance;
  }

  // 初始化播放器
  async init() {
    if (this.avPlayer) return;
    try {
      // 创建播放器实例
      this.avPlayer = await media.createAVPlayer();

      // 监听状态变化
      this.avPlayer.on('stateChange', async (state, reason) => {
        switch (state) {
          case 'initialized':
            if (this.avPlayer) await this.avPlayer.prepare();
            break;
          case 'prepared':
            if (this.avPlayer) await this.avPlayer.play();
            break;
          case 'completed':
            this.isPlaying = false;
            break;
          case 'error':
            this.isPlaying = false;
            console.error('播放器错误');
            break;
        }
      });
    } catch (e) {
      console.error(`播放器初始化失败: ${JSON.stringify(e)}`);
    }
  }

  // 核心功能：播放单词
  async speak(word: string) {
    if (!word) return;

    // 确保已初始化
    if (!this.avPlayer) await this.init();

    if (this.avPlayer) {
      try {
        // 如果正在播放，先重置
        if (this.avPlayer.state === 'playing') {
          await this.avPlayer.reset();
        } else if (this.avPlayer.state !== 'idle' && this.avPlayer.state !== 'initialized') {
          await this.avPlayer.reset();
        }

        // ✅ 使用有道词典的免费 API (type=1 英音, type=2 美音)
        // 这个 URL 在浏览器里也能直接打开听
        let url = `https://dict.youdao.com/dictvoice?audio=${encodeURIComponent(word)}&type=2`;

        this.avPlayer.url = url;
        // 设置 url 后，播放器会自动触发 'initialized' -> 'prepared' -> 'play'

        console.info(`🔊 正在播放: ${word}`);
      } catch (e) {
        console.error(`播放失败: ${JSON.stringify(e)}`);
      }
    }
  }

  // 释放资源
  async release() {
    if (this.avPlayer) {
      await this.avPlayer.release();
      this.avPlayer = null;
    }
  }
}

export default AudioHelper.getInstance();
//由于联网可能要求备案，真人发音暂时取消