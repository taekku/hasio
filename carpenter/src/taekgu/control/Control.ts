interface PingDecorator {
  // Idenditity of Service
  serviceId: string;
  // Kind of Service
  kind?: string;
}
function makeDecorator<T extends PingDecorator>(name: string, deco: T): (deco: PingDecorator) => any {
  function DecoratorFactory(a: T = deco) {
    return function classDecorator<T1 extends {new(...args: any[]): {}}>(target: T1): T1{
      return class extends target {
        service = a;
      }
    }
  }
  return DecoratorFactory as any;
}
const Control = makeDecorator('Action', {serviceId: 'default'});

@Control({serviceId: 'DefaultControl'})
export class DefaultControl {

  retrieve(...args: any): any[] {
    return [{}];
  }
  save(msg: any[]): boolean {
    return true;
  }

}
