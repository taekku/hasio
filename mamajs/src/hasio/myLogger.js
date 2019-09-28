export function log(data){
  console.log(data);
}

export const getTime = () => {
  return Date.now();
}

export const getCurrentHour = () => {
  return (new Date).getHours();
}

/* Class */
export class MyLogger {
  constructor(props) {
    this.lectures = ['java','iOS'];
  }
  getLectures() {
    return this.lectures;
  }
}