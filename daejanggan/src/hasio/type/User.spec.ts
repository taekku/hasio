import { User } from './User'

describe('class User', ()=>{
  it('User', ()=>{
    const login_id = 'tglim'
    const user = new User({login_id, user_name:'임택구'})
    expect(login_id).toEqual(user.loginId)
    expect('임택구').toEqual(user.userName);
  })

  it('checked logined',()=>{
    const user = new User({login_id:'tglim', user_name:'임택구'})
    expect(true).toEqual(user.logined())
  })
})