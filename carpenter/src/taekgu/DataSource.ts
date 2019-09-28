
export function DataSource<T extends {new(...args: any[]): {}}>(construnctor: T) {
  return class extends construnctor {
    myPros = 'My DataSource';
  };
}

