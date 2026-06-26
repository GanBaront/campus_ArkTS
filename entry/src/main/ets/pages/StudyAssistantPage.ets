/**
 * StudyAssistantPage — 学习助手页面
 * ===================================
 * 包含四个子模块：
 *   1. 课表（周视图 + 日视图双模式）
 *   2. 空教室查询（占位）
 *   3. 成绩查询
 *   4. 考试安排（占位）
 *
 * 作为 HomePage「学习」Tab 嵌入使用。
 *
 * 实验5 集成：退后台时短时任务自动保护课表编辑草稿，再次进入恢复。
 */
import promptAction from '@ohos.promptAction';
import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

// ==========================================
// 0. 实验5：课表编辑草稿数据结构（短时任务保护）
// ==========================================
interface CourseDraft {
  formName: string;
  formTeacher: string;
  formLocation: string;
  formCredit: string;
  formDayOfWeek: number;
  formSectionStart: number;
  formWeekType: string;
  formSpecificWeek: number;
  isEditingMode: boolean;
  targetEditingId: string;
}

// ==========================================
// 1. 强类型核心数据模型定义
// ==========================================

/** 课程数据模型 — 支持周次过滤（每周/单周/双周/特定周） */
interface CourseItem {
  id: string;            // 唯一标识
  name: string;          // 课程名称
  teacher: string;       // 授课教师
  timeStr: string;       // 展现时间
  sections: string;      // 节次范围
  location: string;      // 教室地点
  credit: number;        // 学分
  dayOfWeek: number;      // 星期 (1-7)
  sectionStart: number;   // 节次时段 (1-5)
  weekType: string;       // 每周 / 单周 / 双周 / 特定周
  specificWeek?: number;  // 特定周的具体周数
  bgColor: string;        // 渲染背景色
  textColor: string;      // 渲染文字颜色
  isStateSlot?: boolean;  // 标记是否为空白占位格
}

interface ScoreItem {
  name: string;
  score: number;
  gpa: number;
  examTime: string;
}

interface DayCalendarItem {
  weekDay: string;
  dayNum: string;
  dayValue: number;
}

interface ActionButtonItem {
  text: string;
  color: string;
}

// ==========================================
// 2. 学习助手根组件（分流 Tab 视窗）
// ==========================================
@Component
export struct StudyAssistantView {
  @State currentSubTab: number = 0

  // 响应全局主题与字号
  @StorageProp('appTheme') appTheme: string = 'light'
  @StorageProp('appFontSize') appFontSize: number = 17

  build() {
    Column() {
      // 顶部极简 Tab 导航栏
      Row() {
        this.TopNavBarItem('课表', 0)
        this.TopNavBarItem('空教室', 1)
        this.TopNavBarItem('成绩查询', 2)
        this.TopNavBarItem('考试安排', 3)
      }
      .width('100%')
      .height(48)
      .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)
      .padding({ left: 16, right: 16 })

      // 分流内容区
      Column() {
        if (this.currentSubTab === 0) {
          CourseScheduleTimelineModule()
        } else if (this.currentSubTab === 1) {
          PlaceholderModule({ title: '空教室快速查询建设中...' })
        } else if (this.currentSubTab === 2) {
          ScoreQueryModule()
        } else {
          PlaceholderModule({ title: '考试安排建设中...' })
        }
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.appTheme === 'dark' ? '#121212' : '#F7F8FA')
  }

  @Builder TopNavBarItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(this.appFontSize)
        .fontWeight(this.currentSubTab === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentSubTab === index ? (this.appTheme === 'dark' ? '#FFFFFF' : '#1C1B1F') : '#9CA3AF')
        .margin({ bottom: 6 })

      Rect()
        .width(28)
        .height(3)
        .fill(this.currentSubTab === index ? '#2F6BFA' : Color.Transparent)
        .borderRadius(1.5)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.End)
    .onClick(() => { this.currentSubTab = index })
  }
}

// ==========================================
// 3. 课表核心模块
// ==========================================
@Component
struct CourseScheduleTimelineModule {
  @State currentWeek: number = 1
  @State selectedDayOfWeek: number = 1
  @State isWeekView: boolean = false

  // 响应全局主题与字号
  @StorageProp('appTheme') appTheme: string = 'light'
  @StorageProp('appFontSize') appFontSize: number = 17

