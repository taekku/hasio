
function makeDecorator(name: string, props?: (...args: any[]) => any):
  {new (...args: any[]): any; (...args: any[]): any; (...args: any[]): (cls: any) => any}{
  function classDecorator<T extends {new(...args: any[]): any}>
        (constructor: T) {
      return class extends constructor {
        newProperty = "new property";
        decoratorName = name;
        dataSource = props?props():undefined;
      }
  };
  return classDecorator as any;
}

export const Type = Function;
export function isType(v: any): v is Type<any> {
  return typeof v === 'function';
}
export interface AbstractType<T> extends Function { prototype: T; }
export interface Type<T> extends Function { new (...args: any[]): T; }
export type Mutable<T extends{[x: string]: any}, K extends string> = {
  [P in K]: T[P];
}
export interface TypeDecorator {
  <T extends Type<any>>(type: T): T;
  (target: Object, propertyKey?: string|symbol, parameterIndex?: number): void;
}
export interface DataSourceDecorator extends TypeDecorator {
  (obj: DataSource): TypeDecorator;
  new (obj: DataSource): DataSource;
}

export interface DataSource {
  kk?: string;
}
// const DataSourceDecorator = 
export const MyDecorator = makeDecorator('MyDecorator',
     (ds: DataSource) => ds);