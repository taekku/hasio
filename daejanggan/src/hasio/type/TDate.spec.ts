import {TDate} from './TDate';

describe('TDate', () => {
  it('get dateId', () => {
    let tDate: TDate = new TDate(new Date("2019-02-02"));
    expect('20190202').toEqual(tDate.dateId);
  });
  it('get monthId', () => {
    let tDate: TDate =  new TDate(new Date("2019-02-02"))
    expect('201902').toEqual(tDate.monthId)
  })
  it('constructor()', () => {
    let tDate = new TDate("20190204")
    expect('20190204').toEqual(tDate.dateId)
  })
  it('trunc()', () => {
    let d = new Date(2019,1)
    let tDate: TDate = new TDate("2019-02-02")
    expect('20190202').toEqual(tDate.dateId)
    expect('20190201').toEqual(tDate.trunc('month').dateId)
    expect('20190101').toEqual(tDate.trunc('year').dateId)
    expect('20190101').toEqual(tDate.dateId)
  })
  it('lastday()', () => {
    let tDate: TDate = (new TDate(new Date("2019-02-02"))).lastday()
    expect('20190228').toEqual(tDate.dateId);
    tDate = new TDate('20190201').lastday();

  })

});