  // 严格限定初始课表只绑定到【第一周】+【星期一】
  @State coursesList: CourseItem[] = [
    { id: 'init_1001', name: '高级人工智能', teacher: '陈教授', timeStr: '10:00', sections: '3-4节', location: '信教 302', credit: 3, dayOfWeek: 1, sectionStart: 2, weekType: '特定周', specificWeek: 1, bgColor: '#EDF4FF', textColor: '#1A56DB' },
    { id: 'init_1002', name: '创业管理学', teacher: '林副教授', timeStr: '14:00', sections: '5-6节', location: '公教楼 508', credit: 2, dayOfWeek: 1, sectionStart: 4, weekType: '特定周', specificWeek: 1, bgColor: '#EEFBF3', textColor: '#16A34A' },
    { id: 'init_1003', name: '机器学习导论(补课)', teacher: '王教授', timeStr: '16:00', sections: '7-8节', location: '信教 405', credit: 3, dayOfWeek: 1, sectionStart: 5, weekType: '特定周', specificWeek: 1, bgColor: '#FFF4EB', textColor: '#D97706' }
  ]

  // 控制通用输入模态框
  @State isShowFormModal: boolean = false
  @State isEditingMode: boolean = false
  @State targetEditingId: string = ''

  // 表单联动变量
  @State formName: string = ''
  @State formTeacher: string = ''
  @State formLocation: string = ''
  @State formCredit: string = '2'
  @State formDayOfWeek: number = 1
  @State formSectionStart: number = 1
  @State formWeekType: string = '每周'
  @State formSpecificWeek: number = 1

  private weekSelectOptions: SelectOption[] = []
  private timeSlots: number[] = [1, 2, 3, 4, 5]
  private gridMatrixIndices: number[] = []

  private calendarDays: DayCalendarItem[] = [
    { weekDay: '一', dayNum: '30', dayValue: 1 },
    { weekDay: '二', dayNum: '31', dayValue: 2 },
    { weekDay: '三', dayNum: '01', dayValue: 3 },
    { weekDay: '四', dayNum: '02', dayValue: 4 },
    { weekDay: '五', dayNum: '03', dayValue: 5 },
    { weekDay: '六', dayNum: '04', dayValue: 6 },
    { weekDay: '日', dayNum: '05', dayValue: 7 }
  ]

  aboutToAppear() {
    for (let i = 1; i <= 20; i++) {
      this.weekSelectOptions.push({ value: `第 ${i} 周` })
    }
    for (let j = 0; j < 35; j++) {
      this.gridMatrixIndices.push(j);
    }
    // 实验5：尝试恢复未完成的课表编辑草稿（短时任务保护的数据）
    this.loadFormDraft();
  }

