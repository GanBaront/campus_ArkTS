/**
 * MainAbility — 主界面 Ability
 * ==============================
 * 登录成功后由 LoginPage 通过 startAbility 拉起。
 * 接收登录意图中的 userId / userName，注入 AppStorage 后加载 HomePage。
 */
import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import hilog from '@ohos.hilog';
import dataPreferences from '@ohos.data.preferences';
import { StorageManager } from '../utils/StorageManager';

const DOMAIN = 0x0000;

export default class MainAbility extends UIAbility {
  /**
   * 用户信息注入：优先从 Want 参数提取，失败则从 Preferences 读取注册数据。
   * Want 跨 Ability 参数传递在某些 HarmonyOS 版本不可靠，用 Preferences 做兜底。
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'MainAbility', 'Ability onCreate');

    // 尝试从 Want 参数提取（兼容直接传递）
    let userId = want.parameters?.userId as string;
    let userName = want.parameters?.userName as string;

    // 优先用 Want 参数，否则用 AppStorage（由 LoginPage 设置的临时值）
    AppStorage.set('userId', userId || '2301130077');
    AppStorage.set('userName', userName || '未知用户');

    // 异步从 Preferences 加载（覆盖正确的持久化值）
    this.loadUserFromPreferences();
  }

  /** 从 Preferences 读取当前登录用户信息（兜底 Want 参数跨 Ability 传递不可靠） */
  private async loadUserFromPreferences(): Promise<void> {
    try {
      const context = this.context;
      let pref = await dataPreferences.getPreferences(context, 'AppLaunchPreferences');
      let savedName = await pref.get('current_userName', '') as string;
      let savedId = await pref.get('current_userId', '') as string;

      if (savedName) {
        AppStorage.set('userName', savedName);
        hilog.info(DOMAIN, 'MainAbility', '从Preferences恢复用户名: %{public}s', savedName);
      }
      if (savedId) {
        AppStorage.set('userId', savedId);
      }
    } catch (err) {
      hilog.warn(DOMAIN, 'MainAbility', 'Preferences加载用户信息失败');
    }
  }

  /** 加载主界面前从 KV Store 恢复系统设置，确保首页即显示上次保存的主题/字号 */
  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // 从 KV Store 恢复用户偏好设置，注入 AppStorage（解决冷启动首页未恢复设置问题）
    const savedTheme = await StorageManager.getInstance().getSetting('theme_mode', 'light');
    AppStorage.set('appTheme', savedTheme);
    const savedFontSize = await StorageManager.getInstance().getSetting('font_size', '17');
    AppStorage.set('appFontSize', Number(savedFontSize));

    windowStage.loadContent('pages/HomePage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'MainAbility', 'Failed to load content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'MainAbility', 'Succeeded in loading content.');
    });
  }

  onWindowStageDestroy(): void {}
  onForeground(): void {}
  onBackground(): void {}
  onDestroy(): void {}
}