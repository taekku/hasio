export function logClass<TFunction extends () => void>(target: TFunction) {

  // save a reference to the original constructor
  const originalConstructor = target;

  function logClassName(func: TFunction) {
      console.log('New: ' + func.name);
  }

  // a utility function to generate instances of a class
  function instanciate(constructor: any, ...args: any[]) {
      return new constructor(...args);
  }

  // the new constructor behaviour
  const newConstructor = (...args: any[]) => {
      logClassName(originalConstructor);
      return instanciate(originalConstructor, ...args);
  };

  // copy prototype so instanceof operator still works
  newConstructor.prototype = originalConstructor.prototype;

  // return new constructor (will override original)
  return newConstructor as any;
}

export function logMethod(
  target: any,
  key: string,
  descriptor: TypedPropertyDescriptor<any>
) {

  // save a reference to the original method
  const originalMethod = descriptor.value;

  function logFunctionCall(method: string, args: string, result: string) {
      console.log(`Call: ${method}(${args}) => ${result}`);
  }

  // editing the descriptor/value parameter
  descriptor.value = function(this: any, ...args: any[]) {

      // convert method arguments to string
      const argsStr = args.map((a: any) => {
          return JSON.stringify(a);
      }).join();

      // invoke method and get its return value
      const result = originalMethod.apply(this, args);

      // convert result to string
      const resultStr = JSON.stringify(result);

      // display in console the function call details
      console.log();
      console.log(`Call: ${key}(${argsStr}) => ${resultStr}`);

      // return the result of invoking the method
      return result;
  };

  // return edited descriptor
  return descriptor;
}

export function logProperty(target: any, key: string) {

  // property value
  // tslint:disable-next-line:variable-name
  let __val = target[key];

  function logPropertyAccess(acces: 'Set' | 'Get', k: string, v: any) {
      console.log(`${acces}: ${k} => ${v}`);
  }

  // property getter
  const getter = () => {
      logPropertyAccess('Get', key, __val);
      return __val;
  };

  // property setter
  const setter = (newVal: any) => {
      logPropertyAccess('Set', key, newVal);
      __val = newVal;
  };

  // Delete property. The delete operator throws
  // in strict mode if the property is an own
  // non-configurable property and returns
  // false in non-strict mode.
  if (delete target[key]) {
      Object.defineProperty(target, key, {
          get: getter,
          set: setter,
          enumerable: true,
          configurable: true
      });
  }
}

export function readMetadata(target: any, key: string, descriptor: any) {

  const originalMethod = descriptor.value;

  descriptor.value = function(...args: any[]) {

      const metadataKey = `_log_${key}_parameters`;
      const indices = target[metadataKey];

      if (Array.isArray(indices)) {

          for (let i = 0; i < args.length; i++) {

              if (indices.indexOf(i) !== -1) {
                  const arg = args[i];
                  const argStr = JSON.stringify(arg);
                  console.log(`${key} arg[${i}]: ${argStr}`);
              }
          }

          return originalMethod.apply(this, args);

      }

  };

  return descriptor;
}

export function addMetadata(target: any, key: string, index: number) {
  const metadataKey = `_log_${key}_parameters`;
  if (Array.isArray(target[metadataKey])) {
      target[metadataKey].push(index);
  } else {
      target[metadataKey] = [index];
  }
}

function decoratorFactory(
  classDecorator: Function,
  propertyDecorator: Function,
  methodDecorator: Function,
  parameterDecorator: Function
) {
  return function(this: any, ...args: any[]) {
    const nonNullableArgs = args.filter( a => a !== undefined);
    switch (nonNullableArgs.length) {
      case 1:
        return classDecorator.apply(this, args);
        case 2:
            // break instead of return as property
            // decorators don't have a return
            propertyDecorator.apply(this, args);
            break;
        case 3:
            if (typeof args[2] === 'number') {
                parameterDecorator.apply(this, args);
            } else {
                return methodDecorator.apply(this, args);
            }
            break;
        default:
            throw new Error('Decorators are not valid here!');
    }
  };
}

const log = decoratorFactory(
  logClass,
  logProperty,
  readMetadata,
  addMetadata
);

