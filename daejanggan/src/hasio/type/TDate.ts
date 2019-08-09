type DateIdType =  'date' | 'month' | 'year'
export class TDate {
  private date: Date;
  constructor();
  constructor(value: string | number | TDate | Date);
  constructor(year: number, month: number, date?: number | undefined,
              hours?: number | undefined, minutes?: number | undefined,
              seconds?: number | undefined, ms?: number | undefined)
  constructor(value?: string | number | TDate | Date, month?: number, date = 1,
              hours = 0, minutes = 0, seconds = 0, ms = 0){
    if (value) {
      if (typeof value === 'number' && (month)){
        this.date = new Date(value, month, date, hours, minutes, seconds, ms);
      } else if (typeof value  === 'string' ){
        let str = value
        if (value.length === 8){
          str = value.substr(0, 4) + '-' + value.substr(4, 2) + '-' + value.substr(6);
        }
        this.date = new Date(str)
      } else {
        if (value instanceof TDate) 
            this.date = new Date(value.date)
        // else if (typeof value === 'number'
        //       || typeof value === 'string'
        //       || value instanceof Date)
        //   this.date = new Date(value)
        else
          this.date = new Date(value)
      }
    } else {
      this.date = new Date();
    }
  }
  get dateId(): string {
    let _id = String(this.date.getFullYear());
    _id += String(this.date.getMonth() + 1).padStart(2,'0')
    _id += this.date.getDate().toString().padStart(2, '0');
    return _id;
  }
  get yearId(): string  {
    return  String(this.date.getFullYear())
  }
  get monthId(): string {
    return this.yearId + String(this.date.getMonth() + 1).padStart(2, '0')
  }
  lastday(): TDate {
    let last = new Date(this.date)
    last.setMonth(last.getMonth() + 1)
    last.setDate(0);
    return new TDate(last);
  }
  public trunc(dateIdType:DateIdType = 'date'): TDate {
    let date:Date = new Date(this.date.getFullYear(), this.date.getMonth(), this.date.getDate());
    if (dateIdType === 'date')
      this.date = date;
    else if (dateIdType === 'month'){
      date.setDate(1)
      this.date = date
    }else if (dateIdType === 'year'){
      date.setMonth(0)
      date.setDate(1)
      this.date = date;
    } else {
      console.error('정의되지 않은 trunc type 입니다.')
    }
    return this;
  }
}
