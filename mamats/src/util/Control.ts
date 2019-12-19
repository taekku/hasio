interface PingDecorator {
  // Idenditity of Service
  serviceId: string;
  // Kind of Service
  kind?: string;
}
function makeDecorator<T extends PingDecorator>(name: string, deco: T): (deco: PingDecorator) => any {
  function DecoratorFactory(a: T = deco) {
    let myDeco: PingDecorator = {...a};
    myDeco.kind = name;
    return function classDecorator<T1 extends {new(...args: any[]): {}}>(target: T1): T1{
      return class extends target {
        service = myDeco;
      }
    }
  }
  return DecoratorFactory as any;
}
const Action = makeDecorator('Action', {serviceId: 'default'});

@Action({serviceId: 'DefaultAction'})
export class DefaultAction {
  private service: PingDecorator = {serviceId:''};
  constructor(){
  }
  retrieve(...args: any): any[] {
    // if( this.service )
      console.log('serviceId', this.service.serviceId);
    return [{}];
  }
  save(msg: any[]): boolean {
    return true;
  }

}
