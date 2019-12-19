

export class Ping<T> {
  data: T[];
  constructor(data: T[]){
    this.data = data;
  }
  get length(): number {
    return this.data.length;
  }
  addRecord(val: T) {
    this.data.push(val);
  }
  getRecord(idx: number): T {
    return this.data[idx];
  }
  setRecord(idx: number, val: T) {
    this.data[idx] = val;
  }
  get Data(){
    return this.Data;
  }
  set Data(values: T[]){
    this.data = values;
  }
}
