import {myDecorator} from './util/decorators';

console.log("Hello World from your main file!");

console.log('this typescript file')


let a: Function;

a = function(): void{
  console.log('It works');
}

let b: (param: string) => string;
b = function(param: string): string { return param; };

console.log('param:', b('param'));

@myDecorator({ping: ['a', '1']})
class AA {
  pa?: string;
  constructor(){
    this.pa = 'Good';
  }
}

var myAA = new AA();

console.log('myAA', myAA);