  // 实验5：实时保存课表编辑草稿到 Preferences（退后台短时任务保护）
  private async saveFormDraft(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const pref = await dataPreferences.getPreferences(ctx.getApplicationContext(), 'AppLaunchPreferences');
      const draft: CourseDraft = {
        formName: this.formName,
        formTeacher: this.formTeacher,
        formLocation: this.formLocation,
        formCredit: this.formCredit,
        formDayOfWeek: this.formDayOfWeek,
        formSectionStart: this.formSectionStart,
        formWeekType: this.formWeekType,
        formSpecificWeek: this.formSpecificWeek,
        isEditingMode: this.isEditingMode,
        targetEditingId: this.targetEditingId
      };
      await pref.put('draft_course_form', JSON.stringify(draft));
      await pref.flush();
    } catch (e) {
      console.error('课表草稿保存失败: ' + JSON.stringify(e));
    }
  }

  // 实验5：从 Preferences 恢复未完成的课表编辑草稿
  private async loadFormDraft(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const pref = await dataPreferences.getPreferences(ctx.getApplicationContext(), 'AppLaunchPreferences');
      const raw = await pref.get('draft_course_form', '') as string;
      if (raw) {
        const draft: CourseDraft = JSON.parse(raw) as CourseDraft;
        // 恢复表单字段
        this.formName = draft.formName || '';
        this.formTeacher = draft.formTeacher || '';
        this.formLocation = draft.formLocation || '';
        this.formCredit = draft.formCredit || '2';
        this.formDayOfWeek = draft.formDayOfWeek || 1;
        this.formSectionStart = draft.formSectionStart || 1;
        this.formWeekType = draft.formWeekType || '每周';
        this.formSpecificWeek = draft.formSpecificWeek || 1;
        this.isEditingMode = draft.isEditingMode || false;
        this.targetEditingId = draft.targetEditingId || '';
        // 打开表单让用户继续编辑
        this.isShowFormModal = true;
        promptAction.showToast({ message: '已恢复未完成的课表草稿' });
      }
    } catch (e) {
      console.error('课表草稿恢复失败: ' + JSON.stringify(e));
    }
  }

  // 实验5：清除已保存的课表草稿（提交或取消后）
  private async clearFormDraft(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const pref = await dataPreferences.getPreferences(ctx.getApplicationContext(), 'AppLaunchPreferences');
      await pref.delete('draft_course_form');
      await pref.flush();
    } catch (e) {
      console.error('课表草稿清除失败: ' + JSON.stringify(e));
    }
  }

  // 核心数据检索过滤器：加入严格的周次匹配，完美留白
  private getProcessedSlotDataByDay(dayVal: number, slotNum: number): CourseItem {
    let targetWeek = this.currentWeek;
    let foundCourse: CourseItem | null = null;

    for (let i = 0; i < this.coursesList.length; i++) {
      let c = this.coursesList[i];
      if (c.dayOfWeek === dayVal && c.sectionStart === slotNum) {
        let isMatch = false;
        if (c.weekType === '每周') {
          isMatch = true;
        } else if (c.weekType === '单周') {
          isMatch = (targetWeek % 2 === 1);
        } else if (c.weekType === '双周') {
          isMatch = (targetWeek % 2 === 0);
        } else if (c.weekType === '特定周') {
          isMatch = (c.specificWeek === targetWeek);
        }
        if (isMatch) {
          foundCourse = c;
          break;
        }
      }
    }

    if (foundCourse !== null) {
      // 深度拷贝返回克隆体，防止直接共享同一引用干扰双视图同步
      return {
        id: foundCourse.id, name: foundCourse.name, teacher: foundCourse.teacher,
        timeStr: foundCourse.timeStr, sections: foundCourse.sections, location: foundCourse.location,
        credit: foundCourse.credit, dayOfWeek: foundCourse.dayOfWeek, sectionStart: foundCourse.sectionStart,
        weekType: foundCourse.weekType, specificWeek: foundCourse.specificWeek,
        bgColor: foundCourse.bgColor, textColor: foundCourse.textColor, isStateSlot: false
      };
    }

    // 未匹配到课程，生成具备独立坐标和 ID 的空白预设插槽格
    let timeText = '08:00'
    if (slotNum === 2) timeText = '10:00'
    else if (slotNum === 3) timeText = '12:00'
    else if (slotNum === 4) timeText = '14:00'
    else if (slotNum === 5) timeText = '16:00'

    if (slotNum === 1) {
      return { id: `empty-1-${dayVal}-${targetWeek}`, name: '晨读/自主预习', teacher: '', timeStr: '08:00', sections: '', location: '', credit: 0, dayOfWeek: dayVal, sectionStart: 1, weekType: '每周', bgColor: '#FFFFFF', textColor: '#9CA3AF', isStateSlot: true }
    } else if (slotNum === 3) {
      return { id: `empty-3-${dayVal}-${targetWeek}`, name: '午间休息', teacher: '', timeStr: '12:00', sections: '', location: '', credit: 0, dayOfWeek: dayVal, sectionStart: 3, weekType: '每周', bgColor: '#FFFFFF', textColor: '#9CA3AF', isStateSlot: true }
    } else {
      return { id: `empty-${slotNum}-${dayVal}-${targetWeek}`, name: '暂无排课安排', teacher: '', timeStr: timeText, sections: '', location: '', credit: 0, dayOfWeek: dayVal, sectionStart: slotNum, weekType: '每周', bgColor: '#FFFFFF', textColor: '#E5E7EB', isStateSlot: true }
    }
  }

  private getProcessedSlotData(slotNum: number): CourseItem {
    return this.getProcessedSlotDataByDay(this.selectedDayOfWeek, slotNum);
  }

  // 三点快捷菜单选项
  private openTopActionMenu() {
    try {
      let btn1: ActionButtonItem = { text: '导出课表数据快照', color: '#1F2937' };
      let btn2: ActionButtonItem = { text: this.isWeekView ? '当日课表' : '一周课表', color: '#1F2937' };

      let menuButtons: [promptAction.Button, promptAction.Button] = [
        btn1 as promptAction.Button,
        btn2 as promptAction.Button
      ];

      promptAction.showActionMenu({
        title: '课表视图及数据管理',
        buttons: menuButtons
      }).then((data) => {
        if (data.index === 0) {
          this.exportScheduleData();
        } else if (data.index === 1) {
          this.isWeekView = !this.isWeekView;
        }
      }).catch((err: Error) => {
        console.error('Menu failed: ' + err.message);
      })
    } catch (e) {
      console.error('ActionMenu Exception block');
    }
  }

  // 行程轻触操作菜单（涵盖修改与移除逻辑）
  private openCourseActionSheet(course: CourseItem) {
    if (course.isStateSlot) return

    try {
      let b1: ActionButtonItem = { text: '设定 10 分钟前快速提醒', color: '#2F6BFA' };
      let b2: ActionButtonItem = { text: '修改日程信息', color: '#1F2937' };
      let b3: ActionButtonItem = { text: '从我的课表删除', color: '#FA5151' };

      let actionButtons: [promptAction.Button, promptAction.Button, promptAction.Button] = [
        b1 as promptAction.Button,
        b2 as promptAction.Button,
        b3 as promptAction.Button
      ];

      promptAction.showActionMenu({
        title: `管理日程: ${course.name}`,
        buttons: actionButtons
      }).then((data) => {
        if (data.index === 0) {
          promptAction.showToast({ message: `已成功设定【${course.name}】提醒` })
        } else if (data.index === 1) {
          this.isEditingMode = true
          this.targetEditingId = course.id
          this.formName = course.name
          this.formTeacher = course.teacher
          this.formLocation = course.location
          this.formCredit = course.credit.toString()
          this.formDayOfWeek = course.dayOfWeek
          this.formSectionStart = course.sectionStart
          this.formWeekType = course.weekType
          this.formSpecificWeek = course.specificWeek || 1
          this.isShowFormModal = true
        } else if (data.index === 2) {
          // 深度剔除：改变深层指针结构，达成即时刷新同步的目的
          this.coursesList = this.coursesList.filter(item => item.id !== course.id);
          promptAction.showToast({ message: '课程已成功移除' });
        }
      }).catch((err: Error) => {
        console.error('Action trace error: ' + err.message)
      })
    } catch (e) {
      console.error('ActionSheet safety block');
    }
  }

  private openAddModal() {
    this.isEditingMode = false
    this.formName = ''
    this.formTeacher = ''
    this.formLocation = ''
    this.formCredit = '2'
    this.formDayOfWeek = this.selectedDayOfWeek
    this.formSectionStart = 2
    this.formWeekType = '每周'
    this.formSpecificWeek = this.currentWeek
    this.isShowFormModal = true
  }

  exportScheduleData() {
    let dialogBtn: ActionButtonItem = { text: '确信', color: '#2F6BFA' };
    promptAction.showDialog({
      title: '教务课表快照导出成功',
      message: `本地安全离线数据包已建立完成。\n当前并发排课记录数: ${this.coursesList.length} 条。`,
      buttons: [dialogBtn as promptAction.Button]
    }).catch(() => {})
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        // 顶部操作栏
        Row() {
          Select(this.weekSelectOptions)
            .selected(this.currentWeek - 1)
            .value(`第 ${this.currentWeek} 周 (${this.currentWeek % 2 === 1 ? '单周' : '双周'})`)
            .font({ size: this.appFontSize, weight: FontWeight.Bold })
            .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
            .onSelect((index: number) => {
              this.currentWeek = index + 1
            })

          Blank()

          // 三点（更多）图标
          Image($r('app.media.more')).width(22).height(22).margin({ right: 16 })
            .onClick(() => { this.openTopActionMenu() })

          // 【已修改】将原有 app.media.home 房子图标改为 app.media.add 加号图标
          Image($r('app.media.add')).width(22).height(22)
            .onClick(() => { this.openAddModal() })
        }
        .width('92%').margin({ top: 10, bottom: 8 })

        if (!this.isWeekView) {
          // ==========================================
          // 视图 A：当日课表时间轴模式
          // ==========================================
          Row() {
            ForEach(this.calendarDays, (dayItem: DayCalendarItem) => {
              Column({ space: 6 }) {
                Text(dayItem.weekDay)
                  .fontSize(12)
                  .fontColor(this.selectedDayOfWeek === dayItem.dayValue ? '#2F6BFA' : '#9CA3AF')

                Stack() {
                  if (this.selectedDayOfWeek === dayItem.dayValue) {
                    Circle().width(28).height(28).fill('#2F6BFA')
                  }
                  Text(dayItem.dayNum)
                    .fontSize(this.appFontSize - 2)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.selectedDayOfWeek === dayItem.dayValue ? Color.White : (this.appTheme === 'dark' ? '#CCCCCC' : '#1F2937'))
                }
              }
              .layoutWeight(1)
              .onClick(() => { this.selectedDayOfWeek = dayItem.dayValue })
            }, (dayItem: DayCalendarItem) => dayItem.dayValue.toString() + '_' + this.currentWeek.toString())
          }
          .width('100%')
          .padding({ top: 12, bottom: 12, left: 10, right: 10 })
          .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)
          .margin({ bottom: 12 })

          Scroll() {
            Column() {
              // 通过组合唯一标识字串，强制 ForEach 在任何数据突变时重新计算状态
              ForEach(this.timeSlots, (slotNum: number) => {
                this.RenderTimeLineRow(this.getProcessedSlotData(slotNum))
              }, (slotNum: number) => slotNum.toString() + '_' + this.selectedDayOfWeek.toString() + '_' + this.coursesList.length.toString() + '_' + Date.now().toString())
              this.QuickSearchBottomCard()
            }
            .width('92%')
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        } else {
          // ==========================================
          // 视图 B：标准“一周课表”矩阵网格模式
          // ==========================================
          Column() {
            Row() {
              Text('').width('12%').height('100%')

              ForEach(['一', '二', '三', '四', '五', '六', '日'], (weekName: string) => {
                Text(`周${weekName}`)
                  .fontSize(this.appFontSize - 5)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.appTheme === 'dark' ? '#CCCCCC' : '#4B5563')
                  .textAlign(TextAlign.Center)
                  .layoutWeight(1)
              }, (weekName: string) => weekName)
            }
            .width('100%')
            .height(32)
            .backgroundColor(this.appTheme === 'dark' ? '#1E2A3A' : '#EBF2FF')
            .borderRadius({ topLeft: 8, topRight: 8 })

            Row() {
              Column() {
                ForEach(this.timeSlots, (slotNum: number) => {
                  Column({ space: 2 }) {
                    Text(`${slotNum}`)
                      .fontSize(this.appFontSize - 3)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
                    Text(slotNum === 1 ? '08:00' : slotNum === 2 ? '10:00' : slotNum === 3 ? '12:00' : slotNum === 4 ? '14:00' : '16:00')
                      .fontSize(this.appFontSize - 7)
                      .fontColor('#9CA3AF')
                  }
                  .width('100%')
                  .height(76)
                  .justifyContent(FlexAlign.Center)
                  .border({ width: { bottom: 1 }, color: this.appTheme === 'dark' ? '#2C2C2C' : '#F3F4F6' })
                }, (slotNum: number) => slotNum.toString())
              }
              .width('12%')
              .height('100%')
              .backgroundColor(this.appTheme === 'dark' ? '#1A1A1A' : '#FAFAFA')

              // 右侧主格：高频率刷新机制绑定
              Grid() {
                ForEach(this.gridMatrixIndices, (matrixIndex: number) => {
                  GridItem() {
                    this.RenderGridMatrixCell(matrixIndex)
                  }
                }, (matrixIndex: number) => matrixIndex.toString() + '_' + this.coursesList.length.toString() + '_' + this.currentWeek.toString())
              }
              .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
              .rowsTemplate('1fr 1fr 1fr 1fr 1fr')
              .layoutWeight(1)
              .height('100%')
            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('96%')
          .layoutWeight(1)
          .margin({ top: 4, bottom: 8 })
          .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)
          .borderRadius(8)
          .shadow({ radius: 6, color: '#08000000' })
        }
      }
      .width('100%').height('100%')

      if (this.isShowFormModal) {
        this.CourseFormModal()
      }
    }
  }

  @Builder RenderGridMatrixCell(matrixIndex: number) {
    Column() {
      this.RenderCellCore(Math.floor(matrixIndex % 7) + 1, Math.floor(matrixIndex / 7) + 1)
    }
  }

  @Builder RenderCellCore(dayVal: number, slotNum: number) {
    Column() {
      this.RenderFinalCellLayout(this.getProcessedSlotDataByDay(dayVal, slotNum))
    }
  }

  @Builder RenderFinalCellLayout(course: CourseItem) {
    Column() {
      if (course.isStateSlot) {
        Column() {
          Text('+').fontColor('#E5E7EB').fontSize(14)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.isEditingMode = false
          this.formName = ''
          this.formTeacher = ''
          this.formLocation = ''
          this.formCredit = '2'
          this.formDayOfWeek = course.dayOfWeek
          this.formSectionStart = course.sectionStart
          this.formWeekType = this.currentWeek === 1 ? '每周' : '特定周'
          this.formSpecificWeek = this.currentWeek
          this.isShowFormModal = true
        })
      } else {
        Column() {
          Text(course.name)
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(course.textColor)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 2 })

          Text(course.location)
            .fontSize(8)
            .fontColor(course.textColor)
            .maxLines(2)
            .opacity(0.8)
        }
        .width('94%')
        .height('92%')
        .padding(4)
        .backgroundColor(course.bgColor)
        .borderRadius(5)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .onClick(() => { this.openCourseActionSheet(course) })
      }
    }
    .width('100%')
    .height(76)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .border({ width: { right: 1, bottom: 1 }, color: this.appTheme === 'dark' ? '#2C2C2C' : '#F3F4F6' })
  }

  @Builder RenderTimeLineRow(course: CourseItem) {
    Row() {
      Column() {
        Text(course.timeStr)
          .fontSize(12)
          .fontColor('#9CA3AF')
          .margin({ bottom: 4 })

        Circle().width(6).height(6).fill(course.isStateSlot ? '#D1D5DB' : '#2F6BFA')
        Rect().width(1).layoutWeight(1).fill('#E5E7EB').margin({ top: 4 })
      }
      .width('16%')
      .height(105)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)

      Column() {
        if (course.isStateSlot) {
          Column() {
            Text(course.name)
              .fontSize(14)
              .fontStyle(FontStyle.Italic)
              .fontColor(course.name.includes('暂无') ? '#E5E7EB' : '#9CA3AF')
          }
          .width('100%')
          .height(72)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 16 })
          .border({ width: 1, color: '#E5E7EB', radius: 14, style: BorderStyle.Dashed })
          .backgroundColor(course.name.includes('暂无') ? 'transparent' : '#F9FAFB')
          .onClick(() => {
            this.isEditingMode = false
            this.formName = ''
            this.formTeacher = ''
            this.formLocation = ''
            this.formCredit = '2'
            this.formDayOfWeek = course.dayOfWeek
            this.formSectionStart = course.sectionStart
            this.formWeekType = this.currentWeek === 1 ? '每周' : '特定周'
            this.formSpecificWeek = this.currentWeek
            this.isShowFormModal = true
          })
        } else {
          Row() {
            Column({ space: 5 }) {
              Text(course.name)
                .fontSize(this.appFontSize)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')

              Text(`${course.teacher} | ${course.location} [${course.credit}学分]`)
                .fontSize(this.appFontSize - 4)
                .fontColor(this.appTheme === 'dark' ? '#AAAAAA' : '#6B7280')

              Text(course.weekType === '特定周' ? `排课周期: 第 ${course.specificWeek} 周` : `排课周期: ${course.weekType}`)
                .fontSize(10)
                .fontColor(course.textColor)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            if (course.sections) {
              Text(course.sections)
                .fontSize(11)
                .fontColor(course.textColor)
                .backgroundColor(course.bgColor)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .borderRadius(6)
            }
          }
          .width('100%')
          .height(88)
          .padding(14)
          .backgroundColor(course.bgColor)
          .borderRadius(14)
          .shadow({ radius: 4, color: '#04000000', offsetY: 2 })
          .onClick(() => { this.openCourseActionSheet(course) })
        }
      }
      .layoutWeight(1)
      .margin({ left: 4, bottom: 16 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder QuickSearchBottomCard() {
    Row() {
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Image($r('app.media.room')).width(16).height(16)
          Text('空教室快速查询').fontSize(this.appFontSize - 2).fontWeight(FontWeight.Bold)
            .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
        }
        Text('公共教学楼: 12 间 | 信息教学楼: 04 间').fontSize(this.appFontSize - 4)
          .fontColor(this.appTheme === 'dark' ? '#AAAAAA' : '#6B7280')
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)

      Text('实时更新').fontSize(this.appFontSize - 5).fontColor('#6B7280').backgroundColor('#E5E7EB')
        .padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(6)
    }
    .width('100%')
    .padding(14)
    .margin({ top: 16, bottom: 34 })
    .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)
    .borderRadius(14)
    .shadow({ radius: 6, color: '#06000000', offsetY: 2 })
  }

  // ==========================================
  // 5. 万能增改表单模块（实时深度重构解构机制）
  // ==========================================
  @Builder CourseFormModal() {
    Stack({ alignContent: Alignment.Center }) {
      Rect().width('100%').height('100%').fill('#75000000')
        .onClick(() => { this.isShowFormModal = false })

      Column({ space: 14 }) {
        Text(this.isEditingMode ? '完善调整日程数据' : '自填手动排课入库')
          .fontSize(this.appFontSize).fontWeight(FontWeight.Bold)
          .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')

        TextInput({ text: this.formName, placeholder: '请输入课程名称（必填）' })
          .height(42).onChange(v => { this.formName = v; this.saveFormDraft(); })

        TextInput({ text: this.formTeacher, placeholder: '请输入授课教师姓名' })
          .height(42).onChange(v => { this.formTeacher = v; this.saveFormDraft(); })

        TextInput({ text: this.formLocation, placeholder: '请输入上课具体教室（如信教302）' })
          .height(42).onChange(v => { this.formLocation = v; this.saveFormDraft(); })

        TextInput({ text: this.formCredit, placeholder: '对应分配学分' })
          .type(InputType.Number).height(42).onChange(v => { this.formCredit = v; this.saveFormDraft(); })

        Row() {
          Text('上课星期:').fontSize(this.appFontSize - 2).fontColor('#4B5563')
          Counter() {
            Text(`周 ${['一','二','三','四','五','六','日'][this.formDayOfWeek - 1]}`).fontSize(this.appFontSize - 3).fontWeight(FontWeight.Bold)
          }
          .onInc(() => { if (this.formDayOfWeek < 7) { this.formDayOfWeek++; this.saveFormDraft(); } })
          .onDec(() => { if (this.formDayOfWeek > 1) { this.formDayOfWeek--; this.saveFormDraft(); } })
        }.width('100%').justifyContent(FlexAlign.SpaceBetween)

        Row() {
          Text('时段节次:').fontSize(this.appFontSize - 2).fontColor('#4B5563')
          Counter() {
            Text(`时段 ${this.formSectionStart}`).fontSize(this.appFontSize - 3).fontWeight(FontWeight.Bold)
          }
          .onInc(() => { if (this.formSectionStart < 5) { this.formSectionStart++; this.saveFormDraft(); } })
          .onDec(() => { if (this.formSectionStart > 1) { this.formSectionStart--; this.saveFormDraft(); } })
        }.width('100%').justifyContent(FlexAlign.SpaceBetween)

        Column({ space: 8 }) {
          Text('排课周次选择:').fontSize(this.appFontSize - 2).fontColor('#4B5563').width('100%')

          Row({ space: 10 }) {
            Select([{ value: '每周' }, { value: '单周' }, { value: '双周' }, { value: '特定周' }])
              .selected(this.formWeekType === '每周' ? 0 : this.formWeekType === '单周' ? 1 : this.formWeekType === '双周' ? 2 : 3)
              .value(this.formWeekType)
              .font({ size: 13 })
              .layoutWeight(1)
              .height(40)
              .onSelect((idx: number, value?: string) => {
                if (value) { this.formWeekType = value; this.saveFormDraft(); }
              })

            if (this.formWeekType === '特定周') {
              Select(this.weekSelectOptions)
                .selected(this.formSpecificWeek - 1)
                .value(`第 ${this.formSpecificWeek} 周`)
                .font({ size: 13 })
                .layoutWeight(1)
                .height(40)
                .onSelect((idx: number) => {
                  this.formSpecificWeek = idx + 1;
                  this.saveFormDraft();
                })
            }
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)

        Row({ space: 16 }) {
          Button('取消').layoutWeight(1).backgroundColor('#F3F4F6').fontColor('#4B5563')
            .onClick(() => { this.clearFormDraft(); this.isShowFormModal = false })

          Button('写入课表数据库').layoutWeight(1).backgroundColor('#2F6BFA')
            .onClick(() => {
              if (!this.formName.trim() || !this.formLocation.trim()) {
                promptAction.showToast({ message: '课程名称和地点不能为空' })
                return
              }

              let calculatedTime = '08:00'
              let calculatedSec = '1-2节'
              let colorSet = ['#EDF4FF', '#1A56DB']
              if (this.formSectionStart === 2) { calculatedTime = '10:00'; calculatedSec = '3-4节'; colorSet = ['#EDF4FF', '#1A56DB'] }
              else if (this.formSectionStart === 3) { calculatedTime = '12:00'; calculatedSec = '中午时段'; colorSet = ['#F9FAFB', '#9CA3AF'] }
              else if (this.formSectionStart === 4) { calculatedTime = '14:00'; calculatedSec = '5-6节'; colorSet = ['#EEFBF3', '#16A34A'] }
              else if (this.formSectionStart === 5) { calculatedTime = '16:00'; calculatedSec = '7-8节'; colorSet = ['#FFF4EB', '#D97706'] }

              // ==================================================
              // 解决不同步的终极机制：强制进行深解构并产生全新引用
              // ==================================================
              if (this.isEditingMode) {
                // 修改：使用全新内存块重组对象
                this.coursesList = this.coursesList.map(item => {
                  if (item.id === this.targetEditingId) {
                    return {
                      id: 'course_' + Date.now().toString(), // 刷出一个带有新标记的ID，打破缓存
                      name: this.formName,
                      teacher: this.formTeacher || '未知教师',
                      timeStr: calculatedTime,
                      sections: calculatedSec,
                      location: this.formLocation,
                      credit: Number(this.formCredit) || 2,
                      dayOfWeek: this.formDayOfWeek,
                      sectionStart: this.formSectionStart,
                      weekType: this.formWeekType,
                      specificWeek: this.formWeekType === '特定周' ? this.formSpecificWeek : undefined,
                      bgColor: colorSet[0],
                      textColor: colorSet[1]
                    } as CourseItem;
                  }
                  return item;
                });
              } else {
                // 新增：直接展开赋值触发整体侦听
                let updatedList: CourseItem[] = [];
                for (let i = 0; i < this.coursesList.length; i++) {
                  updatedList.push(this.coursesList[i]);
                }
                updatedList.push({
                  id: 'course_' + Date.now().toString() + '_add',
                  name: this.formName, teacher: this.formTeacher || '默认教师',
                  timeStr: calculatedTime, sections: calculatedSec, location: this.formLocation,
                  credit: Number(this.formCredit) || 2, dayOfWeek: this.formDayOfWeek,
                  sectionStart: this.formSectionStart, weekType: this.formWeekType,
                  specificWeek: this.formWeekType === '特定周' ? this.formSpecificWeek : undefined,
                  bgColor: colorSet[0], textColor: colorSet[1]
                });
                this.coursesList = updatedList;
              }
              this.clearFormDraft();  // 实验5：保存成功后清除草稿
              this.isShowFormModal = false
            })
        }.margin({ top: 10 })
      }
      .width('88%').padding(20)
      .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White).borderRadius(16)
    }
    .width('100%').height('100%')
  }
}

