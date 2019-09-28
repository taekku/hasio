import {IService} from './TService';

describe('TService', ()=>{
  it('IService', ()=>{
    let service: IService = {
      id:'my',
      request: [],
      result: []
    };
    console.log('service', service);
    expect('my').toEqual(service.id);
  })
})