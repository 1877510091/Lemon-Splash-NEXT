import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
// ✅ 引入数据库帮助类 (确保路径正确)
import DatabaseHelper from '../model/DatabaseHelper';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // ✅ 1. 初始化数据库
    // 传入 UIAbilityContext，用于后续读取 RawFile 和操作 RDB
    DatabaseHelper.init(this.context).then(() => {
      hilog.info(DOMAIN, 'testTag', '✅ 数据库初始化成功');
    }).catch((err: object) => {
      hilog.error(DOMAIN, 'testTag', '❌ 数据库初始化失败: %{public}s', JSON.stringify(err));
    });

    // ------------------- 👇 沉浸式设置 👇 -------------------

    // 2. 获取应用主窗口
    let windowClass: window.Window = windowStage.getMainWindowSync();

    // 3. 设置全屏布局 (开启沉浸式)
    windowClass.setWindowLayoutFullScreen(true, (err: BusinessError) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to set full screen. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in setting full screen.');
    });

    // 4. 设置状态栏和导航栏样式
    let sysBarProps: window.SystemBarProperties = {
      // 把背景色设为全透明
      statusBarColor: '#00000000',
      navigationBarColor: '#00000000',

      // 设置图标和文字颜色：'#000000' (黑) 或 '#ffffff' (白)
      statusBarContentColor: '#000000',
      navigationBarContentColor: '#000000'
    };

    windowClass.setWindowSystemBarProperties(sysBarProps, (err: BusinessError) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to set system bar properties. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in setting system bar properties.');
    });

    // ------------------- 👆 沉浸式设置结束 👆 -------------------

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}