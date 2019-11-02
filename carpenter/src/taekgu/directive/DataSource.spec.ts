import { DataSource, Lim, IData } from './DataSource';

@DataSource
class MyClass implements IData {
    newProperty: string;
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
        const ms: IData = ds;
        // console.log('myPros', ds.myPros);
        // // tslint:disable-next-line: no-string-literal
        // console.log('newProperty', ds['newProperty']);
        // console.log(ds.myMethod());
        // console.log('myClass', ds);
        // console.log('ms', ms);
        expect(ds.myPros).toEqual('My DataSource');
    });
});
