// import MamaRoutes from 'routes';
// dev-server.js
const express = require('express');

// 전통방식의 GET파라메터 분석에 필요
const url = require('url');

// 요청에 따라 html페이지를 읽어서 서비스하기 위해 필요
var fs = require('fs');

// bodyParser - POST파라메터 추출에 필요
const bodyParser = require('body-parser');

const app = express();
// bodyParser - POST파라미터 추출에 필요 - Start
app.use(bodyParser.urlencoded({ extended: true})); // support encoded bodies

// Import routes
// require('./_routes')(app);   // <-- or whatever you do to include your API endpoints and middleware
app.set('port', 5433);
app.get('/', (req, res)=>{
  console.log('mylog tglim');
  res.send('good1');
  //res.render();
  res.status('200');
});


// CASE1 - RESTFul 요청처리
app.get('/api/:version', (req, res)=>{
  res.send(req.params.version);
});

// CASE2 - GET방식 요청 처리
app.get('/getparam', (req, res)=>{
  let parseObj = url.parse(req.url, true);
  var id = parseObj.query.id;
  var name = parseObj.query.name;
  console.log(`id : ${id}, name : ${name}`);

  res.send(`id : ${id}, name : ${name}`);
});

// GET방식으로 로그인 페이지 보여준다.
app.get('/login', (req, res) => {
  fs.readFile('login.html', { encoding: 'utf-8' }, (error, data) => {
    //res.send(error);
    //res.setHeader("type", "text/html");
    res.status(200);
    res.send(data);
    // res.send('와우');
    console.log(data);
    console.log(toString(data));
    //res.send(data.toString());
  });
});

// CASE3 - POST방식요청처리(로그인 페이지에서 POST방식으로 호출한다.)
app.post('/login', (req, res) => {
  const userid = req.body.userid;
  const passwd  = req.body.passwd;

  console.log(userid, password);
  if( userid==='tglim'){
    res.send('Login Success');
  } else {
    res.redirect('/login');
  }
})

// CASE4 - GET, POST방식요청의 다른 처리 방법
app.use( (req, res) => {
  const methodType = req.method;
  if( methodType === 'GET' ){
    // url 속성을 이용한 경로 구분
    const pathname = url.parse( req.url ).pathname;
  } else if( methodType === 'POST' ) {
    // POST방식 파라메터 얻기
    const deptName = req.body.deptName;
    const empList = req.body.empList;
    const msg = `deptName : ${ deptName }, empList : ${ empList }`;
    console.log(msg);
    res.send(msg);
  }
});



app.post('/mypost', (req, res)=>{
  console.log('post:mypost');
  console.log('header', header);
  console.log('query', query);
  console.log('body', body);
  res.send('console.log(post)');
  res.status('200');
});
// RESTFul 요청처리
app.get('/mypost/:id', (req, res)=>{
  console.log('get:mypost');
  const {header, query, body, params} = req;
  console.log('header', header);
  console.log('query', query);
  console.log('body', body);
  console.log('id', req.params.id);
  res.send(`id = ${ params.id }`);
  res.status('200');
});

app.listen(app.get('port'), function() {
    console.log('Node App Started');
});