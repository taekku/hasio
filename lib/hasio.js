"use strict";

var _jumin = require("./hasio/common/type/jumin.js");

let jumin = new _jumin.Jumin('asdf');
console.log("Hello World!");
console.log(jumin);
console.log('my SSN:' + jumin.getSSN());
console.log('gender:' + jumin.gender());