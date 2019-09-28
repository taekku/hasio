import { TDate } from "../type/TDate";

/**
 * 서비스 : 각종 Request를 wrap처리한다.
 */
export interface IService {
  id: string;
  request: IParam[];
  result: IData[];
}

export enum ParamType {
  Normal = 1,

}
export interface IParam {
  id: string;
  value: number | string | boolean | TDate;
  /**
   * 생성자에 의해서만 변경되는 경우 true
   */
  isReadOnly(): boolean;

  /**
   * Data가 가져야 할 최대
   * string : 최대길이
   * number : 최대값
   */
  max_length: number;

  /**
   * Data가 가져야 할 최소
   * string : 최소길이
   * number : 최소값
   */
  min_length: number;
}

export interface IData {
  readonly [index: number]: any;
}