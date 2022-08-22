/* eslint-disable no-unused-vars */
/* eslint-disable radix */
const columnResizerJs = function (component) {
  let table = component.template.querySelector("table.data-table");
  let row = table.getElementsByTagName("tr")[0]; // header row
  let cols = row ? row.children : undefined;
  if (!cols) return;

  table.style.overflow = "hidden";
  for (let i = 0; i < cols.length; i++) {
    cols[i].style.position = "relative";
  }

  let resizerDivs = component.template.querySelectorAll("div.column-resizer");
  for (let i = 0; i < resizerDivs.length; i++) {
    setListeners(resizerDivs[i]);
  }
};

function setListeners(div) {
  let pageX, curCol, nxtCol, curColWidth, nxtColWidth;

  div.addEventListener("mousedown", function (e) {
    curCol = e.target.parentElement;
    nxtCol = curCol.nextElementSibling;
    pageX = e.pageX;

    let padding = paddingDiff(curCol);

    curColWidth = curCol.offsetWidth - padding;
    if (nxtCol) nxtColWidth = nxtCol.offsetWidth - padding;
  });

  document.addEventListener("mousemove", function (e) {
    if (curCol) {
      let diffX = e.pageX - pageX;

      if (nxtCol) {
        nxtCol.style.width = nxtColWidth - diffX + "px";
        nxtCol.style.maxWidth = nxtColWidth - diffX + "px";
      }

      curCol.style.width = curColWidth + diffX + "px";
      curCol.style.maxWidth = curColWidth + diffX + "px";
    }
  });

  document.addEventListener("mouseup", function (e) {
    curCol = undefined;
    nxtCol = undefined;
    pageX = undefined;
    nxtColWidth = undefined;
    curColWidth = undefined;
  });
}

function paddingDiff(col) {
  if (getStyleVal(col, "box-sizing") === "border-box") {
    return 0;
  }

  let padLeft = getStyleVal(col, "padding-left");
  let padRight = getStyleVal(col, "padding-right");
  return parseInt(padLeft) + parseInt(padRight);
}

function getStyleVal(elm, css) {
  return window.getComputedStyle(elm, null).getPropertyValue(css);
}

export { columnResizerJs };