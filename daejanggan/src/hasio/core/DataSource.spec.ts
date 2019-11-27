import {Greeter, DataSource} from './DataSource';

const MyType = Function;

interface MyType<T> extends Function {
  new (...args: any[]): T;
  myPros: string;
  //myHello: string;
}

interface MyInterface {
  myPros: string;
}
function hi(kk: any): {myPros: string} {
  return kk;
}
@DataSource
class MyClass {
}

describe('DataSource Decorator', () => {
  it('What is the Decorator', () => {
    let g = new Greeter('1234');
    g.type1 = '1123'
    console.log('Greeter', g);
    expect('a').toEqual('a');
  })

  it('How to work Decorator', () => {
    let myClass: MyClass = new MyClass();
    console.log('myClass', myClass)
    console.log(hi(myClass).myPros);
    console.log('kkkkk', (myClass as MyType<MyInterface>).myPros);
    expect('Good').toEqual((myClass as MyInterface).myPros);
  });
})