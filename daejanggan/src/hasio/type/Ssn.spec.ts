import { Ssn, Gender } from "./Ssn";

describe("Ssn src Ssn.spec.ts", ()=>{
  beforeAll(()=>{
  });
  afterAll(()=>{
  });
  it("gender()", ()=>{
    let jumin:Ssn;
    // const female: Gender = Gender.F
    jumin = new Ssn("7205201382418");
    expect(jumin.gender()).toEqual(1);
    expect(jumin.gender()).toEqual(Gender.M);
    jumin = new Ssn("7205200382418");
    expect(jumin.gender()).toEqual(2);
    expect(jumin.gender()).toEqual(Gender.F);
  });
  it("validation()", ()=>{
    let jumin:Ssn;
    jumin = new Ssn("7205201382418");
    expect(jumin.isValidation()).toEqual(true);
    expect(jumin.getMessage()).toEqual('');

    jumin = new Ssn("7205200382419");
    expect(jumin.isValidation()).toEqual(false);
    expect(jumin.getMessage()).toContain('올바른');
  });
  it("birth()", ()=>{
    let jumin:Ssn;
    jumin = new Ssn("7205201382418");
    expect(jumin.birth()).toEqual(new Date("1972-05-20Z+09:00"));
    jumin = new Ssn("7205203382414");
    expect(jumin.birth()).toEqual(new Date("2072-05-20Z+09:00"));
  });
  it("jumin_no()", ()=>{
    let jumin:Ssn;
    jumin = new Ssn("7205200382418");
    expect(jumin.jumin_no()).toEqual("7205200382418");
  });
});