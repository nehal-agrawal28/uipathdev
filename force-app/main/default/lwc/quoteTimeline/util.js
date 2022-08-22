/* eslint-disable no-else-return */
/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-use-before-define */
/* eslint-disable no-unused-vars */
import pollQuoteCalculationStatus_Apex from "@salesforce/apex/QuoteTimelineController_SQ.pollQuoteCalculationStatus";

const createCookie = (document, name, value, days) => {
  var expires;
  if (days) {
    const date = new Date();
    date.setTime(date.getTime() + days * 24 * 60 * 60 * 1000);
    expires = "; expires=" + date.toGMTString();
  } else {
    expires = "";
  }
  document.cookie = name + "=" + escape(value) + expires + "; path=/";
};

const setCookies = (document, name, value) => {
  createCookie(document, name, value, null);
};

const getCookie = (document, name) => {
  var cookieString = "; " + document.cookie;
  var parts = cookieString.split("; " + name + "=");
  if (parts.length === 2) {
    return parts.pop().split(";").shift();
  }
  return null;
};

const buildARRData = (gantt, cmp, ganttData) => {
  let dateAndARRMap = new Map();
  let sortedDateAndARRMap = new Map();
  let arrPoints = [];
  let minARR = 0;
  let maxARR = 0;

  // collect dates
  let dataRange = getChartBoundary(gantt, ganttData);
  dateAndARRMap.set(+dataRange.start_date, 0);
  dateAndARRMap.set(+dataRange.end_date, 0);
  for (let task of gantt.getTaskByTime()) {
    let sd = task.start_date.setHours(0, 0, 0, 0);
    let ed = task.end_date.setHours(0, 0, 0, 0);
    if (!dateAndARRMap.has(+sd)) {
      dateAndARRMap.set(+sd, 0);
    }
    if (!dateAndARRMap.has(+ed)) {
      dateAndARRMap.set(+ed, 0);
    }
    // add 1+ day when task ends before quote end date
    if (+ed < +dataRange.end_date) {
      let edNextDay = new Date(ed.valueOf());
      edNextDay = new Date(edNextDay.setDate(edNextDay.getDate() + 1)).setHours(0, 0, 0, 0);
      dateAndARRMap.set(+edNextDay, 0);
    }
  }
  // sort dates
  let sortedDates = [...dateAndARRMap.keys()].sort((a, b) => {
    return a - b;
  });
  for (let dtKey of sortedDates) {
    sortedDateAndARRMap.set(dtKey, dateAndARRMap.get(dtKey));
  }
  // sum ARR for the date
  for (let dtKey of sortedDateAndARRMap.keys()) {
    for (let task of gantt.getTaskByTime()) {
      let sd = task.start_date.setHours(0, 0, 0, 0);
      let ed = task.end_date.setHours(0, 0, 0, 0);
      if (dtKey >= +sd && +dtKey <= +ed) {
        sortedDateAndARRMap.set(
          dtKey,
          parseFloat(sortedDateAndARRMap.get(dtKey)) +
            (!isNaN(task.record.CPQ_QliARR__c) ? parseFloat(task.record.CPQ_QliARR__c) : 0)
        );
      }
    }
  }
  // build data array
  for (let dtKey of sortedDateAndARRMap.keys()) {
    let currentArr = sortedDateAndARRMap.get(dtKey);
    if (currentArr < minARR) {
      minARR = currentArr;
    }
    if (currentArr > maxARR) {
      maxARR = currentArr;
    }
    arrPoints.push({
      x: new Date(dtKey),
      y: currentArr
    });
  }

  return { arrPoints: arrPoints, minARR: minARR, maxARR: maxARR };
};

const getChartBoundary = (gantt, ganttData) => {
  return {
    start_date: new Date(ganttData.quote.SBQQ__StartDate__c).setHours(0, 0, 0, 0),
    end_date: new Date(ganttData.quote.SBQQ__EndDate__c).setHours(0, 0, 0, 0)
  };
};

const pollCalculationStatus = (gantt, ganttData, cmp, autoReload) => {
  console.log("polling calculation status " + cmp.quoteId);
  pollQuoteCalculationStatus_Apex({
    quoteId: cmp.quoteId
  })
    .then((result) => {
      console.log("calculation status result " + result);
      if (["Unknown", "Aborted", "Completed", "Failed"].includes(result)) {
        if (autoReload) {
          setTimeout(() => {
            cmp.isQuoteCalculating = false;
            window.location.reload();
          }, 1000);
        }
      } else {
        cmp.isQuoteCalculating = true;
        setTimeout(() => {
          pollCalculationStatus(gantt, ganttData, cmp, true);
        }, 5000);
      }
    })
    .catch((error) => {
      console.error("Error " + JSON.stringify(error));
      cmp.showToast("Error", error?.body?.message, "error");
    });
};

const stdTimezoneOffset = () => {
  const today = new Date();
  var jan = new Date(today.getFullYear(), 0, 1);
  var jul = new Date(today.getFullYear(), 6, 1);
  return Math.max(jan.getTimezoneOffset(), jul.getTimezoneOffset());
};

const isDstObserved = () => {
  const today = new Date();
  return today.getTimezoneOffset() < stdTimezoneOffset();
};

const timezoneDate = (d) => {
  const today = new Date();
  // get current browser timezone differences with UTC
  let diff = today.getTimezoneOffset();
  d = new Date(d);
  if (isDstObserved) {
    return new Date(d.getTime() + (diff + 120) * 60000);
  } else {
    return new Date(d.getTime() + diff * 60000);
  }
};

export { setCookies, getCookie, buildARRData, getChartBoundary, pollCalculationStatus, timezoneDate };