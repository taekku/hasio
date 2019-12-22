import {request} from 'http';

export class ServerInfo {
  constructor(){

  }

  public getUrl(){
    return '/Pingpong';
  }

  public getInfo(){
    const req = request(
      {
        host: 'localhost',
        path: '/Pingpong',
        port: 8081,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
      },
      response => {
        const chunks: any[] = [];
        response.on('data', (chunk) => {
          chunks.push(chunk);
        });
        response.on('end', () => {
          const result = Buffer.concat(chunks).toString();
          console.log(result);
        });
      }
    );
    
    req.write(JSON.stringify({
      author: 'Taekgu',
      title: 'GoldGaram',
      content: 'Garam means the river.'
    }));

    req.end();
  }
}