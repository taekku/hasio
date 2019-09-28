/**
 * [하시오]라이브러리 모음
 */
export module Hasio {
  /**
   * Date형으로 만듦
   * @param ymd yyyymmdd, yyyy.mm.dd, yyyy-mm-dd, yyyy/mm/dd
   */
  export const toDate = (ymd: string): Date|null => {
    const _ymd = ymd.replace(/\./gi, "").replace(/-/gi,"").replace(/\//gi,"")
    if( _ymd.length != 8 ){
      return null
    }
    if( isNaN(Number(_ymd)) ) {
      return null
    }
    const yyyy: number = Number.parseInt(_ymd.substring(0,4))
    const mm: number = Number.parseInt(_ymd.substring(4,6)) - 1
    const dd: number = Number.parseInt(_ymd.substring(6))

    return new Date(yyyy, mm, dd);
  }

  /**
   * yyyymmdd형태로 만듦
   * @param day 기본값은 오늘
   */
  export const strDate = (day:Date = new Date()) =>
    '' + day.getFullYear() + (day.getMonth()+1).toString().padStart(2, "0")
            + day.getDate().toString().padStart(2, "0")

  /**
   * yyyymmdd형태로 만듦
   * @param day 기본값은 오늘
   */
  export const dateId = (day:Date = new Date()) =>
    '' + day.getFullYear() + (day.getMonth()+1).toString().padStart(2, "0")
            + day.getDate().toString().padStart(2, "0")

  /**
   * yyyymm형태로 만듦
   * @param day 기본값은 오늘
   */
  export const monthId = (day:Date = new Date()) =>
    ''+ day.getFullYear() + (day.getMonth()+1).toString().padStart(2, "0")

  /**
   * yyyy형태로 만듦
   * @param day 기본값은 오늘
   */
  export const yearId = (day:Date = new Date()) =>
    '' + day.getFullYear()
  /**
   * #,##0 형태로 만듦
   * @param num 정수
   */
  export const fmNumber = (num:number) =>
    num.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,')

  /**
   * '0'을 추가하여 minLength자리 문자열로 만듦
   * @param num 
   * @param minLength 
   */
  export const numberPad = (num: number, minLength: number) =>
    num.toFixed(0).padStart(minLength, '0')

  /**
   * '0'을 추가하여 최소 2자리 문자열로 만듦
   * @param num 
   */
  export const numberPad2 = (num:number) => numberPad(num,2);

  /**
   * '0'을 추가하여 최대 maxLength자리 문자열로 만듦
   * @param n 
   * @param maxLength 
   */
  export const numberTrunc = (n: number, maxLength: number) =>
    n.toFixed(0).slice(-maxLength).padStart(maxLength, '0')
}