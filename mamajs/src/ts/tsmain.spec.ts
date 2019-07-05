import { MyTask } from '../hasio/common/type/MyTask'
  describe("Hasio with Typescript", ()=> {
    let task:MyTask = new MyTask();
    console.log(task.getName())
    it("테스트가 잘 작동하는 가?", ()=> {
      expect(true).toBe(true);
    })
    it('MyTask', ()=>{
      expect('임택구').toEqual(task.getName())
    })
  });
