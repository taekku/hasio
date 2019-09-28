import * as monaco from 'monaco-editor';
 
self.MonacoEnvironment = {
	getWorkerUrl: function (moduleId, label) {
		if (label === 'json') {
			return '/dist/json.worker.bundle.js';
		}
		if (label === 'css') {
			return '/dist/css.worker.bundle.js';
		}
		if (label === 'html') {
			return '/dist/html.worker.bundle.js';
		}
		if (label === 'typescript' || label === 'javascript') {
			return '/dist/ts.worker.bundle.js';
		}
		return '/dist/editor.worker.bundle.js';
	}
}
 
// monaco.editor.create(document.getElementById('container'), {
// 	value: [
// 		'function x() {',
// 		'\tconsole.log("Hello world!");',
// 		'}'
// 	].join('\n'),
// 	language: 'sql'
// });

var mymodel = monaco.editor.createModel([
  'select *',
  'from dual',
  ';'
].join('\n'),
'sql'
);

monaco.editor.create(document.getElementById('container'), {
  model: mymodel
})


function myfunc(){
  let mymessage = document.getElementById("mymessage");
  mymessage.innerHTML = "click myfunc <br/>";
  mymessage.innerHTML += mymodel.getValue();
  mymessage.innerHTML += "<br />";
  console.log(mymodel);
  let line = mymodel.getLinesContent();
  line.map((value, index) => {
    mymessage.innerHTML += /* (index + 1) + " : " */ + value + "<br/>";
  });
}

let mybutton = document.getElementById("mybutton");
mybutton.addEventListener('click', ()=>{
  let mymessage = document.getElementById("mymessage");
  mymessage.innerHTML = "This is your source:<br />";
  let line = mymodel.getLinesContent();
  line.map((value, index) => {
    mymessage.innerHTML += (index + 1) + " : " + value + "<br/>";
  });
});

let mybutton2 = document.getElementById("reload");
mybutton2.addEventListener('click', ()=>{
  // mymodel.setValue(`select taekgu
  //   from dual;`);
    // let new_contents = xhr('/src/sql/mysql.sql');
    let mysource = '/src/sql/mysql.sql';
    console.log('source:', mysource);
    monaco.Promise.join([xhr(mysource)]).then(function(r) {
      let new_contents = r[0].responseText;
      console.log(new_contents);
      mymodel.setValue(new_contents);
    });
});


function xhr(url) {
  var req = null;
  return new monaco.Promise(function(c,e,p) {
    req = new XMLHttpRequest();
    req.onreadystatechange = function () {
      if (req._canceled) { return; }

      if (req.readyState === 4) {
        if ((req.status >= 200 && req.status < 300) || req.status === 1223) {
          c(req);
        } else {
          e(req);
        }
        req.onreadystatechange = function () { };
      } else {
        p(req);
      }
    };

    req.open("GET", url, true );
    req.responseType = "";

    req.send(null);
  }, function () {
    req._canceled = true;
    req.abort();
  });
}