/**
 * ProfileAbility — 个人中心独立 Ability
 * =======================================
 * 从首页通知图标点击跳转，加载独立的 ProfilePage。
 * 接收 Want 中的 userId / userName 参数并注入 AppStorage。
 */
import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';

export default class ProfileAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 从首页通知图标传来的用户参数
    let userId = want.parameters?.userId as string;
    let userName = want.parameters?.userName as string;

    AppStorage.set('userId', userId || '2301130077');
    AppStorage.set('userName', userName || '甘凯洋');
  }

  /** 加载独立 ProfilePage 页面 */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/ProfilePage');
  }

  onWindowStageDestroy(): void {}
  onForeground(): void {}
  onBackground(): void {}
  onDestroy(): void {}
}