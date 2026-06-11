// entry/src/main/ets/utils/StorageManager.ets
import dataPreferences from '@ohos.data.preferences';
import distributedKVStore from '@ohos.data.distributedKVStore';
import relativedb from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

// 严格对应实验报告要求的学生数据结构
export interface StudentItem {
  id?: number;
  name: string;
  age: number;
  score: number;
  update_time: number;
}

// 🛠️ 精准修复：匹配主页 Index.ets 实际依赖的日程数据结构（将 location 修正为 content）
export interface ScheduleItem {
  id?: number;
  title: string;
  time: string;
  content: string;
}

export class StorageManager {
  private static instance: StorageManager | null = null;
  private preferences: dataPreferences.Preferences | null = null;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private rdbStore: relativedb.RdbStore | null = null;

  // 关系型数据库配置
  private readonly STORE_CONFIG: relativedb.StoreConfig = {
    name: 'CampusStudent.db',
    securityLevel: relativedb.SecurityLevel.S1
  };
  private readonly TABLE_NAME = 'student';

  // 核心建表 SQL
  private readonly SQL_CREATE_TABLE = `
    CREATE TABLE IF NOT EXISTS ${this.TABLE_NAME} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      age INTEGER NOT NULL,
      score REAL NOT NULL,
      update_time INTEGER NOT NULL
    );
  `;

  private readonly SQL_CREATE_INDEX = `
    CREATE INDEX IF NOT EXISTS idx_name ON ${this.TABLE_NAME}(name);
  `;

  private constructor() {}

  public static getInstance(): StorageManager {
    if (!StorageManager.instance) {
      StorageManager.instance = new StorageManager();
    }
    return StorageManager.instance;
  }

