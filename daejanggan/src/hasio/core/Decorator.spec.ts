import {MyDecorator, DataSourceDecorator, DataSource} from './Decorator';

@MyDecorator(
  {
    kk: 'kkk'
  }
)
class MyClass {

}


describe('Taekgu Decorator', () => {
  it('What is the Decorator', () => {
    var myClass = new MyClass();
    console.log('myClass', myClass);
    console.log('myClass2', (myClass as DataSource));
    expect('a').toEqual('a');
  });
});
