
import {Type} from '../interface/type';

export interface TypeDecorator {
  <T extends Type<any>>(type: T): T;
  // tslint:disable-next-line: ban-types
  (target: Object, propertyKey?: string|symbol, parameterIndex?: number): void;
}

export const ANNOTATIONS = '__annotations__';
export const PARAMETERS = '__parameters__';
export const PROP_METADATA = '__prop__metadata__';

export function makeDecorator<T>(
  name: string, props?: (...args: any[]) => any, parentClass?: any,
  additionalProcessing?: (type: Type<T>) => void):
  {new (...args: any[]): any; (...args: any[]): any; (...args: any[]): (cls: any) => any;} {

  return void 0;
}