// ==========================================
// 4. 绩点成绩查询子模块
// ==========================================
@Component
struct ScoreQueryModule {
  @State displayScores: ScoreItem[] = [
    { name: '高级人工智能', score: 92, gpa: 4.2, examTime: '2026-01-10' },
    { name: '软件架构 design', score: 88, gpa: 3.8, examTime: '2026-01-12' },
    { name: '创业管理学', score: 95, gpa: 4.5, examTime: '2026-01-15' }
  ]

  // 响应全局主题与字号
  @StorageProp('appTheme') appTheme: string = 'light'
  @StorageProp('appFontSize') appFontSize: number = 17

  build() {
    Column() {
      List() {
        ForEach(this.displayScores, (score: ScoreItem) => {
          ListItem() {
            Row() {
              Column({ space: 4 }) {
                Text(score.name).fontSize(this.appFontSize - 1).fontWeight(FontWeight.Bold)
                  .fontColor(this.appTheme === 'dark' ? '#FFFFFF' : '#1F2937')
                Text(`绩点: ${score.gpa} | 评定时间: ${score.examTime}`).fontSize(this.appFontSize - 4)
                  .fontColor('#9CA3AF')
              }.alignItems(HorizontalAlign.Start)
              Blank()
              Text(`${score.score}`).fontSize(this.appFontSize + 4).fontColor('#2F6BFA').fontWeight(FontWeight.Bold)
            }
            .width('100%').padding(16)
            .backgroundColor(this.appTheme === 'dark' ? '#1E1E1E' : Color.White)
            .borderRadius(14).margin({ bottom: 10 })
          }
        }, (score: ScoreItem) => score.name)
      }.width('92%').margin({ top: 12 })
    }.width('100%').height('100%')
  }
}

// ==========================================
// 6. 极简底层占位组件定义
// ==========================================
@Component
struct PlaceholderModule {
  private title: string = '内容加载中...'

  // 响应全局主题与字号
  @StorageProp('appTheme') appTheme: string = 'light'
  @StorageProp('appFontSize') appFontSize: number = 17

  build() {
    Column() {
      Text(this.title).fontSize(this.appFontSize - 3).fontColor('#9CA3AF')
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
    .backgroundColor(this.appTheme === 'dark' ? '#121212' : Color.Transparent)
  }
}