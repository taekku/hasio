import { TestBed } from '@angular/core/testing';

import { MenuService } from './menu.service';

describe('MenuService', () => {
  beforeEach(() => TestBed.configureTestingModule({}));

  it('should be created', () => {
    const service: MenuService = TestBed.get(MenuService);
    expect(service).toBeTruthy();
  });

  it('service name', () => {
    const service: MenuService = TestBed.get(MenuService);
    console.log(service);
    expect(service.getName()).toEqual('MenuService');
  });
});
