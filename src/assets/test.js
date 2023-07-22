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