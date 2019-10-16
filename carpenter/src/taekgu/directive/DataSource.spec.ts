import { DataSource, Lim } from './DataSource';

@DataSource
class MyClass {
    constructor(my: string = 'Good') {
        console.log('MyClass construnctor called!', my)
    }
    myPros: string;

    @Lim()
    myMethod() {
        console.log('myMethod execute');
        return 'myMethod() return ';
    }
}
describe('DataSource', () => {
    beforeEach(() => {});
    it('My DataSource', () => {
        const ds: MyClass = new MyClass('oh no');
        console.log('myPros', ds.myPros);
        // tslint:disable-next-line: no-string-literal
        console.log('newProperty', ds['newProperty']);
        console.log(ds.myMethod());
        console.log('myClass', ds);
        expect(ds.myPros).toEqual('My DataSource');
    });
});
