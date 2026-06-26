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
import { BackgroundTaskManager } from '../utils/BackgroundTaskManager';

const DOMAIN = 0x0000;

export default class MainAbility extends UIAbility {
  /** Want 参数传递在某些 HarmonyOS 版本不可靠，仅做临时占位 */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'MainAbility', 'Ability onCreate');
    // 先用 Want 参数占位（可能为空）
    let userId = want.parameters?.userId as string;
    let userName = want.parameters?.userName as string;
    AppStorage.set('userId', userId || '2301130077');
    AppStorage.set('userName', userName || '加载中...');
  }

  /** 加载页面前从 Preferences/KVStore 恢复所有持久化状态，确保首页首帧即显示正确信息 */
  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // 1. 从应用级 Preferences 恢复当前登录用户信息（跨 Ability 共享）
    try {
      const appCtx = this.context.getApplicationContext();
      let pref = await dataPreferences.getPreferences(appCtx, 'AppLaunchPreferences');
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

    // 2. 从 KV Store 恢复用户偏好设置
    const savedTheme = await StorageManager.getInstance().getSetting('theme_mode', 'light');
    AppStorage.set('appTheme', savedTheme);
    const savedFontSize = await StorageManager.getInstance().getSetting('font_size', '17');
    AppStorage.set('appFontSize', Number(savedFontSize));

    // 3. 状态全部就绪后再加载页面
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
  onBackground(): void {
    // 实验5：退后台时申请短时任务，保护课表编辑草稿（draft_course_form）和滚动位置（scroll_position）
    try {
      const btm = BackgroundTaskManager.getInstance();
      const result = btm.requestTransientTask('保存课表草稿与滚动位置', () => {
        // 超时回调：3分钟内强制落盘，确保草稿不丢失
        console.info('MainAbility 短时任务超时，紧急保护草稿数据（draft_course_form / scroll_position）');
      });
      hilog.info(DOMAIN, 'MainAbility', '短时任务已申请(requestId=%{public}d): %{public}s',
        result.requestId, result.message);
    } catch (err) {
      hilog.error(DOMAIN, 'MainAbility', '短时任务申请失败: %{public}s', JSON.stringify(err));
    }
  }
  onDestroy(): void {}
}