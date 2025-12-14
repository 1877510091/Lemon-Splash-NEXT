import relationalStore from '@ohos.data.relationalStore';
import { Word, StudyProgress } from './WordModel';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';

export interface ImportResult {
  success: boolean;
  message: string;
  count: number;
}

// ==================== 1. 定义兼容接口 ====================

// ✅ 新增：定义单词头部对象接口，替代 any
interface WordHeadObject {
  wordHead?: string;
}

interface SimpleTrans {
  type?: string;
  translation?: string;
}

interface SimplePhrase {
  phrase?: string;
  translation?: string;
}

interface ComplexTrans {
  pos?: string;
  tranCn?: string;
}

interface ComplexSentence {
  sContent?: string;
  sCn?: string;
}

interface SentenceWrapper {
  sentences?: ComplexSentence[];
}

interface ComplexPhraseData {
  pContent?: string;
  pCn?: string;
}

interface PhraseWrapper {
  phrases?: ComplexPhraseData[];
}

interface DeepContent {
  usphone?: string;
  ukphone?: string;
  trans?: ComplexTrans[];
  sentence?: SentenceWrapper;
  phrase?: PhraseWrapper;
}

interface DeepWordWrapper {
  wordHead?: string;
  content?: DeepContent;
}

interface ContentWrapper {
  word?: DeepWordWrapper;
}

interface RawJsonItem {
  // ✅ 修复：使用联合类型替代 any，符合 ArkTS 严格模式
  word?: string | WordHeadObject;
  phonetic?: string;
  translations?: SimpleTrans[];
  phrases?: SimplePhrase[];

  headWord?: string;
  content?: ContentWrapper;
}

// ==================== 2. 数据库帮助类 ====================

class DatabaseHelper {
  private rdbStore: relationalStore.RdbStore | null = null;
  private static instance: DatabaseHelper;
  private context: common.UIAbilityContext | null = null;
  private reviewIntervals: number[] = [1, 2, 4, 7, 15, 30];

  private constructor() {}

