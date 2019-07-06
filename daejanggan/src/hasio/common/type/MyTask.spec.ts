import { stringify } from "querystring";

describe('이것이 ts맞나?', ()=>{

  it("check typescript", ()=>{
    let myNum:number;
    let asf: string;
    myNum = 10
    expect(10).toEqual(myNum);

    asf = "kkkkk";
    expect("kkkkk").toEqual(asf);
  });
})