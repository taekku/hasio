"use strict";
import { Jumin } from './hasio/common/type/jumin.js';

let jumin = new Jumin('asdf');

console.log("Hello World!");
console.log(jumin);
console.log('my SSN:' + jumin.getSSN());
console.log('my SSN:' + jumin.ssn());
console.log('gender:' + jumin.gender());