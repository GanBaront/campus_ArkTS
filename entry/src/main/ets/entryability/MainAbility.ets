import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import hilog from '@ohos.hilog';

const DOMAIN = 0x0000;

export default class MainAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'MainAbility', 'Ability onCreate');

    // 拦截提取通过 Want 管道传输过来的新用户信息
    let userId = want.parameters?.userId as string;
    let userName = want.parameters?.userName as string;

    // 实时注入全局状态机，驱动视图主动触发重绘
    AppStorage.setOrCreate('userId', userId || '2301130077');
    AppStorage.setOrCreate('userName', userName || '甘凯洋');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
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