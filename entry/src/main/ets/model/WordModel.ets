
// WordModel.ets

interface WordMap {
  id?: number;
  word?: string;
  phonetic?: string;
  definition?: string;
  bookName?: string;
  status?: number;
  reviewStage?: number;
  nextReviewTime?: string;
  isMistake?: number;
  example?: string;
}

export class Word {
  id: number | null;
  word: string;
  phonetic: string;
  definition: string;
  bookName: string;
  status: number; // 0: 未学, 1: 已学
  reviewStage: number; // 复习阶段
  nextReviewTime: string; // ISO8601 格式时间字符串
  isMistake: number; // 0: 否, 1: 是
  example: string;

  constructor(
    id: number | null,
    word: string,
    phonetic: string,
    definition: string,
    bookName: string,
    status: number,
    reviewStage: number,
    nextReviewTime: string,
    isMistake: number,
    example: string
  ) {
    this.id = id;
    this.word = word;
    this.phonetic = phonetic;
    this.definition = definition;
    this.bookName = bookName;
    this.status = status;
    this.reviewStage = reviewStage;
    this.nextReviewTime = nextReviewTime;
    this.isMistake = isMistake;
    this.example = example;
  }
  // 从数据库查询结果转换 (RDB查询返回的是 ResultSet，需要手动转换)
  // 这里暂时留一个简单的转换方法，具体在 Helper 中处理
  static fromMap(map: WordMap): Word {
    return new Word(
      map.id ?? null,
      map.word ?? '',
      map.phonetic ?? '',
      map.definition ?? '',
      map.bookName ?? '',
      map.status ?? 0,
      map.reviewStage ?? 0,
      map.nextReviewTime ?? '',
      map.isMistake ?? 0,
      map.example ?? ''
    );
  }
}

export class StudyProgress {
  bookName: string;
  currentGroup: number;
  lastReviewTime: string;

  constructor(bookName: string, currentGroup: number, lastReviewTime: string = '') {
    this.bookName = bookName;
    this.currentGroup = currentGroup;
    this.lastReviewTime = lastReviewTime;
  }
}