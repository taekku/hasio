"use strict";
import "@babel/polyfill";
import { Jumin } from './hasio/common/type/jumin.js';
import blog from './hasio/main';
import {log, getTime, getCurrentHour} from './hasio/myLogger';

let jumin = new Jumin('asdf');


const previousObj = {
  name : "mama",
  lastTime : "11:20"
}

const myHealth = Object.assign({}, previousObj, {
  "lastTime" : "12:30"
});

console.log("previousObj is ", previousObj);
console.log("myhealth is ", myHealth);


log(myHealth);

log(`getTime is ${getTime()}`);
log(`current hour is ${getCurrentHour()}`);


const myObj = { name:'mama', changedValue:0 };
const proxy = new Proxy(myObj, {
  get: function(target, property, receiver){
    console.log('get Value')
    //return target[property];
    return Reflect.get(target, property, receiver);
  },
  set: function(target, property, value, receiver){
    console.log('set value');
    console.log('target : ', target);
    console.log('value :', value);
    target['changedValue']++;
    target[property] = value;
    return true;
  }
});

console.log('myObj : ', myObj);
console.log('proxy : ', proxy);
proxy.name = 'crong';
console.log('proxy : ', myObj);

const myblog = new blog();

console.log('myblog', myblog);