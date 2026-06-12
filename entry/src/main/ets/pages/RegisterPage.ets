/**
 * RegisterPage — 注册页
 * ======================
 * 校验字段：姓名、学号（≥5位）、手机号、密码（≥6位）、确认密码一致性。
 * 注册成功后通过 RegData 静态类传递凭证，跳转回 LoginPage。
 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct RegisterPage {
  @State phoneNumber: string = ''
  @State userName: string = ''
  @State studentId: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''

  build() {
    Column() {
      // 1. 返回按钮
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back()
          })
      }
      .width('100%')
      .padding({ top: 20 })

      // 2. 标题区
      Column({ space: 5 }) {
        Row() {
          Text('注册新账号')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
          Image($r('app.media.star'))
            .width(24)
            .height(24)
            .margin({ left: 8 })
        }
        Text('加入校通Plus，开启智慧校园新篇章')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ top: 20, bottom: 20 })

      // 3. 注册表单（支持滚动，防止小屏幕键盘弹起遮挡）
      Scroll() {
        Column({ space: 15 }) {
          this.RegisterInput('真实姓名', '请输入您的真实姓名', $r('app.media.user'), (val) => {
            this.userName = val.trim()
          })

          this.RegisterInput('学号', '请输入您的校方学号', $r('app.media.id'), (val) => {
            this.studentId = val.trim()
          })

          this.RegisterInput('手机号', '请输入手机号', $r('app.media.home'), (val) => {
            this.phoneNumber = val.trim()
          })

          this.RegisterInput('设置密码', '请输入密码(不少于6位)', $r('app.media.privacy'), (val) => {
            this.password = val.trim()
          }, InputType.Password)

          this.RegisterInput('确认密码', '请再次输入密码', $r('app.media.privacy'), (val) => {
            this.confirmPassword = val.trim()
          }, InputType.Password)
        }
        .padding({ bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 4. 注册按钮
      Button('立即注册')
        .width('100%')
        .height(50)
        .margin({ top: 15, bottom: 15 })
        .backgroundColor('#005DFF')
        .borderRadius(25)
        .onClick(() => {
          this.handleRegisterValidation()
        })

      // 5. 底部跳转
      Row() {
        Text('已经有账号？').fontSize(14).fontColor('#999')
        Text('直接登录')
          .fontSize(14)
          .fontColor('#005DFF')
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            router.back()
          })
      }
      .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 30, right: 30 })
    .backgroundColor('#FFFFFF')
  }

  /** 表单逐字段校验 */
  private handleRegisterValidation() {
    if (!this.userName) {
      promptAction.showToast({ message: '姓名不能为空！', duration: 2000 });
      return;
    }
    if (this.studentId.length < 5) {
      promptAction.showToast({ message: '请输入正确的学号！', duration: 2000 });
      return;
    }
    if (!this.phoneNumber) {
      promptAction.showToast({ message: '手机号不能为空！', duration: 2000 });
      return;
    }
    if (this.password.length < 6) {
      promptAction.showToast({ message: '密码不能少于6位！', duration: 2000 });
      return;
    }
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的密码不一致！', duration: 2000 });
      return;
    }

    // 校验通过，执行成功暂存
    this.handleRegisterSuccess()
  }

  /** 注册成功：持久化凭证到 Preferences（重启不丢失），跳转回 LoginPage */
  private async handleRegisterSuccess() {
    promptAction.showToast({ message: `注册成功！姓名:${this.userName} 账号:${this.phoneNumber}`, duration: 3000 });

    // 持久化到应用级 Preferences（跨 Ability 共享）
    const appCtx = (getContext(this) as common.UIAbilityContext).getApplicationContext();
    let pref = await dataPreferences.getPreferences(appCtx, 'AppLaunchPreferences');
    await pref.put('reg_account', this.phoneNumber);
    await pref.put('reg_password', this.password);
    await pref.put('reg_userName', this.userName);
    await pref.put('reg_studentId', this.studentId);
    await pref.flush();

    let options: router.RouterOptions = {
      url: 'pages/LoginPage',
      params: {
        account: this.phoneNumber
      }
    };
    router.pushUrl(options);
  }

  @Builder RegisterInput(label: string, hint: string, icon: Resource, onValueChange: (value: string) => void, type: InputType = InputType.Normal) {
    Column({ space: 6 }) {
      Text(label).fontSize(14).fontColor('#666')
      Row() {
        Image(icon).width(20).height(20).opacity(0.5)
        TextInput({ placeholder: hint })
          .type(type)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange(onValueChange)
      }
      .border({ width: { bottom: 1 }, color: '#E5E5E5' })
      .padding({ bottom: 5 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}