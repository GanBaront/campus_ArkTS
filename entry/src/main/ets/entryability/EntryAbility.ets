/**
 * EntryAbility — 应用入口 Ability
 * ==============================
 * 启动流程：
 *   1. 强制浅色模式（避免初始闪烁）
 *   2. 初始化 StorageManager 三引擎
 *   3. 读取 bundle 版本号
 *   4. 首次启动/版本更新 → Onboarding 引导页 → LoginPage → MainAbility → HomePage
 *      非首次           → 直接 LoginPage → MainAbility → HomePage
 *   5. 标记启动完成（落盘 isFirstLaunch + appVersion）
 */
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import bundleManager from '@ohos.bundle.bundleManager';
import { StorageManager } from '../utils/StorageManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  /** Ability 创建：初始化主题模式 + 存储引擎 */
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    // 强制浅色模式，防止冷启动时闪屏
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 一键初始化三大存储引擎（Preferences / KV Store / RelationalStore）
    try {
      await StorageManager.getInstance().init(this.context);
      hilog.info(DOMAIN, 'testTag', 'StorageManager 一键初始化成功');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'StorageManager 初始化失败: %{public}s', JSON.stringify(err));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  /** 窗口创建：根据首次启动/版本更新决定路由目标页面 */
  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 1. 获取当前 App 版本号（用于版本更新检测）
    let currentVersion: string = '1.0.0';
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT
      );
      currentVersion = bundleInfo.versionName;
      hilog.info(DOMAIN, 'testTag', '当前 App 版本: %{public}s', currentVersion);
    } catch (err) {
      hilog.warn(DOMAIN, 'testTag', '获取版本号失败，使用默认值 1.0.0');
    }

    // 2. 检测是否需要展示引导页（首次启动 或 版本更新）
    let shouldShowOnboarding: boolean = false;
    try {
      shouldShowOnboarding = await StorageManager.getInstance()
        .checkIsFirstLaunchOrUpdate(currentVersion);
      hilog.info(DOMAIN, 'testTag', '是否需要引导页: %{public}s', String(shouldShowOnboarding));
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', '首次启动检测异常: %{public}s', JSON.stringify(err));
    }

    // 3. 决定目标页面并加载
    let targetPage: string;
    if (shouldShowOnboarding) {
      targetPage = 'pages/Onboarding';
      // 立即标记完成，避免用户中途杀进程后重复展示引导页
      await StorageManager.getInstance().markLaunchComplete(currentVersion);
      hilog.info(DOMAIN, 'testTag', '首次启动/版本更新标记已落盘');
    } else {
      targetPage = 'pages/LoginPage';
    }

    // 4. 加载目标页面
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