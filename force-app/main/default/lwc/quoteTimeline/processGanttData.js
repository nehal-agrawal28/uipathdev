/* eslint-disable no-unused-vars */
/* eslint-disable no-undef */
/* eslint-disable no-use-before-define */
import getGanttData_Apex from "@salesforce/apex/QuoteTimelineController_SQ.getGanttData"; // Apex method
import ganttConfigsPostData from "./ganttConfigsPostData";
import { pollCalculationStatus, timezoneDate } from "./util";

const processGanttData = (gantt, cmp) => {
  if (cmp.quoteId) {
    cmp.showSpinner = true;
    getGanttData_Apex({
      quoteId: cmp.quoteId
    })
      .then((result) => {
        console.dir(result);
        cmp.ganttData = result;
        loadDataIntoGantt(gantt, cmp, result);
        ganttConfigsPostData(gantt, cmp, cmp.ganttData);
        pollCalculationStatus(gantt, cmp.ganttData, cmp, false); // Poll qoute calculation status
      })
      .catch((error) => {
        console.error("Error " + JSON.stringify(error));
        cmp.showToast("Error", "Something went wrong. " + error, "error");
      })
      .finally(() => {
        cmp.showSpinner = false;
      });
  } else {
    cmp.showToast("Error", "Quote Id is missing!", "error");
  }
};

const loadDataIntoGantt = (gantt, cmp, ganttData) => {
  gantt.parse(mapDataToGantt(gantt, ganttData, cmp));
};

const mapDataToGantt = (gantt, ganttData, cmp) => {
  // console.log("InitialData", ganttData);
  const data = ganttData.quoteLines.map((a) => ({
    id: a.Id,
    text: a.SBQQ__ProductName__c,
    start_date: getLineStartDate(a),
    end_date: getLineEndDate(a),
    exisingSubscription: a.SBQQ__UpgradedSubscription__c ? true : false,
    parent: a.SBQQ__RequiredBy__c,
    quantity: a.SBQQ__Quantity__c,
    type: checkType(a, ganttData),
    progress: calculateProgress(a, ganttData),
    timeline_order: a.QuoteTimelineOrder__c,
    record: a
  }));
  const links = ganttData.quoteLineLinks.map((a) => ({
    id: a.Id,
    source: a.Source__c,
    target: a.Target__c,
    type: a.Type__c,
    lag: 1
  }));
  return { data, links };
};

const getLineStartDate = (a) => {
  let d = a.SBQQ__UpgradedSubscription__c
    ? a.SBQQ__UpgradedSubscription__r.SBQQ__StartDate__c
    : a.SBQQ__EffectiveStartDate__c;
  return timezoneDate(d);
};

const getLineEndDate = (a) => {
  let d =
    a.SBQQ__UpgradedSubscription__c && a.SBQQ__Quantity__c <= 0 ? getZeroSubEndDate(a) : a.SBQQ__EffectiveEndDate__c;
  return timezoneDate(d);
};

const processDataForLinkMode = (gantt, cmp, ganttData) => {
  let tasks = gantt.getTaskByTime();
  let links = gantt.getLinks();
  for (let i = 0; i < tasks.length; i++) {
    let task = tasks[i];
    task.parent = cmp.linkMode ? null : task.record.SBQQ__RequiredBy__c;
    task.type = cmp.linkMode ? "" : checkType(task.record, ganttData);
  }
  gantt.parse({ tasks, links });
};

const getZeroSubEndDate = (a) => {
  let subStartDate = new Date(a.SBQQ__EffectiveStartDate__c);
  return new Date(subStartDate.setDate(subStartDate.getDate() - 1));
};

const checkType = (a, ganttData) => {
  for (let ql of ganttData.quoteLines) {
    if (ql.SBQQ__RequiredBy__c === a.Id) {
      return "project"; // bundle product
    }
  }
  return "";
};

const calculateProgress = (a, ganttData) => {
  if (a.SBQQ__UpgradedSubscription__c) {
    let subStart = new Date(a.SBQQ__UpgradedSubscription__r.SBQQ__StartDate__c);
    let quoteLineEnd = new Date(a.SBQQ__EffectiveEndDate__c);
    let quoteStart = new Date(ganttData.quote.SBQQ__StartDate__c);
    if (quoteStart - subStart < 0) {
      return 0;
    }
    return (quoteStart - subStart) / (quoteLineEnd - subStart);
  }
  return 0;
};

const sortGanttFunction = (aTask, bTask) => {
  return aTask.timeline_order > bTask.timeline_order ? 1 : aTask.timeline_order < bTask.timeline_order ? -1 : 0;
};

export { processGanttData, processDataForLinkMode, sortGanttFunction };