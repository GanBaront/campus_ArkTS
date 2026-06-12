/**
 * Index — 学生信息管理独立页面
 * ================================
 * 包含完整的 RelationalStore CRUD 验证面板：
 *   - 偏好设置舱（KV Store 主题/字号切换）
 *   - 日程录入/展示（RelationalStore 写入/查询）
 *   - 学生管理（新增/删除/改分/批量事务插入/索引搜索）
 *
 * 从 ProfilePage「我的」Tab →「学生信息管理」按钮跳转进入。
 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import dataPreferences from '@ohos.data.preferences';
import { StorageManager, ScheduleItem, StudentItem } from '../utils/StorageManager';
import { ProfilePage } from './ProfilePage';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0; // 默认选中第 1 个 Tab（工作台）

  // Preferences 状态响应
  @State isFirstTime: boolean = false;

  // RelationalStore 复杂关系型列表状态响应
  @State scheduleList: Array<ScheduleItem> = [];

  // 临时表单状态数据
  @State newTitle: string = '';
  @State newContent: string = '';

  // 步骤4：学生信息管理状态变量
  @State studentList: Array<StudentItem> = [];
  @State newStudentName: string = '';
  @State newStudentAge: string = '';
  @State newStudentScore: string = '';
  @State searchName: string = '';
  @State batchInsertTime: string = '';   // 批量插入耗时展示
  @State queryTime: string = '';         // 查询耗时展示

  // 🛠️ 深度绑定：双向全局状态机，拉动滑块或切换单选框时，全项目关联组件毫秒级重绘
  @StorageLink('appTheme') appTheme: string = 'light';       // 'light' 浅色 / 'dark' 深色
  @StorageLink('appFontSize') appFontSize: number = 17;       // 14 ~ 24 像素范围

  async aboutToAppear() {
    // 1. 拦截盘查 Preferences 首次启动状态
    this.isFirstTime = await StorageManager.getInstance().checkIsFirstLaunch();
    if (this.isFirstTime) {
      this.showWelcomeDialog();
    }

    // 2. 将 Key 严格对齐为课程报告要求的 'theme_mode' 和 'font_size' 字段
    const savedTheme = await StorageManager.getInstance().getSetting('theme_mode', 'light');
    AppStorage.set('appTheme', savedTheme);

    const savedFontSize = await StorageManager.getInstance().getSetting('font_size', '17');
    AppStorage.set('appFontSize', Number(savedFontSize));

    // 3. 从 RelationalStore 读取数据库离线日程单列表
    await this.refreshSchedules();
  }

  // 刷新日程列表数据
  async refreshSchedules() {
    this.scheduleList = await StorageManager.getInstance().queryAllSchedules();
  }

  // 首次进入欢迎弹窗
  showWelcomeDialog() {
    promptAction.showDialog({
      title: '欢迎使用',
      message: '感谢您首次开启智能小助手！我们将使用结构化 RelationalStore 数据库为您守护每一项核心数据安全。',
      buttons: [{ text: '进入应用', color: '#2F6BFA' }]
    }).then(async () => {
      await StorageManager.getInstance().disableFirstLaunchFlag();
      this.isFirstTime = false;
    })
  }

  // 切换主题模式 (KV Store)
  async toggleTheme() {
    this.appTheme = this.appTheme === 'light' ? 'dark' : 'light';
    await StorageManager.getInstance().putSetting('theme_mode', this.appTheme);
  }

  // 切换字号 (KV Store)
  async toggleFontSize() {
    this.appFontSize = this.appFontSize === 17 ? 20 : 17;
    await StorageManager.getInstance().putSetting('font_size', this.appFontSize.toString());
  }

  // 新增日程插入到数据库 (RelationalStore)
  async addSchedule() {
    if (!this.newTitle.trim()) {
      promptAction.showToast({ message: '请输入日程标题' });
      return;
    }

    let now = new Date();
    let timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

    let item: ScheduleItem = {
      title: this.newTitle,
      time: timeStr,
      content: this.newContent
    };

    await StorageManager.getInstance().insertSchedule(item);
    promptAction.showToast({ message: '成功写入关系型数据库' });

    this.newTitle = '';
    this.newContent = '';
    await this.refreshSchedules();
  }

  // 从数据库中抹除某条日程 (RelationalStore)
  async deleteSchedule(id: number) {
    await StorageManager.getInstance().deleteScheduleById(id);
    promptAction.showToast({ message: '已从数据库中安全擦除' });
    await this.refreshSchedules();
  }

  // ========================================================
  // 步骤4：学生信息管理 CRUD（RelationalStore 优化验证）
  // ========================================================

  // 刷新学生列表
  async refreshStudents() {
    const start = Date.now();
    this.studentList = await StorageManager.getInstance().queryAllStudents();
    const elapsed = Date.now() - start;
    if (this.studentList.length > 0) {
      this.queryTime = `${elapsed}ms（共 ${this.studentList.length} 条）`;
    }
  }

  // 新增学生
  async addStudent() {
    if (!this.newStudentName.trim()) {
      promptAction.showToast({ message: '请输入学生姓名' });
      return;
    }
    const age = parseInt(this.newStudentAge) || 20;
    const score = parseFloat(this.newStudentScore) || 80;

    const student: StudentItem = {
      name: this.newStudentName.trim(),
      age: age,
      score: score,
      update_time: Date.now()
    };

    const rowId = await StorageManager.getInstance().insertStudent(student);
    promptAction.showToast({ message: `学生已入库，rowId=${rowId}` });

    this.newStudentName = '';
    this.newStudentAge = '';
    this.newStudentScore = '';
    await this.refreshStudents();
  }

  // 删除学生
  async deleteStudent(id: number) {
    const affected = await StorageManager.getInstance().deleteStudentById(id);
    promptAction.showToast({ message: `已删除，影响行数=${affected}` });
    await this.refreshStudents();
  }

  // 更新学生分数
  async updateScore(id: number) {
    const newScore = Math.floor(Math.random() * 41) + 60; // 60~100 随机分
    const affected = await StorageManager.getInstance().updateStudentScore(id, newScore);
    promptAction.showToast({ message: `分数已更新为 ${newScore}，影响行数=${affected}` });
    await this.refreshStudents();
  }

  // 按姓名模糊搜索（验证索引加速）
  async searchStudents() {
    if (!this.searchName.trim()) {
      await this.refreshStudents();
      return;
    }
    const start = Date.now();
    this.studentList = await StorageManager.getInstance().queryStudentsByName(this.searchName.trim());
    const elapsed = Date.now() - start;
    this.queryTime = `索引查询耗时: ${elapsed}ms（匹配 ${this.studentList.length} 条）`;
    promptAction.showToast({ message: this.queryTime });
  }

  // 调试：重置首次启动标记
  async resetFirstLaunch() {
    const context = getContext(this) as common.Context;
    let pref = await dataPreferences.getPreferences(context, 'AppLaunchPreferences');
    await pref.put('isFirstLaunch', true);
    await pref.delete('appVersion');
    await pref.flush();
    this.isFirstTime = true;
    promptAction.showToast({ message: '已重置，冷启动复现引导页' });
  }

  // 批量插入 100 条测试数据（验证事务加速）
  async batchInsert() {
    promptAction.showToast({ message: '正在事务批量写入 100 条数据...' });
    const elapsed = await StorageManager.getInstance().batchInsertTestData();
    this.batchInsertTime = `批量插入 100 条耗时: ${elapsed}ms（事务优化）`;
    promptAction.showToast({ message: this.batchInsertTime });
    await this.refreshStudents();
  }

  build() {
    // 🛠️ 确保整体最外层也做穿透，不给状态栏和底部导航栏留任何白色缺口
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {

        // ===== TAB 1: 综合数据工作台 =====
        TabContent() {
          Column() {
            // 顶通标题导航栏
            Row() {
              Button('← 返回')
                .fontSize(12).height(28).backgroundColor('#6B7280')
                .margin({ right: 8 })
                .onClick(() => {
                  router.back();
                })
              Text('学生信息管理')
                .fontSize(this.appFontSize + 2)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
                .layoutWeight(1)
              Button('DEBUG')
                .fontSize(10)
                .height(24)
                .fontColor(Color.White)
                .backgroundColor(Color.Red)
                .onClick(() => {
                  this.resetFirstLaunch();
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.appTheme === 'dark' ? '#1E1E24' : '#FFFFFF')
            .shadow({ radius: 2, color: '#10000000', offsetY: 1 })

            Scroll() {
              Column({ space: 16 }) {
                // 偏好设置仓 (KV Store 驱动)
                Column({ space: 12 }) {
                  Text('偏好设置舱 (KV Store)')
                    .fontSize(this.appFontSize - 3)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#2F6BFA')
                    .width('100%')

                  Row() {
                    Text(`当前主题模式: ${this.appTheme === 'dark' ? '深色' : '浅色'}`)
                      .fontSize(this.appFontSize - 2)
                      .fontColor(this.appTheme === 'dark' ? '#E5E7EB' : '#374151')
                    Blank()
                    Button('切换')
                      .fontSize(this.appFontSize - 4)
                      .height(28)
                      .onClick(() => this.toggleTheme())
                  }.width('100%')

                  Row() {
                    Text(`全局字体大小: ${this.appFontSize === 20 ? '放大' : '标准'} (${this.appFontSize}px)`)
                      .fontSize(this.appFontSize - 2)
                      .fontColor(this.appTheme === 'dark' ? '#E5E7EB' : '#374151')
                    Blank()
                    Button('微调')
                      .fontSize(this.appFontSize - 4)
                      .height(28)
                      .backgroundColor('#16A34A')
                      .onClick(() => this.toggleFontSize())
                  }.width('100%')
                }
                .padding(14)
                .borderRadius(12)
                .backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#FFFFFF')

                // 数据表单录入区 (RelationalStore 写入端)
                Column({ space: 10 }) {
                  Text('新建日程数据 (RelationalStore 写入)')
                    .fontSize(this.appFontSize - 3)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#F59E0B')
                    .width('100%')

                  TextInput({ text: this.newTitle, placeholder: '输入日程事项标题...' })
                    .placeholderColor('#9CA3AF')
                    .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#000000')
                    .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#F3F4F6')
                    .onChange((val) => this.newTitle = val)

                  TextArea({ text: this.newContent, placeholder: '补充备注细节描述（可选）...' })
                    .placeholderColor('#9CA3AF')
                    .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#000000')
                    .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#F3F4F6')
                    .height(70)
                    .onChange((val) => this.newContent = val)

                  Button('将本条记录提交通道落盘')
                    .width('100%')
                    .height(38)
                    .fontSize(this.appFontSize - 2)
                    .backgroundColor('#2F6BFA')
                    .onClick(() => this.addSchedule())
                }
                .padding(14)
                .borderRadius(12)
                .backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#FFFFFF')

                // 数据视图呈现展示区
                Column({ space: 8 }) {
                  Text(`动态数据沙箱队列 (共 ${this.scheduleList.length} 条)`)
                    .fontSize(this.appFontSize - 3)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#10B981')
                    .width('100%')

                  if (this.scheduleList.length === 0) {
                    Text('目前关系型数据库表中无任何数据记录')
                      .fontSize(this.appFontSize - 3)
                      .fontColor('#9CA3AF')
                      .margin({ top: 16, bottom: 16 })
                  } else {
                    ForEach(this.scheduleList, (item: ScheduleItem) => {
                      Row() {
                        Column({ space: 4 }) {
                          Row({ space: 6 }) {
                            Text(`[${item.time}]`).fontSize(this.appFontSize - 3).fontColor('#9CA3AF')
                            Text(item.title)
                              .fontSize(this.appFontSize - 1)
                              .fontWeight(FontWeight.Bold)
                              .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
                          }
                          if (item.content) {
                            Text(item.content)
                              .fontSize(this.appFontSize - 3)
                              .fontColor(this.appTheme === 'dark' ? '#9CA3AF' : '#6B7280')
                          }
                        }.alignItems(HorizontalAlign.Start).layoutWeight(1)

                        Button('删除')
                          .fontSize(this.appFontSize - 5)
                          .height(24)
                          .backgroundColor('#EF4444')
                          .onClick(() => this.deleteSchedule(item.id!))
                      }
                      .width('100%')
                      .padding(10)
                      .borderRadius(8)
                      .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#F9FAFB')
                    }, (item: ScheduleItem) => item.id!.toString())
                  }
                }
                .padding(14)
                .borderRadius(12)
                .backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#FFFFFF')

                // ==============================================
                // 步骤4：学生信息管理 (RelationalStore 优化验证)
                // ==============================================
                Column({ space: 10 }) {
                  Text('学生信息管理 (RelationalStore CRUD)')
                    .fontSize(this.appFontSize - 3)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#EF4444')
                    .width('100%')

                  // ---- 4.1 新增学生表单 ----
                  Text('新增学生').fontSize(this.appFontSize - 4).fontColor('#9CA3AF').width('100%')
                  Row({ space: 8 }) {
                    TextInput({ text: this.newStudentName, placeholder: '姓名' })
                      .placeholderColor('#9CA3AF')
                      .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#000000')
                      .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#F3F4F6')
                      .layoutWeight(2)
                      .onChange((val) => this.newStudentName = val)
                    TextInput({ text: this.newStudentAge, placeholder: '年龄' })
                      .placeholderColor('#9CA3AF')
                      .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#000000')
                      .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#F3F4F6')
                      .layoutWeight(1)
                      .onChange((val) => this.newStudentAge = val)
                    TextInput({ text: this.newStudentScore, placeholder: '分数' })
                      .placeholderColor('#9CA3AF')
                      .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#000000')
                      .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#F3F4F6')
                      .layoutWeight(1)
                      .onChange((val) => this.newStudentScore = val)
                  }.width('100%')

                  Button('新增学生（异步写入）')
                    .width('100%').height(36).fontSize(this.appFontSize - 3)
                    .backgroundColor('#EF4444')
                    .onClick(() => this.addStudent())

                  // ---- 4.2 批量插入 + 搜索（优化验证）----
                  Divider().margin({ top: 4, bottom: 4 }).color(this.appTheme === 'dark' ? '#3E3E4A' : '#E5E7EB')

                  Row({ space: 8 }) {
                    Button('批量插入100条测试数据')
                      .fontSize(this.appFontSize - 4).height(34)
                      .backgroundColor('#F59E0B')
                      .layoutWeight(1)
                      .onClick(() => this.batchInsert())
                    Button('查询全部')
                      .fontSize(this.appFontSize - 4).height(34)
                      .backgroundColor('#10B981')
                      .layoutWeight(1)
                      .onClick(async () => {
                        const start = Date.now();
                        this.studentList = await StorageManager.getInstance().queryAllStudents();
                        const elapsed = Date.now() - start;
                        this.queryTime = `全表查询耗时: ${elapsed}ms（共 ${this.studentList.length} 条）`;
                        promptAction.showToast({ message: this.queryTime });
                      })
                  }.width('100%')

                  // 批量插入耗时展示
                  if (this.batchInsertTime) {
                    Text(this.batchInsertTime)
                      .fontSize(this.appFontSize - 5).fontColor('#F59E0B')
                      .fontWeight(FontWeight.Bold).width('100%')
                  }

                  // ---- 4.3 按姓名搜索（验证索引加速）----
                  Row({ space: 8 }) {
                    TextInput({ text: this.searchName, placeholder: '按姓名模糊搜索...' })
                      .placeholderColor('#9CA3AF')
                      .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#000000')
                      .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#F3F4F6')
                      .layoutWeight(1)
                      .onChange((val) => this.searchName = val)
                    Button('索引搜索')
                      .fontSize(this.appFontSize - 4).height(34)
                      .backgroundColor('#8B5CF6')
                      .onClick(() => this.searchStudents())
                  }.width('100%')

                  if (this.queryTime) {
                    Text(this.queryTime)
                      .fontSize(this.appFontSize - 5).fontColor('#8B5CF6')
                      .fontWeight(FontWeight.Bold).width('100%')
                  }

                  // ---- 4.4 学生列表 ----
                  Text(`学生列表（共 ${this.studentList.length} 条）`)
                    .fontSize(this.appFontSize - 4).fontColor('#9CA3AF').width('100%')
                    .margin({ top: 4 })

                  if (this.studentList.length === 0) {
                    Text('暂无数据，请先批量插入或手动新增')
                      .fontSize(this.appFontSize - 4).fontColor('#6B7280')
                      .margin({ top: 8, bottom: 8 })
                  } else {
                    Column({ space: 6 }) {
                      ForEach(this.studentList, (item: StudentItem) => {
                        Row() {
                          Column({ space: 2 }) {
                            Text(`${item.name}`)
                              .fontSize(this.appFontSize - 2).fontWeight(FontWeight.Bold)
                              .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
                            Row({ space: 8 }) {
                              Text(`年龄: ${item.age}`).fontSize(this.appFontSize - 5).fontColor('#6B7280')
                              Text(`分数: ${item.score}`).fontSize(this.appFontSize - 5).fontColor('#6B7280')
                              Text(`ID: ${item.id}`).fontSize(this.appFontSize - 6).fontColor('#9CA3AF')
                            }
                          }.alignItems(HorizontalAlign.Start).layoutWeight(1)

                          Button('改分')
                            .fontSize(this.appFontSize - 6).height(22)
                            .backgroundColor('#10B981')
                            .onClick(() => this.updateScore(item.id!))
                          Button('删除')
                            .fontSize(this.appFontSize - 6).height(22)
                            .backgroundColor('#EF4444')
                            .margin({ left: 4 })
                            .onClick(() => this.deleteStudent(item.id!))
                        }
                        .width('100%').padding(8).borderRadius(6)
                        .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#F9FAFB')
                      }, (item: StudentItem) => `stu_${item.id}_${item.update_time}`)
                    }.width('100%')
                  }
                }
                .padding(14)
                .borderRadius(12)
                .backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#FFFFFF')

              }
              .padding(12)
            }
            .layoutWeight(1)
          }
          .width('100%')
          .height('100%')
          .backgroundColor(this.appTheme === 'dark' ? '#121216' : '#F3F4F6')
        }
        .tabBar(this.TabBuilder('工作台', 0))

        // ===== TAB 2: 学习（占位，可导入你的学生管理页面） =====
        TabContent() {
          Column() {
            Text('学习中心')
              .fontSize(this.appFontSize + 4)
              .fontColor(this.appTheme === 'dark' ? '#FFF' : '#333')
          }
          .width('100%').height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.appTheme === 'dark' ? '#121216' : '#F3F4F6')
        }.tabBar(this.TabBuilder('学习', 1))

        // ===== TAB 3: 🛠️ 扩充复刻的【互动社区】页面 =====
        TabContent() {
          InteractionView()
        }.tabBar(this.TabBuilder('互动', 2))

        // ===== TAB 4: 🛠️ 扩充复刻的【校园集市】页面 =====
        TabContent() {
          MarketView()
        }.tabBar(this.TabBuilder('集市', 3))

        // ===== TAB 5: 完美对接个人中心 =====
        TabContent() {
          ProfilePage()
        }
        .tabBar(this.TabBuilder('我的', 4))
      }
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .layoutWeight(1)
      .scrollable(false) // 关闭手势滑动，确保大底色渲染连贯
      .barHeight(64)     // 适配底部避让安全高度
      .barBackgroundColor(this.appTheme === 'dark' ? '#1E1E24' : Color.White)
      // 🛠️ 穿透核心：向下延伸吞掉底栏系统白边
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
    // 🛠️ 极致细节：将外层大背景渲染层与当前主题完全打通
    .backgroundColor(this.appTheme === 'dark' ? '#1E1E24' : Color.White)
  }

  // 状态栏 Tab 统一构造器
  @Builder TabBuilder(title: string, targetIndex: number) {
    Column() {
      // 纯自绘精美滑块图标（激活时蓝色，非激活时灰度，完美规避图片丢失报错）
      Column()
        .width(22)
        .height(22)
        .backgroundColor(this.currentIndex === targetIndex ? '#2F6BFA' : (this.appTheme === 'dark' ? '#555566' : '#9CA3AF'))
        .borderRadius(6)
        .margin({ bottom: 4 })

      Text(title)
        .fontSize(this.appFontSize - 4) // 状态栏字号完美跟随偏好滑块动态放大
        .fontColor(this.currentIndex === targetIndex ? '#2F6BFA' : (this.appTheme === 'dark' ? '#888888' : '#666666'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.appTheme === 'dark' ? '#1E1E24' : Color.White)
  }
}


// ==========================================
// 🛠️ 子页面 1: 完美复刻的【互动社区】组件
// ==========================================
@Component
struct InteractionView {
  @StorageLink('appTheme') appTheme: string = 'light';
  @StorageLink('appFontSize') appFontSize: number = 17;
  @State activeSubTab: number = 0;

  build() {
    Column() {
      // 1. 顶部操作栏
      Row() {
        Text('互动社区')
          .fontSize(this.appFontSize + 4)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
        Blank()
        // 模拟右侧搜索与发布图标
        Row({ space: 16 }) {
          Circle({ width: 20, height: 20 }).fill(this.appTheme === 'dark' ? '#555566' : '#E5E7EB')
          Rect({ width: 20, height: 20 }).radius(4).fill('#2F6BFA')
        }
      }
      .width('100%').padding(16)

      // 2. 社区分类子 Tab 栏
      Row({ space: 24 }) {
        this.SubTabItem('推荐', 0)
        this.SubTabItem('组队', 1)
        this.SubTabItem('匿名树洞', 2)
        this.SubTabItem('黑板报', 3)
      }
      .width('100%').padding({ left: 16, right: 16, bottom: 8 })

      // 3. 内容滚动沙盒
      Scroll() {
        Column({ space: 14 }) {
          // 热门话题热门 Tags
          Row({ space: 8 }) {
            this.TopicTag('# 2026毕业设计课题 #')
            this.TopicTag('# 食堂新品采样 #')
          }.width('100%').padding({ left: 4 })

          // 复刻贴 1：带精致高亮预约卡片的通知贴
          Column({ space: 10 }) {
            Row({ space: 10 }) {
              Circle({ width: 36, height: 36 }).fill('#F59E0B')
              Column({ space: 2 }) {
                Text('智能机器人协会_小甘').fontSize(this.appFontSize - 2).fontWeight(FontWeight.Bold)
                  .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
                Text('来自官方社团认证').fontSize(11).fontColor('#9CA3AF')
              }.alignItems(HorizontalAlign.Start)
            }.width('100%')

            Text('下周三下午在信教302有无人机全自主飞行演示活动！欢迎各位对低空经济和软硬件控制感兴趣的同学到场交流，点击下方卡片即可抢先预约。')
              .fontSize(this.appFontSize - 1)
              .lineHeight(22)
              .fontColor(this.appTheme === 'dark' ? '#E5E7EB' : '#374151')

            // 复刻图中的蓝色内置预约活动卡片
            Row() {
              Column() {
                Text('JUN').fontSize(10).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
                Text('17').fontSize(18).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
              }
              .backgroundColor('#2F6BFA').padding({ left: 10, right: 10, top: 6, bottom: 6 }).borderRadius(8)
              .margin({ right: 12 })

              Column({ space: 2 }) {
                Text('无人机真机仿真控制讲座').fontSize(this.appFontSize - 2).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                Text('已有 48 人预约 / 限额 60 人').fontSize(11).fontColor('#BFDBFE')
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)

              Button('预约').fontSize(12).height(28).width(56).backgroundColor('#FFFFFF').fontColor('#2F6BFA')
            }
            .backgroundColor('#2F6BFA')
            .padding(12)
            .borderRadius(12)
            .width('100%')

            this.PostActionBar('125', '32')
          }
          .padding(14).borderRadius(16)
          .backgroundColor(this.appTheme === 'dark' ? '#1E1E24' : '#FFFFFF')

          // 复刻贴 2：普通文本吐槽吐槽贴
          Column({ space: 10 }) {
            Row({ space: 10 }) {
              Circle({ width: 36, height: 36 }).fill('#9CA3AF')
              Text('某不愿透露姓名的同学').fontSize(this.appFontSize - 2).fontWeight(FontWeight.Bold)
                .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
            }.width('100%')

            Text('图书馆四楼某些自习室的空调机位声音也太响了，一坐下嗡嗡嗡的根本看不进去代码，希望能有物业老师管管呀。')
              .fontSize(this.appFontSize - 1)
              .lineHeight(22)
              .fontColor(this.appTheme === 'dark' ? '#E5E7EB' : '#374151')

            this.PostActionBar('56', '12')
          }
          .padding(14).borderRadius(16)
          .backgroundColor(this.appTheme === 'dark' ? '#1E1E24' : '#FFFFFF')
        }
        .padding(12)
      }.layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor(this.appTheme === 'dark' ? '#121216' : '#F3F4F6')
  }

  @Builder SubTabItem(name: string, id: number) {
    Column({ space: 4 }) {
      Text(name)
        .fontSize(this.activeSubTab === id ? this.appFontSize + 1 : this.appFontSize - 1)
        .fontWeight(this.activeSubTab === id ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activeSubTab === id ? '#2F6BFA' : '#9CA3AF')
      if (this.activeSubTab === id) {
        Rect().width(16).height(3).fill('#2F6BFA').borderRadius(2)
      }
    }.onClick(() => this.activeSubTab = id)
  }

  @Builder TopicTag(text: string) {
    Text(text)
      .fontSize(this.appFontSize - 4)
      .fontColor('#2F6BFA')
      .backgroundColor(this.appTheme === 'dark' ? '#242430' : '#EBF2FF')
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .borderRadius(12)
  }

  @Builder PostActionBar(likes: string, comments: string) {
    Row() {
      Row({ space: 4 }) {
        Circle({ width: 14, height: 14 }).fill('#9CA3AF')
        Text(likes).fontSize(12).fontColor('#9CA3AF')
      }.margin({ right: 20 })
      Row({ space: 4 }) {
        Rect({ width: 14, height: 14 }).radius(2).fill('#9CA3AF')
        Text(comments).fontSize(12).fontColor('#9CA3AF')
      }
    }.width('100%').margin({ top: 6 })
  }
}


// ==========================================
// 🛠️ 子页面 2: 完美复刻的【校园集市】组件（双列布局）
// ==========================================
@Component
struct MarketView {
  @StorageLink('appTheme') appTheme: string = 'light';
  @StorageLink('appFontSize') appFontSize: number = 17;
  @State activeCat: number = 0;

  build() {
    Column() {
      // 1. 顶部操作头
      Row() {
        Text('校园集市')
          .fontSize(this.appFontSize + 4)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
        Blank()
        // 右侧购物车加发布快连
        Row({ space: 16 }) {
          Circle({ width: 22, height: 22 }).fill('#10B981')
          Circle({ width: 22, height: 22 }).fill('#2F6BFA')
        }
      }
      .width('100%').padding(16)

      // 2. 搜索过滤舱条
      Row() {
        Row({ space: 8 }) {
          Circle({ width: 14, height: 14 }).fill('#9CA3AF')
          Text('搜索闲置宝贝、考研资料...').fontSize(13).fontColor('#9CA3AF')
        }
        .layoutWeight(1)
        .padding(10)
        .borderRadius(10)
        .backgroundColor(this.appTheme === 'dark' ? '#2D2D35' : '#E5E7EB')

        Text('筛选').fontSize(14).fontColor('#2F6BFA').margin({ left: 12 })
      }
      .width('100%').padding({ left: 16, right: 16, bottom: 12 })

      // 3. 瀑布流双列网格卡片区
      Scroll() {
        // 使用高效的纵向双列混排
        Row({ space: 12 }) {
          // 左列
          Column({ space: 12 }) {
            this.MarketProductCard('iPad Air4 64G 考研神器 附带全套无源电容笔 顺滑无延迟', '2450', '3800', '毕业学姐')
            this.MarketProductCard('人体工学转椅 气压杆安全 靠背可调', '80', '199', '宿管寄售')
          }.layoutWeight(1)

          // 右列
          Column({ space: 12 }) {
            this.MarketProductCard('高等数学第七版 下册 九成新 无笔记', '15', '45', '大二学霸')
            this.MarketProductCard('入门级古典吉他 琴弦已换新 赠拨片', '120', '', '吉他社闲置')
          }.layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .alignItems(VerticalAlign.Top)
      }.layoutWeight(1)
    }
    .width('100%').height('100%')
    .backgroundColor(this.appTheme === 'dark' ? '#121216' : '#F3F4F6')
  }

  @Builder MarketProductCard(title: string, price: string, originalPrice: string, sellerTag: string) {
    Column() {
      // 占位图自绘色块（如果是真实项目可在此处放 Image）
      Column()
        .width('100%')
        .height(110)
        .backgroundColor(this.appTheme === 'dark' ? '#3E3E4A' : '#E5E7EB')
        .borderRadius({ topLeft: 12, topRight: 12 })

      Column({ space: 6 }) {
        // 商品名称（多行截断展示）
        Text(title)
          .fontSize(this.appFontSize - 2)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.appTheme === 'dark' ? '#E5E7EB' : '#1F2937')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 价格双显示（现价红，原价划线灰）
        Row({ space: 6 }) {
          Text(`￥${price}`)
            .fontSize(this.appFontSize - 1)
            .fontWeight(FontWeight.Bold)
            .fontColor('#EF4444')

          if (originalPrice) {
            Text(`￥${originalPrice}`)
              .fontSize(11)
              .fontColor('#9CA3AF')
              .decoration({ type: TextDecorationType.LineThrough })
          }
        }.width('100%')

        // 卖家身份标签
        Row({ space: 4 }) {
          Circle({ width: 5, height: 5 }).fill('#10B981')
          Text(sellerTag).fontSize(10).fontColor('#9CA3AF')
        }
      }
      .padding(10)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .borderRadius(12)
    .backgroundColor(this.appTheme === 'dark' ? '#1E1E24' : '#FFFFFF')
    .shadow({ radius: 4, color: '#08000000', offsetY: 1 })
  }
}