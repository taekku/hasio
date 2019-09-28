import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class UserService {

  constructor() { }

  login(user): boolean {
    return false;
  }

  get name() {
    return 'Taekgu Lim';
  }

  get authority() {
    return true;
  }

  hasAutority(oid: string): boolean {
    return true;
  }
}
