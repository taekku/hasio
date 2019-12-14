import {mago} from './logs';

export interface PingDecorator {
  name: string;
  kk?: string;
  ping?: string[];
}

export interface Ping {
  service: PingDecorator;
}

export function instanceOfPing(obj: any): obj is Ping {
  return 'service' in obj;
}

export function Pingpong(deco:PingDecorator){
  console.log('Pingpong function:', deco)
  function classDecorator<T extends {new(...args:any[]):{}}>(cls:T) {
    return class extends cls implements Ping{
        newProperty = "new property";
        hello = "override";
        service = deco;

    }
  }
  return classDecorator;
}
function makeDecorator<T extends PingDecorator>(name: string, deco: T): (deco:PingDecorator) => any {
  function DecoratorFactory(a: T){
    console.log(`This is a ${name} Factory.`);
    console.log('factory', a);
    return function classDecorator<T1 extends {new(...args: any[]):{}}>(target: T1): T1{
      return class extends target {
        service = a;
      }
    }
  }
  return DecoratorFactory as any;
}
//export const Pong: PingDecorator = makeDecorator(PingDecorator);
export const Pong = makeDecorator('Pong', {name: 'Pong'});


export function myDecorator<T extends PingDecorator>(deco: T) {
  console.log('myDecorator function:')
  console.log('myDecorator function:', typeof deco)
  function classDecorator<T extends {new(...args:any[]):{}}>(cls:T) {
    return class extends cls {
        newProperty = "new property";
        hello = "override";
        service = deco;
    }
  }
  return classDecorator;
}

var k: number = 0;
export function myDecoratorP(target?: any, key?: any, descriptor?: any){
  // console.log('myDecoratorP function:')
  /* case 1 : class decorator
      target is the constructor function;
      key is the undefined.
      descriptor is the undefined.
   */
  /* case 2 : class method decorator
      target is a class.
      key is a function name.
      descriptor is the undefined.
   */
  /* case 3 : params decorator
      target is a class.
      key is a function name.
      descriptor is index no of the parameters.
   */
  k ++;
  //mago.log('myDecoratorP:' + k, target, key, descriptor);
}