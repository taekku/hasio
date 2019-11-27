/**
 * @license
 * Copyright ...
 */

 /**
  * @description
  * 컴포넌트 또는 다른 오브젝트가 instances of 인 타입을 표현한다.
  */
export const Type = Function;

export interface Type<T> extends Function { new (...args: any[]): T; }

export function isType(v: any): v is Type<any> {
  return typeof v === 'function';
}

/**
 * @descripttion
 * 추상클래스 'T'를 표현, 구체적인 클래스에 적용하면 인스턴스화가 중지됩니다.
 */
export interface AbstractType<T> extends Function { prototype: T; }

export type Mutable<T extends{[x: string]: any}, K extends string> = {
  [P in K]: T[P];
}
