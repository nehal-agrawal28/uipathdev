/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-unused-vars */
/* eslint-disable no-use-before-define */
import saveGanttData_Apex from "@salesforce/apex/QuoteTimelineController_SQ.saveGanttData";
import { buildARRData, pollCalculationStatus } from "./util";

const saveGanttData = (gantt, ganttData, cmp) => {
  let ganttTasks = [];
  let ganttLinks = [];

  // get tasks and links
  gantt.eachTask((task) => {
    ganttTasks.push(task);
  });
  ganttLinks = gantt.getLinks();

  // perform data validations
  let errors = performValidations(ganttTasks, ganttLinks, gantt, ganttData, cmp);
  if (errors && errors.length > 0) {
    for (let err of errors) {
      cmp.showToast("Error", err, "error");
    }
    return;
  }

  // perform DML operations
  cmp.showSpinner = true;
  let dataToSave = mapGanttDataToSF(ganttTasks, ganttLinks, gantt, ganttData, cmp);
  saveGanttData_Apex({
    quoteId: cmp.quoteId,
    quoteLines: dataToSave.quoteLines,
    quoteLineLinks: dataToSave.quoteLineLinks
  })
    .then((result) => {
      cmp.showToast("Success", "Quote updated successfully.", "success");
      gantt.clearUndoStack();
      gantt.clearRedoStack();

      cmp.isQuoteCalculating = true;
      setTimeout(() => {
        pollCalculationStatus(gantt, ganttData, cmp, true);
      }, 2000);
    })
    .catch((error) => {
      console.error("Error " + JSON.stringify(error));
      cmp.showToast("Error", error?.body?.message, "error");
    })
    .finally(() => {
      cmp.showSpinner = false;
    });
};

const performValidations = (ganttTasks, ganttLinks, gantt, ganttData, cmp) => {
  let error = [];
  // task ending ealier than quote end date must have a link to another task
  for (let task of ganttTasks) {
    if (
      !task.exisingSubscription &&
      +task.end_date.setHours(0, 0, 0, 0) < +new Date(ganttData.quote.SBQQ__EndDate__c).setHours(0, 0, 0, 0) &&
      task.$source.length <= 0 &&
      task.record.CPQ_QliARR__c > 0
    ) {
      gantt.getTaskNode(task.id).classList.add("task_validation_error");
      error.push(
        `'${task.text}' must have a link to another product to carry ARR through the end date. Switch to Linking Mode to add a link.`
      );
    }
  }
  // ARR must not reduce at any point
  if (error.length === 0) {
    let arrPoints = buildARRData(gantt, cmp, ganttData).arrPoints;
    for (let i = 1; i < arrPoints.length; i++) {
      if (arrPoints[i].y < arrPoints[i - 1].y) {
        error.push("ARR must not reduce at any point for the whole quote duration.");
        if (!gantt.ext.overlay.isOverlayVisible(cmp._overlayARRId)) {
          cmp.toggleARROverlay();
        }
        break;
      }
    }
  }
  return error;
};

const mapGanttDataToSF = (ganttTasks, ganttLinks, gantt, ganttData, cmp) => {
  let quoteLines = [];
  let quoteLineLinks = [];

  quoteLines = ganttTasks.filter(filterQuoteLines).map(mapQuoteLineFields);
  quoteLineLinks = ganttLinks.filter(filterQuoteLineLinks).map(mapQuoteLineLinkFields);
  return { quoteLines, quoteLineLinks };
};

const filterQuoteLines = (task) => {
  return true;
};

const mapQuoteLineFields = (task) => {
  if (task.exisingSubscription) {
    // only update order field for existing subscriptions
    return {
      Id: task.id,
      QuoteTimelineOrder__c: task.timeline_order
    };
  }
  return {
    Id: task.id,
    SBQQ__StartDate__c: getApexDate(task.start_date),
    SBQQ__EndDate__c: getApexDate(task.end_date),
    QuoteTimelineOrder__c: task.timeline_order
  };
};

const filterQuoteLineLinks = (link) => {
  return true;
};

const mapQuoteLineLinkFields = (link) => {
  return {
    Source__c: link.source,
    Target__c: link.target,
    Type__c: link.type
  };
};

const getApexDate = (dateStr) => {
  let date = new Date(dateStr);
  // example : 2022-02-01
  return date.getFullYear() + "-" + ("0" + (date.getMonth() + 1)).slice(-2) + "-" + ("0" + date.getDate()).slice(-2);
};

export default saveGanttData;