  /**
   * 异步初始化三大存储引擎
   */
  public async init(context: common.Context): Promise<void> {
    try {
      this.preferences = await dataPreferences.getPreferences(context, 'AppLaunchPreferences');

      const kvManagerConfig: distributedKVStore.KVManagerConfig = {
        context: context,
        bundleName: context.applicationInfo.name
      };
      const kvManager = distributedKVStore.createKVManager(kvManagerConfig);
      const kvOptions: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: false,
        backup: false,
        autoSync: false,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };
      this.kvStore = await kvManager.getKVStore('UserSettingsStore', kvOptions) as distributedKVStore.SingleKVStore;

      this.rdbStore = await relativedb.getRdbStore(context, this.STORE_CONFIG);
      await this.rdbStore.executeSql(this.SQL_CREATE_TABLE);
      await this.rdbStore.executeSql(this.SQL_CREATE_INDEX);
      console.info('StorageManager: 关系型数据库及索引初始化成功');
    } catch (err) {
      console.error('StorageManager: 初始化失败');
    }
  }

  // ========================================================
  // 模块 1：首次启动标记 (Preferences)
  // ========================================================
  public async checkIsFirstLaunch(): Promise<boolean> {
    if (!this.preferences) return false;
    return await this.preferences.get('isFirstLaunch', true) as boolean;
  }

  public async disableFirstLaunchFlag(): Promise<void> {
    if (!this.preferences) return;
    await this.preferences.put('isFirstLaunch', false);
    await this.preferences.flush();
  }

  // ========================================================
  // 模块 2：用户设置 (KV Store)
  // ========================================================
  public async putSetting(key: string, value: string): Promise<void> {
    if (!this.kvStore) return;
    await this.kvStore.put(key, value);
  }

  public async getSetting(key: string, defaultValue: string): Promise<string> {
    if (!this.kvStore) return defaultValue;
    try {
      return await this.kvStore.get(key) as string;
    } catch (err) {
      return defaultValue;
    }
  }

  // ========================================================
  // 模块 3：学生信息管理核心增删改查 (RelationalStore)
  // ========================================================
  public async insertStudent(student: StudentItem): Promise<number> {
    if (!this.rdbStore) throw new Error('RdbStore 未就绪');
    const valueBucket: relativedb.ValuesBucket = {
      'name': student.name,
      'age': student.age,
      'score': student.score,
      'update_time': new Date().getTime()
    };
    return await this.rdbStore.insert(this.TABLE_NAME, valueBucket);
  }

  public async deleteStudentById(id: number): Promise<number> {
    if (!this.rdbStore) return 0;
    let predicates = new relativedb.RdbPredicates(this.TABLE_NAME);
    predicates.equalTo('id', id);
    return await this.rdbStore.delete(predicates);
  }

  public async updateStudentScore(id: number, newScore: number): Promise<number> {
    if (!this.rdbStore) return 0;
    const valueBucket: relativedb.ValuesBucket = {
      'score': newScore,
      'update_time': new Date().getTime()
    };
    let predicates = new relativedb.RdbPredicates(this.TABLE_NAME);
    predicates.equalTo('id', id);
    return await this.rdbStore.update(valueBucket, predicates);
  }

  public async queryAllStudents(): Promise<StudentItem[]> {
    if (!this.rdbStore) return [];
    let predicates = new relativedb.RdbPredicates(this.TABLE_NAME);
    predicates.orderByDesc('update_time');
    return await this.fetchResultSet(predicates);
  }

  public async queryStudentsByName(name: string): Promise<StudentItem[]> {
    if (!this.rdbStore) return [];
    let predicates = new relativedb.RdbPredicates(this.TABLE_NAME);
    predicates.contains('name', name);
    return await this.fetchResultSet(predicates);
  }

  public async batchInsertTestData(): Promise<number> {
    if (!this.rdbStore) return 0;
    let startTime = new Date().getTime();
    this.rdbStore.beginTransaction();
    try {
      for (let i = 1; i <= 100; i++) {
        let randomAge = Math.floor(Math.random() * 7) + 18;
        let randomScore = Math.floor(Math.random() * 41) + 60;
        const valueBucket: relativedb.ValuesBucket = {
          'name': `学生_${Math.random().toString(36).substring(7)}`,
          'age': randomAge,
          'score': randomScore,
          'update_time': new Date().getTime()
        };
        await this.rdbStore.insert(this.TABLE_NAME, valueBucket);
      }
      this.rdbStore.commit();
      return new Date().getTime() - startTime;
    } catch (err) {
      throw new Error(JSON.stringify(err));
    }
  }

  private async fetchResultSet(predicates: relativedb.RdbPredicates): Promise<StudentItem[]> {
    if (!this.rdbStore) return [];
    let resultSet = await this.rdbStore.query(predicates);
    let list: StudentItem[] = [];
    while (resultSet.goToNextRow()) {
      list.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        name: resultSet.getString(resultSet.getColumnIndex('name')),
        age: resultSet.getLong(resultSet.getColumnIndex('age')),
        score: resultSet.getDouble(resultSet.getColumnIndex('score')),
        update_time: resultSet.getLong(resultSet.getColumnIndex('update_time'))
      });
    }
    resultSet.close();
    return list;
  }

  // ========================================================
  // 兼容性占位模块：完美对齐 Index.ets 字段要求的日程数据接口
  // ========================================================
  public async queryAllSchedules(): Promise<ScheduleItem[]> {
    return [
      { id: 1, title: '移动开发技术实验提交', time: '08:30 - 10:00', content: '工科楼 402' },
      { id: 2, title: 'AI 图像算法与提示词分享', time: '14:00 - 15:30', content: '图书馆报告厅' },
      { id: 3, title: '软工毕业设计中期答辩', time: '16:00 - 17:30', content: '线上腾讯会议' }
    ];
  }

  public async insertSchedule(schedule: ScheduleItem): Promise<number> {
    console.info('兜底接口：模拟添加日程成功 ' + schedule.title);
    return 1;
  }

  public async deleteScheduleById(id: number): Promise<number> {
    console.info('兜底接口：模拟删除日程成功 ID: ' + id);
    return 1;
  }
}