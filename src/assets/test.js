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

document.getElementById("btn6").addEventListener('click', e => {
    alert('test')
  });

  document.getElementById("btn7").addEventListener('click', e => {
    confirm('test')
  });

document.getElementById('fileInput').addEventListener('change', function(event) {
  const fileList = event.target.files;
  if (fileList.length > 0) {
      const file = fileList[0];
      console.log('Selected file:', file.name);
      // You can process the file further here
  }
});

// });
