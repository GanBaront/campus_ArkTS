/**
 * LoginPage — 登录页
 * ===================
 * 支持双链路认证：
 *   1. 默认账号：2301130077 / 123456（测试用）
 *   2. 注册账号：从 Preferences 持久化读取注册凭证校验
 *
 * 登录成功后通过 startAbility 拉起 MainAbility。
 */
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import promptAction from '@ohos.promptAction';
import dataPreferences from '@ohos.data.preferences';

@Entry
@Component
struct LoginPage {
  @State accountInput: string = ''
  @State passwordInput: string = ''

  /** 页面显示时从路由参数自动填充账号（如从注册页跳回） */
  onPageShow() {
    const params = router.getParams() as Record<string, string | boolean>;
    if (params && params.account) {
      this.accountInput = params.account as string;
    }
  }

  build() {
    Column() {
      // 1. 标题区
      Column({ space: 10 }) {
        Row() {
          Text('欢迎回来').fontSize(30).fontWeight(FontWeight.Bold)
          Image($r('app.media.wechat')).width(30).height(30).margin({ left: 10 })
        }
        Text('请登录您的校通Plus账号').fontSize(16).fontColor('#999').margin({ top: 10 })
      }.alignItems(HorizontalAlign.Start).width('100%').padding({ top: 60, bottom: 40 })

      // 2. 表单区
      Column({ space: 20 }) {
        Column({ space: 10 }) {
          Text('手机号 / 学号').fontSize(14).fontColor('#666')
          Row() {
            Image($r('app.media.wechat')).width(20).height(20).opacity(0.5)
            TextInput({ text: this.accountInput, placeholder: '请输入学号或手机号' })
              .backgroundColor(Color.Transparent)
              .layoutWeight(1)
              .onChange((val) => this.accountInput = val.trim())
          }
          .border({ width: { bottom: 1 }, color: '#E5E5E5' })
          .padding({ bottom: 5 })
        }.alignItems(HorizontalAlign.Start)

        Column({ space: 10 }) {
          Text('密码').fontSize(14).fontColor('#666')
          Row() {
            Image($r('app.media.wechat')).width(20).height(20).opacity(0.5)
            TextInput({ placeholder: '请输入密码' })
              .type(InputType.Password)
              .backgroundColor(Color.Transparent)
              .layoutWeight(1)
              .onChange((val) => this.passwordInput = val.trim())
          }
          .border({ width: { bottom: 1 }, color: '#E5E5E5' })
          .padding({ bottom: 5 })
        }.alignItems(HorizontalAlign.Start)
      }

      // 3. 登录按钮
      Button('登录')
        .width('100%')
        .height(50)
        .margin({ top: 40 })
        .backgroundColor('#005DFF')
        .borderRadius(25)
        .onClick(() => this.handleLogin())

      // 4. 社交登录快捷方式
      Row({ space: 30 }) {
        this.SocialIcon($r('app.media.wechat'))
        this.SocialIcon($r('app.media.wechat'))
      }.margin({ top: 50 })

      Blank()

      // 5. 立即注册
      Row() {
        Text('还没有账号？').fontSize(14).fontColor('#999')
        Text('立即注册').fontSize(14).fontColor('#005DFF').fontWeight(FontWeight.Bold)
          .onClick(() => { router.pushUrl({ url: 'pages/RegisterPage' }) })
      }.margin({ bottom: 30 })
    }.width('100%').height('100%').padding({ left: 30, right: 30 }).backgroundColor('#FFFFFF')
  }

  @Builder SocialIcon(src: Resource) {
    Stack() {
      Circle({ width: 50, height: 50 }).fill('#F5F6F7')
      Image(src).width(28).height(28)
    }
  }

  /**
   * 登录校验与路由拉起
   * 优先级：默认测试账号 → Preferences 持久化注册账号 → 拒绝
   */
  private async handleLogin() {
    if (!this.accountInput) {
      promptAction.showToast({ message: '请输入手机号或学号！', duration: 2000 });
      return;
    }
    if (!this.passwordInput) {
      promptAction.showToast({ message: '请输入密码！', duration: 2000 });
      return;
    }

    // 从 Preferences 读取已持久化的注册凭证（重启不丢失）
    const context = getContext(this) as common.Context;
    let pref = await dataPreferences.getPreferences(context, 'AppLaunchPreferences');
    let regAccount = await pref.get('reg_account', '') as string;
    let regPassword = await pref.get('reg_password', '') as string;
    let regUserName = await pref.get('reg_userName', '新同学') as string;
    let regStudentId = await pref.get('reg_studentId', this.accountInput) as string;

    let isAuthSuccess = false;
    let finalUserName = '';
    let finalUserId = '';

    // 链路 1：默认测试账号（学号 2301130077 / 密码 123456）
    if (this.accountInput === '2301130077') {
      if (this.passwordInput === '123456') {
        isAuthSuccess = true;
        finalUserName = '甘凯洋';
        finalUserId = '2301130077';
      } else {
        promptAction.showToast({ message: '默认账号密码错误，测试密码为 123456', duration: 2000 });
        return;
      }
    } else if (regAccount && this.accountInput === regAccount) {
      if (this.passwordInput === regPassword) {
        isAuthSuccess = true;
        finalUserName = regUserName;
        finalUserId = regStudentId;
      } else {
        promptAction.showToast({ message: '登录密码与注册密码不一致！', duration: 2000 });
        return;
      }
    } else {
      promptAction.showToast({ message: `未注册: 输入[${this.accountInput}] 已注册[${regAccount}]`, duration: 3000 });
      return;
    }

    // 校验全部闭环通过，开始投递到 MainAbility
    if (isAuthSuccess) {
      const context = getContext(this) as common.UIAbilityContext;
      promptAction.showToast({ message: '验证成功，正在登录...', duration: 1500 });

      let loginWant: Want = {
        bundleName: 'com.example.campus',
        abilityName: 'MainAbility',
        parameters: {
          'userId': finalUserId,
          'userName': finalUserName
        }
      };

      try {
        await context.startAbility(loginWant);
        context.terminateSelf();
      } catch (err) {
        console.error('跳转失败原因: ' + JSON.stringify(err));
        promptAction.showToast({ message: '系统调度异常，请检查配置', duration: 2000 });
      }
    }
  }
}