/* eslint-disable no-unused-vars */
/* eslint-disable no-undef */
/* eslint-disable no-use-before-define */
import { buildARRData, getChartBoundary } from "./util";

const overlayARR = (gantt, cmp, ganttData) => {
  let overlayControl = gantt.ext.overlay;
  let chartData = buildARRData(gantt, cmp, ganttData);

  // Build ARR chart
  cmp._overlayARRId = overlayControl.addOverlay((container) => {
    let canvas = document.createElement("canvas");
    container.appendChild(canvas);
    canvas.style.height = container.offsetHeight + "px";
    canvas.style.width = container.offsetWidth + "px";

    let ctx = canvas.getContext("2d");
    if (cmp._overlayARRChart) {
      cmp._overlayARRChart.destroy();
    }
    cmp._overlayARRChart = new Chart(ctx, {
      type: "line",
      data: {
        datasets: [
          {
            label: "Total ARR",
            backgroundColor: "#CC0000",
            borderColor: "#9900CC",
            currencyCode: ganttData.quote.CurrencyIsoCode,
            data: chartData.arrPoints,
            fill: false,
            cubicInterpolationMode: "monotone"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        layout: {
          padding: getScalePaddings(gantt, ganttData)
        },
        onResize: (chart, newSize) => {
          let dataRange = getChartBoundary(gantt, ganttData);
          if (dataRange.start_date) {
            // align chart with the scale range
            chart.options.layout.padding = getScalePaddings(gantt, ganttData);
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          mode: "index",
          intersect: false,
          callbacks: {
            label: function (tooltipItem, data) {
              let dataset = data.datasets[tooltipItem.datasetIndex];
              return (
                dataset.label +
                ": " +
                parseFloat(dataset.data[tooltipItem.index].y).toLocaleString(undefined, { maximumFractionDigits: 2 }) +
                " " +
                dataset.currencyCode
              );
            }
          }
        },
        hover: {
          mode: "nearest",
          intersect: true
        },
        scales: {
          xAxes: [
            {
              type: "time",
              time: {
                tooltipFormat: "DD/MM/YYYY",
                min: getChartBoundary(gantt, ganttData).start_date,
                max: getChartBoundary(gantt, ganttData).end_date,
                unit: "day"
              },
              gridLines: {
                display: false
              },
              ticks: {
                display: false
              }
            }
          ],
          yAxes: [
            {
              display: true,
              gridLines: {
                display: false
              },
              ticks: {
                display: true,
                min: chartData.minARR,
                max: chartData.maxARR,
                stepSize: chartData.maxARR / ganttData.quoteLines.length,
                callback: function (current) {
                  return "";
                }
              }
            },
            {
              display: true,
              position: "right",
              gridLines: {
                display: false
              },
              ticks: {
                display: true,
                min: chartData.minARR,
                max: chartData.maxARR,
                stepSize: chartData.maxARR / ganttData.quoteLines.length,
                callback: function (current) {
                  return "";
                }
              }
            }
          ]
        }
      }
    });
    return canvas;
  });
};

const getScalePaddings = (gantt, ganttData) => {
  let scale = gantt.getScale();
  let dataRange = getChartBoundary(gantt, ganttData);

  let padding = {
    left: 0,
    right: 0
  };

  if (dataRange.start_date) {
    // let yScaleLabelsWidth = 96;
    let yScaleLabelsWidth = 16;
    // fine tune values in order to align chart with the scale range
    padding.left = gantt.posFromDate(dataRange.start_date) - yScaleLabelsWidth;
    padding.right = scale.full_width - gantt.posFromDate(dataRange.end_date) - yScaleLabelsWidth;
    padding.top = gantt.config.row_height - 12;
    padding.bottom = gantt.config.row_height - 12;
  }
  return padding;
};

export default overlayARR;