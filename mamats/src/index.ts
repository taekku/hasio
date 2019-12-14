import {Pingpong, myDecorator, myDecoratorP, PingDecorator, Ping, Pong, instanceOfPing} from './util/decorators';
import {mago} from './util/logs';


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
@Pong({
  name: 'Good Pong'
})
//@Pingpong({a:'a'})
class KK {
  name: string = 'KK';
}
let kk: KK = new KK();
console.log('KK', kk);