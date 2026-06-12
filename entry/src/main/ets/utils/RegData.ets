// 跨页面注册数据共享（绕过 AppStorage/router params 传递不可靠问题）
export class RegData {
  static account: string = '';
  static password: string = '';
  static userName: string = '';
  static studentId: string = '';
  static hasData: boolean = false;

  static set(account: string, password: string, userName: string, studentId: string): void {
    RegData.account = account;
    RegData.password = password;
    RegData.userName = userName;
    RegData.studentId = studentId;
    RegData.hasData = true;
  }

  static clear(): void {
    RegData.account = '';
    RegData.password = '';
    RegData.userName = '';
    RegData.studentId = '';
    RegData.hasData = false;
  }
}
