"use strict";
import Jumin from '../../../src/hasio/type/jumin'
describe("class Jumin", function () {
  const valid_ssn = "7205131382414"
  const invalid_ssn = "72051314"
  const jumin = new Jumin(valid_ssn)
  it("생성자", function () {
    expect(valid_ssn).toEqual(jumin.getSSN())
    expect(valid_ssn).toEqual(jumin.ssn())
    expect(true).toEqual(jumin.isValidation())
    expect('k456k').toEqual(JSON.stringify(jumin))
  });
  it("주민번호 체크", function () {
    let j = new Jumin('720513138241a')
    expect("주민등록번호는 숫자만 입력하셔야 합니다.").toEqual(j.getMessage());
    expect(false).toEqual(j.isValidation());
    j = new Jumin('7205134')
    expect("올바른 주민등록 번호를 입력하여 주세요.").toEqual(j.getMessage());
    expect(false).toEqual(j.isValidation());
  });
  it("함수 gender()", ()=>{
    const m = new Jumin('7205131234567')
    expect('1').toEqual(m.gender());
    const f = new Jumin('7205132234567')
    expect('2').toEqual(f.gender());
    const o = new Jumin('asdfa')
    expect(void 0).toEqual(o.gender());
  });
});