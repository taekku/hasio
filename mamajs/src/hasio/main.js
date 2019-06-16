class Blog {
  constructor(){
    this.setInitVariables();
    this.registerEvents();
    this.likedSet = new Set();
  }

  setInitVariables() {
    this.blogList = document.querySelector(".blogList > ul");
  }

  registerEvents(){
    const dataURL = "/src/data/blog.json";
    const startBtn = document.querySelector(".start");
    //const blogList = document.querySelector(".blogList > ul");
    startBtn.addEventListener("click", ()=>{
      this.setInitData(dataURL);
    });

    this.blogList.addEventListener("click", ({target})=> {
      const targetClassName = target.className;
      console.log(targetClassName);
      // className이 like라면 내 찜 목록에 새로운 블로그제목을 추가한다.
      if(targetClassName !== "like") return;
      const postTitle = target.previousElementSibling.textContent;
      console.log('선택한 블로그 제목 ->', postTitle);
      this.likedSet.add(postTitle);
      this.likedSet.forEach((v)=>{
        console.log('set data is ', v);
      });
    });
  }

  setInitData(dataURL){
    this.getData(dataURL, this.insertPosts.bind(this));
  }

  getData(dataURL, fn){
    const oReq = new XMLHttpRequest();

    oReq.addEventListener("load", () => {
      //console.log(oReq.responseText)
      const list = JSON.parse(oReq.responseText);
      // list.forEach(v =>{
      //   console.log(v.title);
      // })
      fn(list);
    });

    oReq.open('GET', dataURL);
    oReq.send();
  }

  insertPosts(list){
    //const ul = document.querySelector(".blogList > ul");
    list.forEach( v => {
      this.blogList.innerHTML += `
        <li>
          <a href=${v.link}> ${v.title} </a>
          <div class="like">찜하기</div>
        </li>
      `;
    });
  }
}

export default Blog;