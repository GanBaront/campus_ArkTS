import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';

export default class ProfileAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 接收参数
    let userId = want.parameters?.userId as string;
    let userName = want.parameters?.userName as string;

    AppStorage.setOrCreate('userId', userId || '2301130077');
    AppStorage.setOrCreate('userName', userName || '甘凯洋');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/ProfilePage');
  }

  onWindowStageDestroy(): void {}
  onForeground(): void {}
  onBackground(): void {}
  onDestroy(): void {}
}