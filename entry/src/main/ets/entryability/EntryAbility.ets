import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

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

    /**
     * 实验3 核心修改点：
     * 定义“是否首次登录/启动”的逻辑判断。
     * 在实际生产环境下，这里应该通过 @ohos.data.preferences (用户首选项) 异步获取。
     * 在实验演示阶段，我们可以手动修改这个布尔值来测试不同的加载路径。
     */
    let isFirstLaunch: boolean = true;

    let targetPage: string = '';

    if (isFirstLaunch) {
      // 场景 A：首次启动，加载起始页 Index.ets（包含你写的跳动圆点加载动画）
      // 随后由 Index 页面逻辑跳转至 Onboarding 引导页
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