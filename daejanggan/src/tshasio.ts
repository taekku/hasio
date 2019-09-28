import * as monaco from 'monaco-editor';
import {Greeter} from './hasio/core/DataSource'
import {TDate} from './hasio/type/TDate'
console.log('loaded tshasio.ts')

let day = new TDate('20190228');
console.log('day', day.dateId)