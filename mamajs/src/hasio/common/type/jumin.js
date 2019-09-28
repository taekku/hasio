"use strict";
export class Jumin{
  constructor(ssn){
    this.ssn = (() => { return () => { return ssn }; })();
  }
  getSSN(){
    return this.ssn();
  }

  setValidation(jumin_no) {
    let check = false;
    this._message = '';
    let arr_ssn = [],
      compare = [2, 3, 4, 5, 6, 7, 8, 9, 2, 3, 4, 5],
      sum = 0;
    if (jumin_no.length !== 13) {
      this._message = '올바른 주민등록 번호를 입력하여 주세요.';
      return;
    }
    if (jumin_no.match('[^0-9]')) {
      this._message = '주민등록번호는 숫자만 입력하셔야 합니다.';
      return;
    }
    // 공식: M = (11 - ((2×A + 3×B + 4×C + 5×D + 6×E + 7×F + 8×G + 9×H + 2×I + 3×J + 4×K + 5×L) % 11)) % 11
    for (let i = 0; i < 13; i++) {
      arr_ssn[i] = Number(jumin_no.substring(i, i + 1));
    }
    for (let i = 0; i < 12; i++) {
      sum = sum + (arr_ssn[i] * compare[i]);
    }
    sum = (11 - (sum % 11)) % 10;
    if (sum != arr_ssn[12]) {
      this._message = "올바른 주민등록 번호를 입력하여 주세요.";
      return;
    }
    this._validation = true;
  }
  gender() {
    return this._gender;
  }
  birth() {
    return this._date;
  }
  isValidation() {
    return this._validation;
  }
  getMessage() {
    return this._message;
  }
}
