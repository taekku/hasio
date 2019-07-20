import {Hasio} from "./Hasio";

describe("Hasio Util", ()=>{
  it('toDate(string)', ()=>{
    const myYmd = '20190710';
    const myDate = new Date(2019, 6, 10);
    expect(Hasio.toDate(myYmd)).toEqual(myDate)
    expect(Hasio.toDate('2019.07.10')).toEqual(myDate)
    expect(Hasio.toDate('2019/07/10')).toEqual(myDate)
    expect(Hasio.toDate('2019-07-10')).toEqual(myDate)
    expect(Hasio.toDate('201y-07-10')).toEqual(null)
    expect(Hasio.toDate('2019-0a-10')).toEqual(null)
    expect(Hasio.toDate('2019-00-1a')).toEqual(null)
  })
  it('날짜얻기', ()=>{
    const myDate = new Date(2019, 6, 10)
    expect('20190710').toEqual(Hasio.strDate(myDate))
    expect('20190710').toEqual(Hasio.dateId(myDate))
    expect('201907').toEqual(Hasio.monthId(myDate))
    expect('2019').toEqual(Hasio.yearId())
  })
  it('checkNumberToLpad', ()=>{
    const n = 1;
    expect('01').toEqual(Hasio.numberPad(n,2))
    expect('001').toEqual(Hasio.numberPad(n,3))
    expect('123').toEqual(Hasio.numberPad(123,2))
    expect('23').toEqual(Hasio.numberTrunc(123,2))
    expect('01').toEqual(Hasio.numberPad2(n));
  })
  it('Number Format', ()=>{
    const n = 2000000.10;
    expect('2,000,000.1').toEqual(Hasio.fmNumber(n))
  })
})