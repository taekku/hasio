
export function DataSource<T extends {new(...args: any[]):{}}>(constructor:T) {
  return class extends constructor {
    myPros = 'Good';
  }
}

export function DataSource2(param: any){
  console.log(param)
  return function(constructor: any) {
    console.log(constructor)
    return <any>class extends constructor {
      someValue = param.someValue + ' world'
    }
  }
}

function sealed(constructor: Function) {
  Object.seal(constructor);
  Object.seal(constructor.prototype);
}

// 객체를 주입할 때 사용할 간단한 컨테이너를 정의하고 객체를 넣어둔다.
// 간단한 샘플임..
class Container {
  private static map: {[key: string]: any} = {};

  static add(key: string, value: string) {
    Container.map[key] = value;
  }

  static get(key: string): string {
    return Container.map[key];
  }
}
Container.add('myType', 'Classic');
console.log(Container.get('myType')); // 'Classic'

// 프로퍼티 데코레이터
// JavaScript PropertyDescriptors를 참조해야..
// 하여간 이 예제도 작동 안함
// function Inject(param: string){
//   return function(target: any, decoratedPropertyName: string) {
//     /*
//       데코레이터의 파라미터를 검사하거나 수정하는 등의 작업을 할 수 있다.
//       Ex) throw new Error('invalid')
//      */
//     console.log('Inject', target);
//     console.log('Inject:decoatedPropertyName', decoratedPropertyName);
//     console.log('Container.get(param)', Container.get(param));
//     // 이것은 실행되지 않는다.? 된다고 하는 놈도 있는데...2017.08.15
//     target[decoratedPropertyName] = Container.get(param);
//   }
// }

// Property Decorator
// 이 예제도 작동 안함
function Emoji() {
  return function(target: any, key: string | symbol) {

    let val = target[key];

    const getter = () =>  {
        return val;
    };
    const setter = (next: any) => {
        console.log('updating flavor...');
        val = `🍦 ${next} 🍦`;
    };

    Object.defineProperty(target, key, {
      get: getter,
      set: setter,
      enumerable: true,
      configurable: true,
    });

  };
}

// Property Decorator도 metadata때문에 실행 못 함
// const formatMetadataKey = Symbol("format");
// function format(formatString: string) {
//     return Reflect.metadata(formatMetadataKey, formatString);
// }
// function getFormat(target: any, propertyKey: string) {
//     return Reflect.getMetadata(formatMetadataKey, target, propertyKey);
// }

// @DataSource2( { someValue: 'Hello' })
// @sealed
// @DataSource
export class Greeter {
  property = "property";
  hello: string;
  //@Inject('myType')
  @Emoji()
  type1: string = '1'
  constructor(m: string){
    this.hello = m;
  }
}
