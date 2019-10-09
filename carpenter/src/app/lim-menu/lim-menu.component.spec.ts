import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { LimMenuComponent } from './lim-menu.component';

describe('LimMenuComponent', () => {
  let component: LimMenuComponent;
  let fixture: ComponentFixture<LimMenuComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ LimMenuComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(LimMenuComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
