export interface RefreshStamp {
  serviceUrl: string;
  configRevision: number;
  featuredRevision: number;
}

export function sameRefreshStamp(left: RefreshStamp, right: RefreshStamp): boolean {
  return left.serviceUrl === right.serviceUrl && left.configRevision === right.configRevision &&
    left.featuredRevision === right.featuredRevision;
}

export class RefreshCoordinator<T> {
  private activeKey: string = '';
  private active?: Promise<T>;

  run(key: string, task: () => Promise<T>): Promise<T> {
    if (this.active && this.activeKey === key) {
      return this.active;
    }
    const result = task();
    this.activeKey = key;
    this.active = result;
    result.then(() => this.clear(result), () => this.clear(result));
    return result;
  }

  private clear(result: Promise<T>): void {
    if (this.active === result) {
      this.active = undefined;
      this.activeKey = '';
    }
  }
}
