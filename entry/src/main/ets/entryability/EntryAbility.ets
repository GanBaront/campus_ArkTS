import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { StorageManager } from '../utils/StorageManager'; // 1. 引入你封装的存储管理器

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  // 2. 将 onCreate 改为 async 异步函数，确保初始化完成后再向下执行
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    try {
      // 3. 核心注入：在此处传入当前 Ability 的 context 句柄，一键启动三合一存储引擎
      await StorageManager.getInstance().init(this.context);
      hilog.info(DOMAIN, 'testTag', 'StorageManager 一键初始化成功');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'StorageManager 初始化失败: %{public}s', JSON.stringify(err));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  // 4. 将 onWindowStageCreate 改为 async 异步函数，以便使用 await 读取首选项
  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    let isFirstLaunch: boolean = true;

    try {
      // 5. 从 Preferences 中动态异步获取真实的首次启动标记
      isFirstLaunch = await StorageManager.getInstance().checkIsFirstLaunch();
      hilog.info(DOMAIN, 'testTag', '从沙箱成功盘查到 isFirstLaunch 标记为: %{public}s', String(isFirstLaunch));
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', '读取首次启动标记异常，降级使用默认值 true. 原因: %{public}s', JSON.stringify(err));
    }

    let targetPage: string = '';

    if (isFirstLaunch) {
      // 场景 A：首次启动，加载起始页 Index.ets（包含你写的跳动圆点加载动画）
      // 随后由 Index 页面内部逻辑处理欢迎弹窗、消除标记，并跳转至 Onboarding 引导页
      targetPage = 'pages/Index';
    } else {
      // 场景 B：非首次启动，直接加载登录页，提升用户体验
      targetPage = 'pages/LoginPage';
    }

    // 执行页面加载
    windowStage.loadContent(targetPage, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading content: %{public}s', targetPage);
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}