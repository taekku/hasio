
enum FieldType {
  Char,
  VarChar,
  Number,
  Decimal,
  CLOB,
  BLOB,
  Null
}
interface Field {
  name: string;
  type: FieldType;
};

// interface Model {
//   length: number;
//   cols: Field[];
//   data: User[];
// };

interface User {
  user_id: number;
  login_id: string;
  name: string;
  roles: string[];
}

class TRecord<T> {
  data: T[];
  get length(): number {
    return this.data.length;
  }
  addRecord(val: T) {
    this.data.push(val);
  }
  getRecord(idx: number): T {
    return this.data[idx];
  }
  setRecord(idx: number, val: T) {
    this.data[idx] = val;
  }
}

let UserTable: TRecord<User> = new TRecord<User>();
