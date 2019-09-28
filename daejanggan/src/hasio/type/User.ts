import { Ssn } from "./Ssn";

/**
 * 사용자정보
 */
export class User {
  private _login_id: string
  private _user_name: string
  private valid: boolean
  private _ssn?: Ssn
  constructor({ login_id, user_name = '', user_ssn}: { login_id: string; user_name: string; user_ssn?: Ssn }){
    this._login_id = login_id
    this._user_name = user_name
    this.valid = true
    this._ssn = user_ssn
  }
  get loginId(): string{
    return this._login_id;
  }
  get userName(): string {
    return this._user_name
  }
  get ssn(): Ssn | null | undefined {
    return this._ssn
  }
  /**
   * 사용자가 유효한지?
   */
  private isValid = () => this.valid

  /**
   * 로그인했는지 체크
   */
  public logined = () => this.isValid()
}