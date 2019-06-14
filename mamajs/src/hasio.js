"use strict";
import "@babel/polyfill";
import { Jumin } from './hasio/common/type/jumin.js';

let jumin = new Jumin('asdf');


const myObj = {
  runTimeout() {
    setTimeout(()=>{ // 여러번실행
    // setInterval(()=>{ // 한번실행
      this.printData();
    }, 200);
  },
  printData(){
    console.log('hi codesquad! Hello');
  }
}

myObj.runTimeout();

console.log(jumin);