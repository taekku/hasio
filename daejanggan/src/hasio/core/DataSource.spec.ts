import {Greeter, DataSource} from './DataSource';

describe('DataSource Decorator', () => {
  it('What is the Decorator', () => {
    let g = new Greeter('1234');
    g.type1 = '1123'
    console.log(g);
    expect('a').toEqual('a');
  })
})