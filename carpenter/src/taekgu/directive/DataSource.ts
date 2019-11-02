export interface IData {
  newProperty: string
}

export function DataSource<T extends {new(...args: any[]): {}}>(construnctor: T) {
  return class extends construnctor {
    // class construnctor를 CALL한 후에 수행
    newProperty = 'new Property';
    myPros = 'My DataSource';
    kkk = console.log('MyDataSourceExteneds', arguments, construnctor.name, this);
  };
}

export function Lim() {
  // 선언시에..
  console.log('Lim() evaluated');
  // tslint:disable-next-line: only-arrow-functions
  return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    console.log('Lim() call..');
    console.log('target', target);
    console.log('propertyKey', propertyKey);
    console.log('descriptor', descriptor);
    // return 'my decorator';
  };
}
