interface LangModel { uni: Map<string, number>; bi: Map<string, Map<string, number>> }
interface RankedWord { w: string; c: number }

class PredictionModel {
  private models: Map<string, LangModel>; 

  constructor() {
    this.models = new Map();
  }

  private ensure(lang: string): LangModel {
    let m: LangModel | undefined = this.models.get(lang);
    if (!m) {
      const lm: LangModel = { uni: new Map<string, number>(), bi: new Map<string, Map<string, number>>() };
      this.models.set(lang, lm);
      m = lm;
    }
    return m;
  }

  recordWord(lang: string, prev: string | null, word: string): void {
    if (!word) return;
    const m = this.ensure(lang);
    const w = word;
    const u = m.uni.get(w) ?? 0;
    m.uni.set(w, u + 1);
    if (prev && prev.length > 0) {
      let nextMap = m.bi.get(prev);
      if (!nextMap) {
        nextMap = new Map<string, number>();
        m.bi.set(prev, nextMap);
      }
      const c = nextMap.get(w) ?? 0;
      nextMap.set(w, c + 1);
    }
  }

  predict(lang: string, prev: string | null, prefix: string | null, k: number): string[] {
    const m = this.ensure(lang);
    const list: RankedWord[] = [];
    const filter = (s: string): boolean => {
      if (!prefix || prefix.length === 0) return true;
      return s.startsWith(prefix);
    };
    if (prev && prev.length > 0) {
      const nextMap = m.bi.get(prev);
      if (nextMap) {
        nextMap.forEach((c, w) => {
          if (filter(w)) {
            const item: RankedWord = { w: w, c: c };
            list.push(item);
          }
        });
      }
    }
    if (list.length < k) {
      m.uni.forEach((c, w) => {
        if (filter(w)) {
          const item: RankedWord = { w: w, c: c };
          list.push(item);
        }
      });
    }
    list.sort((a, b) => b.c - a.c);
    const seen = new Set<string>();
    const out: string[] = [];
    for (let i = 0; i < list.length && out.length < k; i++) {
      const w = list[i].w;
      if (!seen.has(w)) {
        seen.add(w);
        out.push(w);
      }
    }
    while (out.length < k) out.push('');
    return out;
  }
}

const predictionModel = new PredictionModel();
export default predictionModel;