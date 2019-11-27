import {ChangeDetectionStrategy} from '@angular/core';
import {Type, TypeDecorator, Directive} from '@angular/core';
import { noop } from '@angular/compiler/src/render3/view/util';
// import {makeDecorator} from '@angular'

export interface IData {
  newProperty: string
}

export function DataSource<T extends {new(...args: any[]): {}}>(construnctor: T) {
  return class extends construnctor {
    // class construnctor를 CALL한 후에 수행
    newProperty = 'new Property';
    myPros = 'My DataSource';
    kkk = console.log('MyDataSourceExteneds', arguments, construnctor.name, this);
  };
}

export function Lim() {
  // 선언시에..
  console.log('Lim() evaluated');
  // tslint:disable-next-line: only-arrow-functions
  return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    console.log('Lim() call..');
    console.log('target', target);
    console.log('propertyKey', propertyKey);
    console.log('descriptor', descriptor);
    // return 'my decorator';
  };
}

export interface LTGDecorator {
  (obj: LTG): TypeDecorator;
  new (obj: LTG): LTG;
}
/**
 * Supplies configuration metadata for and Carpenter LTG.
 *
 * @publicApi
 */
export interface LTG extends Directive {
  serviceId?: string;
}

export const ANNOTATIONS = '__annotations__';
export const PARAMETERS = '__parameters__';
export const PROP_METADATA = '__prop__metadata__';

export function makeDecorator<T>(
    name: string, props?: (...args: any[]) => any, parentClass?: any,
    additionalProcessing?: (type: Type<T>) => void,
    typeFn?: (type: Type<T>, ...args: any[]) => void):
    { new (...args: any[]): any;
      (...args: any[]): any;
      (...args: any[]): (cls: any) => any; } {
  const metaCtor = makeMetadataCtor(props);

  function DecoratorFactory(
      this: unknown | typeof DecoratorFactory,
      ...args: any[]): (cls: Type<T>) => any {
    if (this instanceof DecoratorFactory) {
      metaCtor.call(this, ...args);
      return this as typeof DecoratorFactory;
    }

    const annotationInstance = new (DecoratorFactory as any)(...args);
    // return TypeDecorator;
    // tslint:disable-next-line:no-shadowed-variable
    const LTGDecorator = (cls: Type<T>) => {
      if (typeFn) {
        typeFn(cls, ...args);
      }
    // Use of Object.defineProperty is important since it creates non-enumerable property which
    // prevents the property is copied during subclassing.
      const annotations = cls.hasOwnProperty(ANNOTATIONS) ?
          (cls as any)[ANNOTATIONS] :
          Object.defineProperty(cls, ANNOTATIONS, {value: []})[ANNOTATIONS];
      annotations.push(annotationInstance);

      if (additionalProcessing) {
        additionalProcessing(cls);
      }
      return cls;
    };
    return LTGDecorator;
  }

  if (parentClass) {
    DecoratorFactory.prototype = Object.create(parentClass.prototype);
  }

  DecoratorFactory.prototype.ngMetadataName = name;
  (DecoratorFactory as any).annotationCls = DecoratorFactory;
  return DecoratorFactory as any;
}

function makeMetadataCtor(props?: (...args: any[]) => any): any {
  return function ctor(this: any, ...args: any[]) {
    if (props) {
      const values = props(...args);
      for (const propName in values) {
        if (values.hasOwnProperty(propName)) {
          this[propName] = values[propName];
        }
      }
    }
  };
}


export function makeParamDecorator(
  name: string, props?: (...args: any[]) => any, parentClass?: any): any {
const metaCtor = makeMetadataCtor(props);
function ParamDecoratorFactory(
    this: unknown | typeof ParamDecoratorFactory, ...args: any[]): any {
  if (this instanceof ParamDecoratorFactory) {
    metaCtor.apply(this, args);
    return this;
  }
  const annotationInstance = new (ParamDecoratorFactory as any)(...args);

  (ParamDecorator as any).annotation = annotationInstance;
  return ParamDecorator;

  function ParamDecorator(cls: any, unusedKey: any, index: number): any {
    // Use of Object.defineProperty is important since it creates non-enumerable property which
    // prevents the property is copied during subclassing.
    const parameters = cls.hasOwnProperty(PARAMETERS) ?
        (cls as any)[PARAMETERS] :
        Object.defineProperty(cls, PARAMETERS, {value: []})[PARAMETERS];

    // there might be gaps if some in between parameters do not have annotations.
    // we pad with nulls.
    while (parameters.length <= index) {
      parameters.push(null);
    }

    (parameters[index] = parameters[index] || []).push(annotationInstance);
    return cls;
  }
}
if (parentClass) {
  ParamDecoratorFactory.prototype = Object.create(parentClass.prototype);
}
ParamDecoratorFactory.prototype.ngMetadataName = name;
(ParamDecoratorFactory as any).annotationCls = ParamDecoratorFactory;
return ParamDecoratorFactory;
}

export function makePropDecorator(
  name: string, props?: (...args: any[]) => any, parentClass?: any,
  additionalProcessing?: (target: any, name: string, ...args: any[]) => void): any {
const metaCtor = makeMetadataCtor(props);

function PropDecoratorFactory(this: unknown | typeof PropDecoratorFactory, ...args: any[]): any {
  if (this instanceof PropDecoratorFactory) {
    metaCtor.apply(this, args);
    return this;
  }

  const decoratorInstance = new (PropDecoratorFactory as any)(...args);

  function PropDecorator(target: any, propName: string) {
    const constructor = target.constructor;
    // Use of Object.defineProperty is important since it creates non-enumerable property which
    // prevents the property is copied during subclassing.
    const meta = constructor.hasOwnProperty(PROP_METADATA) ?
        (constructor as any)[PROP_METADATA] :
        Object.defineProperty(constructor, PROP_METADATA, {value: {}})[PROP_METADATA];
    meta[propName] = meta.hasOwnProperty(propName) && meta[propName] || [];
    meta[propName].unshift(decoratorInstance);

    if (additionalProcessing) {
      additionalProcessing(target, propName, ...args);
    }
  }

  return PropDecorator;
}

if (parentClass) {
  PropDecoratorFactory.prototype = Object.create(parentClass.prototype);
}

PropDecoratorFactory.prototype.ngMetadataName = name;
(PropDecoratorFactory as any).annotationCls = PropDecoratorFactory;
return PropDecoratorFactory;
}

export const LTG: LTGDecorator = makeDecorator(
  'LTG', (ltg: LTG = {}) => ({changeDetection: ChangeDetectionStrategy.Default, ...ltg}),
  Directive, undefined,
  undefined // (type: Type<any>, meta: LTG) => typeFn(type, meta));
);