  public static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper();
    }
    return DatabaseHelper.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    if (this.rdbStore) return;
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'lemon_words_v10.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
    await this.createTables();
  }

  private async createTables() {
    if (!this.rdbStore) return;
    await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS words (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT, phonetic TEXT, definition TEXT, bookName TEXT, status INTEGER DEFAULT 0, reviewStage INTEGER DEFAULT 0, nextReviewTime TEXT, isMistake INTEGER DEFAULT 0, example TEXT)`);
    try { await this.rdbStore.executeSql('CREATE INDEX IF NOT EXISTS idx_bookName ON words(bookName)'); } catch(e) {}
    try { await this.rdbStore.executeSql('CREATE INDEX IF NOT EXISTS idx_status ON words(status)'); } catch(e) {}
    await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS study_logs (date TEXT PRIMARY KEY, count INTEGER DEFAULT 0)`);
    await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS study_progress (bookName TEXT PRIMARY KEY, currentGroup INTEGER DEFAULT 0, lastReviewTime TEXT)`);
    await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)`);
  }

  // ==================== 核心逻辑 ====================

  // ✅ 修复：补全缺失的 markWordAsLearned 方法
  async markWordAsLearned(wordId: number, isMistake: boolean) {
    if (!this.rdbStore) return;
    const date = new Date();
    // 生成 YYYY-MM-DD
    const todayStr = `${date.getFullYear()}-${(date.getMonth()+1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
    const nextDate = new Date(date.getTime() + 24 * 60 * 60 * 1000);

    this.rdbStore.beginTransaction();
    try {
      // 1. 更新单词状态
      let wordVal: relationalStore.ValuesBucket = {
        status: 1,
        reviewStage: 1,
        nextReviewTime: nextDate.toISOString(),
        isMistake: isMistake ? 1 : 0
      };
      let wordPred = new relationalStore.RdbPredicates('words');
      wordPred.equalTo('id', wordId);
      await this.rdbStore.update(wordVal, wordPred);

      // 2. 更新今日学习记录 (计数 +1)
      let logPred = new relationalStore.RdbPredicates('study_logs');
      logPred.equalTo('date', todayStr);
      let rs = await this.rdbStore.query(logPred);

      if (rs.goToFirstRow()) {
        let currentCount = rs.getLong(rs.getColumnIndex('count'));
        let updateLogVal: relationalStore.ValuesBucket = { count: currentCount + 1 };
        let updatePred = new relationalStore.RdbPredicates('study_logs');
        updatePred.equalTo('date', todayStr);
        await this.rdbStore.update(updateLogVal, updatePred);
      } else {
        let insertLogVal: relationalStore.ValuesBucket = { date: todayStr, count: 1 };
        await this.rdbStore.insert('study_logs', insertLogVal);
      }
      rs.close();
      this.rdbStore.commit();
    } catch (e) {
      this.rdbStore.rollBack();
    }
  }

  async importJsonData(fileName: string, bookName: string, isShuffle: boolean): Promise<ImportResult> {
    if (!this.rdbStore || !this.context) return { success: false, message: "数据库未初始化", count: 0 };

    try {
      const resourceManager = this.context.resourceManager;
      let fileData: Uint8Array;

      try {
        fileData = await resourceManager.getRawFileContent(fileName);
      } catch (e) {
        return { success: false, message: `找不到文件: ${fileName}`, count: 0 };
      }

      const textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      const jsonString = textDecoder.decodeToString(fileData);

      let jsonList: RawJsonItem[] = [];

      try {
        let parsed = JSON.parse(jsonString) as Object;
        if (Array.isArray(parsed)) {
          jsonList = parsed as RawJsonItem[];
        } else {
          jsonList = [parsed as RawJsonItem];
        }
      } catch (e) {
        let lines = jsonString.split('\n');
        for (let line of lines) {
          if (line.trim().length > 0) {
            try { jsonList.push(JSON.parse(line.trim()) as RawJsonItem); } catch (err) {}
          }
        }
      }

      if (jsonList.length === 0) return { success: false, message: "JSON 内容为空", count: 0 };

      if (isShuffle) {
        for (let i = jsonList.length - 1; i > 0; i--) {
          const j = Math.floor(Math.random() * (i + 1));
          let temp = jsonList[i];
          jsonList[i] = jsonList[j];
          jsonList[j] = temp;
        }
      }

      this.rdbStore.beginTransaction();

      let deletePredicates = new relationalStore.RdbPredicates('words');
      deletePredicates.equalTo('bookName', bookName);
      await this.rdbStore.delete(deletePredicates);

      let progPred = new relationalStore.RdbPredicates('study_progress');
      progPred.equalTo('bookName', bookName);
      await this.rdbStore.delete(progPred);

      let insertCount = 0;

      for (const item of jsonList) {
        let word = "";
        let phonetic = "";
        let definition = "";
        let example = "";

        // ✅ 修复：兼容字符串和对象类型的单词字段
        if (item.headWord) {
          word = item.headWord;
        } else if (typeof item.word === 'string') {
          word = item.word;
        } else if (typeof item.word === 'object' && item.word) {
          // 类型断言，处理 WordHeadObject
          word = (item.word as WordHeadObject).wordHead || "";
        }

        if (!word) continue;

        if (item.content?.word?.content?.usphone) {
          phonetic = item.content.word.content.usphone;
        } else if (item.phonetic) {
          phonetic = item.phonetic;
        }

        if (item.content?.word?.content?.trans) {
          definition = item.content.word.content.trans.map(t => (t.pos ? `${t.pos}. ` : "") + (t.tranCn || "")).join('\n');
        } else if (item.translations) {
          definition = item.translations.map(t => (t.type ? `${t.type}. ` : "") + (t.translation || "")).join('\n');
        }

        if (item.content?.word?.content?.sentence?.sentences?.[0]) {
          example = `${item.content.word.content.sentence.sentences[0].sContent || ''}\n${item.content.word.content.sentence.sentences[0].sCn || ''}`;
        } else if (item.phrases && item.phrases.length > 0) {
          example = item.phrases.slice(0, 3).map(p =>
          `${p.phrase || ''}  ${p.translation || ''}`
          ).join('\n');
        }

        const valueBucket: relationalStore.ValuesBucket = {
          bookName: bookName,
          word: word,
          phonetic: phonetic,
          definition: definition,
          example: example,
          status: 0,
          isMistake: 0,
          reviewStage: 0,
          nextReviewTime: ''
        };
        await this.rdbStore.insert('words', valueBucket);
        insertCount++;
      }

      this.rdbStore.commit();

      if (insertCount === 0) {
        return { success: false, message: "解析完成但未插入任何数据，请检查 JSON 字段名", count: 0 };
      }

      await this.saveStudyProgress(new StudyProgress(bookName, 0));
      await this.setLastBook(bookName);

      return { success: true, message: "导入成功", count: insertCount };

    } catch (e) {
      if(this.rdbStore) { try { this.rdbStore.commit(); } catch(ignore) {} }
      return { success: false, message: `导入异常: ${JSON.stringify(e as object)}`, count: 0 };
    }
  }

  // ----------------------------------------------------
  // ✅ 【最终修复后的新增代码】解决编译错误
  // ----------------------------------------------------

  /**
   * 获取第一个已导入的词库名称作为默认词库。
   * @returns 第一个词库名称或 null
   */
  async getFirstBook(): Promise<string | null> {
    if (!this.rdbStore) return null;

    let predicates = new relationalStore.RdbPredicates('words');

    // 🚨 最终修复：使用 limitAs 且只传入一个参数 (count)，解决了 "Expected 1 arguments, but got 2" 错误
    predicates.limitAs(1);

    // 查询结果集，只获取 bookName 字段
    let resultSet = await this.rdbStore.query(predicates, ['bookName']);

    if (resultSet.goToFirstRow()) {
      // 获取 bookName 的值
      const bookName = resultSet.getString(resultSet.getColumnIndex('bookName'));
      resultSet.close();
      return bookName;
    }

    resultSet.close();
    // 如果 words 表中没有任何数据，则返回 null
    return null;
  }
  // ----------------------------------------------------
  // ✅ 【最终修复后的新增代码结束】
  // ----------------------------------------------------


  async getLastBook(): Promise<string | null> {
    if (!this.rdbStore) return null;
    let predicates = new relationalStore.RdbPredicates('settings');
    predicates.equalTo('key', 'last_book');
    let resultSet = await this.rdbStore.query(predicates);
    if (resultSet.goToFirstRow()) {
      const val = resultSet.getString(resultSet.getColumnIndex('value'));
      resultSet.close();
      return val;
    }
    resultSet.close();
    return null;
  }

  async setLastBook(bookName: string) {
    if (!this.rdbStore) return;
    try {
      let val: relationalStore.ValuesBucket = { key: 'last_book', value: bookName };
      let predicates = new relationalStore.RdbPredicates('settings');
      predicates.equalTo('key', 'last_book');
      let rows = await this.rdbStore.update(val, predicates);
      if (rows === 0) await this.rdbStore.insert('settings', val);
    } catch (e) {}
  }

  async getTodayCount(): Promise<number> {
    if (!this.rdbStore) return 0;
    const date = new Date();
    const todayStr = `${date.getFullYear()}-${(date.getMonth()+1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
    let predicates = new relationalStore.RdbPredicates('study_logs');
    predicates.equalTo('date', todayStr);
    let resultSet = await this.rdbStore.query(predicates);
    let count = 0;
    if (resultSet.goToFirstRow()) { count = resultSet.getLong(resultSet.getColumnIndex('count')); }
    resultSet.close();
    return count;
  }

  async setDailyCount(dateStr: string, count: number) {
    if (!this.rdbStore) return;
    try {
      let val: relationalStore.ValuesBucket = { date: dateStr, count: count };
      let predicates = new relationalStore.RdbPredicates('study_logs');
      predicates.equalTo('date', dateStr);
      let rs = await this.rdbStore.query(predicates);
      if (rs.goToFirstRow()) { await this.rdbStore.update(val, predicates); }
      else { await this.rdbStore.insert('study_logs', val); }
      rs.close();
    } catch (e) { console.error('setDailyCount error'); }
  }

  async getWordsByGroup(bookName: string, groupIndex: number, size: number = 20): Promise<Word[]> {
    if (!this.rdbStore) return [];
    let predicates = new relationalStore.RdbPredicates('words');
    predicates.equalTo('bookName', bookName);
    predicates.orderByAsc('id');
    let resultSet = await this.rdbStore.query(predicates);
    let words: Word[] = [];
    const startRow = groupIndex * size;
    if (resultSet.goToRow(startRow)) {
      do { words.push(this.resultSetToWord(resultSet)); if (words.length >= size) break; } while (resultSet.goToNextRow());
    }
    resultSet.close();
    return words;
  }

  async getTotalWords(bookName: string): Promise<number> {
    if (!this.rdbStore) return 0;
    let predicates = new relationalStore.RdbPredicates('words');
    predicates.equalTo('bookName', bookName);
    let resultSet = await this.rdbStore.query(predicates, ['id']);
    let count = resultSet.rowCount;
    resultSet.close();
    return count;
  }

  private resultSetToWord(rs: relationalStore.ResultSet): Word {
    return new Word(
      rs.getLong(rs.getColumnIndex('id')), rs.getString(rs.getColumnIndex('word')), rs.getString(rs.getColumnIndex('phonetic')),
      rs.getString(rs.getColumnIndex('definition')), rs.getString(rs.getColumnIndex('bookName')), rs.getLong(rs.getColumnIndex('status')),
      rs.getLong(rs.getColumnIndex('reviewStage')), rs.getString(rs.getColumnIndex('nextReviewTime')), rs.getLong(rs.getColumnIndex('isMistake')), rs.getString(rs.getColumnIndex('example'))
    );
  }

  async saveStudyProgress(p: StudyProgress) {
    if (!this.rdbStore) return;
    let predicates = new relationalStore.RdbPredicates('study_progress');
    predicates.equalTo('bookName', p.bookName);
    await this.rdbStore.delete(predicates);
    const val: relationalStore.ValuesBucket = { bookName: p.bookName, currentGroup: p.currentGroup, lastReviewTime: p.lastReviewTime || '' };
    await this.rdbStore.insert('study_progress', val);
  }

  async getStudyProgress(bookName: string): Promise<StudyProgress> {
    if (!this.rdbStore) return new StudyProgress(bookName, 0);
    let predicates = new relationalStore.RdbPredicates('study_progress');
    predicates.equalTo('bookName', bookName);
    let rs = await this.rdbStore.query(predicates);
    if (rs.goToFirstRow()) {
      let p = new StudyProgress(rs.getString(rs.getColumnIndex('bookName')), rs.getLong(rs.getColumnIndex('currentGroup')), rs.getString(rs.getColumnIndex('lastReviewTime')));
      rs.close(); return p;
    }
    rs.close(); return new StudyProgress(bookName, 0);
  }

  async getWordsDueForReview(): Promise<Word[]> {
    if (!this.rdbStore) return [];
    const nowStr = new Date().toISOString();
    let predicates = new relationalStore.RdbPredicates('words');
    predicates.equalTo('status', 1);
    predicates.lessThanOrEqualTo('nextReviewTime', nowStr);
    predicates.orderByAsc('nextReviewTime');
    let resultSet = await this.rdbStore.query(predicates);
    let words: Word[] = [];
    while (resultSet.goToNextRow()) { words.push(this.resultSetToWord(resultSet)); }
    resultSet.close(); return words;
  }

  async getMistakeWords(): Promise<Word[]> {
    if (!this.rdbStore) return [];
    let predicates = new relationalStore.RdbPredicates('words');
    predicates.equalTo('isMistake', 1);
    predicates.orderByDesc('id');
    let resultSet = await this.rdbStore.query(predicates);
    let words: Word[] = [];
    while (resultSet.goToNextRow()) { words.push(this.resultSetToWord(resultSet)); }
    resultSet.close(); return words;
  }

  async removeMistake(wordId: number) {
    if (!this.rdbStore) return;
    let val: relationalStore.ValuesBucket = { isMistake: 0 };
    let predicates = new relationalStore.RdbPredicates('words');
    predicates.equalTo('id', wordId);
    await this.rdbStore.update(val, predicates);
  }

  async getMonthlyData(year: number, month: number): Promise<Map<number, number>> {
    let map = new Map<number, number>();
    if (!this.rdbStore) return map;
    let prefix = `${year}-${month.toString().padStart(2, '0')}`;
    let predicates = new relationalStore.RdbPredicates('study_logs');
    predicates.like('date', prefix + '%');
    let rs = await this.rdbStore.query(predicates);
    while(rs.goToNextRow()) {
      let date = rs.getString(rs.getColumnIndex('date'));
      let count = rs.getLong(rs.getColumnIndex('count'));
      let day = parseInt(date.split('-')[2]);
      map.set(day, count);
    }
    rs.close(); return map;
  }

  async getAllMonthsWithData(): Promise<string[]> {
    if (!this.rdbStore) return [];
    try {
      let predicates = new relationalStore.RdbPredicates('study_logs');
      predicates.orderByDesc('date');
      let rs = await this.rdbStore.query(predicates, ['date']);
      let months = new Set<string>();
      while (rs.goToNextRow()) {
        let date = rs.getString(rs.getColumnIndex('date'));
        let monthStr = date.substring(0, 7);
        months.add(monthStr);
      }
      rs.close();
      if (months.size === 0) {
        let now = new Date();
        let m = (now.getMonth()+1).toString().padStart(2, '0');
        months.add(`${now.getFullYear()}-${m}`);
      }
      return Array.from(months);
    } catch (e) { return []; }
  }

  async processReview(wordId: number, remembered: boolean, currentStage: number) {
    if (!this.rdbStore) return;
    let newStage = 1;
    let days = 1;
    if (remembered) {
      newStage = currentStage + 1;
      if (newStage > this.reviewIntervals.length) days = 365;
      else days = this.reviewIntervals[newStage - 1];
    }
    let nextDate = new Date(new Date().getTime() + days * 24 * 60 * 60 * 1000);
    let val: relationalStore.ValuesBucket = { reviewStage: newStage, nextReviewTime: nextDate.toISOString(), isMistake: remembered ? 0 : 1 };
    let pred = new relationalStore.RdbPredicates('words');
    pred.equalTo('id', wordId);
    await this.rdbStore.update(val, pred);
  }
}

export default DatabaseHelper.getInstance();