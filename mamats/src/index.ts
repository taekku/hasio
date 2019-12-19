// import {Pingpong, myDecorator, myDecoratorP, PingDecorator, Pong, instanceOfPing} from './util/decorators';
// import {mago} from './util/logs';
// import { Ping } from './util/record';
import { DefaultAction } from './util/control';


// @Pingpong({})
//@myDecorator({ping: ['a', '1'], a: 'a'})
//Pingpong({ping: ['a', '1'], a: 'l'})
// @myDecoratorP
// class AA {
//   //service!: PingDecorator;
//   pa?: string;

//   localVal!: string;
//   constructor(){
//     this.pa = 'Good';
//   }
//   @myDecoratorP
//   myFunction = (s:string):string => {
//     return s;
//   }
//   myCalc(@myDecoratorP a: number = 100, c: number, @myDecoratorP b: string): string{
//     return String(a + 1)
//   }
// }

// class BB {
//   good: string;
//   constructor(){
//     this.good = 'Goods';
//   }
// }

// let myAA: AA = new AA();
// let myBB: BB = new BB();
// // console.log('myAA', myAA, myAA.pa);

// // console.log('as', myAA as Ping)

// function myFn(ping: any) {
//   if(instanceOfPing(ping)){
//     console.log('myFn:Ping.service', ping.service, ping);
//   } else {
//     console.log('myFn:Nobody', ping);
//   }
  
// }
// myFn(myAA);
// myFn(myBB);
// @Pong({
//   name: 'Good Pong'
// })
// //@Pingpong({a:'a'})
// class KK {
//   name: string = 'KK';
// }
// let kk: KK = new KK();
// console.log('KK', kk);

// interface User {
//   user_id: number;
//   login_id: string;
//   name: string;
//   roles: string[];
// }
// let userList: Ping<User> = new Ping<User>([]);

// userList.addRecord({user_id: 0, login_id: 'kk', name: 'tglim', roles: []});

// let uList = Array<User>();
// uList.push({user_id: 0, login_id: 'kkk', name: 'tglim', roles: []});

// console.log('userList', userList);
// console.log('uList', uList);

let control = new DefaultAction();
let control2 = new DefaultAction()

console.log('control', control);
console.log('control', control2);
console.log('control.retrieve', control.retrieve());
