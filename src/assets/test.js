// window.addEventListener("DOMContentLoaded", (event) => {
  
document.getElementById("btn1").addEventListener('click', e => {
  api.info({
    title: "info title",
    description: "info description"
  });
});

document.getElementById("btn2").addEventListener('click', e => {
api.warning({
  title: "warning title",
  description: "warning description"
});

});

document.getElementById("btn3").addEventListener('click', e => {
api.error({
  title: "error title",
  description: "error description"
});
});

document.getElementById("btn4").addEventListener('click', e => {
api.chooseFile();
});

document.getElementById("btn5").addEventListener('click', e => {
api.saveFile();
});

// });
