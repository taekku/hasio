import {Org} from './Organization'

describe('Organization', ()=>{

  it('constructor', ()=>{
    const org = new Org({ line: '/', id: 10, org_name: 'Organization Name' })
    expect(10).toEqual(org.oid);
    expect('Organization Name').toEqual(org.name);
  })
  
  it('Property', ()=>{
    const org =  new Org( { line: '/', id: 11 });
    org.name = 'Good';
    expect('Good').toEqual(org.name);
  })

  it('Append Child Organization', ()=>{
    const org = new Org({ line: '/', id: 0, org_name: '' });
    const child1 = new Org({ line: '/10', id: 10, org_name: 'Department_1' })
    const child2 = new Org({ line: '/11', id: 11, org_name: 'Department_2' })
    const child3 = new Org({ line: '/10/01', id: 12, org_name: 'Department_3' })
    const child4 = new Org({ line: '/10/02', id: 13, org_name: 'Department_4' })
    const child5 = new Org({ line: '/11/01', id: 14, org_name: 'Department_5' })
    org.append(child1)
    expect([child1]).toEqual(org.children)
    org.append(child2)
    expect([child1, child2]).toEqual(org.children)
    org.append(child3)
    expect([child1, child2]).toEqual(org.children)
    org.append(child4)
    expect([child1, child2]).toEqual(org.children)
    expect([child3, child4]).toEqual(org.children[0].children)

    expect(0).toEqual(org.children[1].children.length)
    org.append(child5)
    expect([child5]).toEqual(org.children[1].children)
  })
})