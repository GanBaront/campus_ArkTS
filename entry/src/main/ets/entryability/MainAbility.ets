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
import { StorageManager } from '../utils/StorageManager';

const DOMAIN = 0x0000;

export default class MainAbility extends UIAbility {
  /** 接收登录页传来的用户信息，注入全局状态 */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'MainAbility', 'Ability onCreate');

    // 从 Want 参数中提取登录成功的用户信息
    let userId = want.parameters?.userId as string;
    let userName = want.parameters?.userName as string;

    // [诊断] 确认 Want 参数传递是否正常
    hilog.info(DOMAIN, 'MainAbility', 'Want参数 userId: %{public}s, userName: %{public}s',
      userId || 'null', userName || 'null');

    // 注入 AppStorage，驱动全局 UI 更新（如首页用户名校验、个人中心展示）
    AppStorage.set('userId', userId || '2301130077');
    AppStorage.set('userName', userName || '甘凯洋');
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