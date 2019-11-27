export interface PingDecorator {
  kk?: string;
  ping?: string[];
}


export function myDecorator<T extends PingDecorator>(deco: T) {

  function classDecorator<T extends {new(...args:any[]):{}}>(cls:T) {
    return class extends cls {
        newProperty = "new property";
        hello = "override";
        myDecoderatorName = deco;
    }
  }
  return classDecorator;
}