/**
 * File : Organization.ts
 * Description : Organization for Org Chart
 */
export class Org {
  private _oid: number
  private _name: string
  private _line: string
  private _sta_ymd: Date
  private _end_ymd: Date
  private _children: Org[] = []
  constructor(
    {
      line,
      id = 0,
      org_name = '',
      sta_ymd = new Date(),
      end_ymd = new Date(2019, 11, 31)
    }: {
      line: string;
      id?: number;
      org_name?: string;
      sta_ymd?: Date,
      end_ymd?: Date})
      {
    this._oid = id;
    this._name = org_name;
    this._line = line;
    this._sta_ymd = sta_ymd
    this._end_ymd = end_ymd
  }
  get oid(): number{
    return this._oid
  }
  get name(): string{
    return this._name
  }
  set name(org_name:string){
    this._name = org_name
  }
  get line(): string{
    return this._line
  }
  get children(): Org[]{
    return [...this._children]
  }
  get sta_ymd(): Date{
    return this._sta_ymd
  }
  set sta_ymd(ymd) {
    this._sta_ymd = ymd
  }
  get end_ymd(): Date{
    return this._end_ymd
  }
  set end_ymd(ymd) {
    this._end_ymd = ymd
  }
  public append(org: Org) {
    if ( org.line.lastIndexOf(this.line, 0) === 0 )
      if ( org.line.indexOf('/', this.line.length + 1) < 0 )
        this._children.push(org);
      else
        this._children.forEach(p => p.append(org));
  }
}