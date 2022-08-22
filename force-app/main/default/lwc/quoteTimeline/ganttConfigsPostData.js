/* eslint-disable consistent-return */
/* eslint-disable default-case */
/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable @lwc/lwc/no-inner-html */
/* eslint-disable vars-on-top */
/* eslint-disable no-unused-vars */
/* eslint-disable no-use-before-define */
import { timezoneDate } from "./util";

const ganttConfigsPostData = (gantt, cmp, ganttData) => {
  if (ganttData.isReadOnly) {
    gantt.config.readonly = true;
  }
  addTaskStyling(gantt, cmp, ganttData);
  addDurationMarker(gantt, cmp, ganttData);
  linkCreationValidate(gantt, cmp, ganttData);
  addTooltips(gantt, cmp, ganttData);
  ganttLightBoxConfig(gantt, cmp, ganttData);
  unselectRowsOnEmptyClick(gantt);
  dragHandling(gantt, cmp, ganttData);
  ganttLinkSettings(gantt, cmp, ganttData);
  // autoSchedulingTasks(gantt, cmp, ganttData);
  setZoomLevel(gantt, cmp, ganttData);
  rowOrderHandling(gantt, cmp, ganttData);
};

const addTaskStyling = (gantt, cmp, ganttData) => {
  gantt.templates.task_class = (start, end, task) => {
    if (task.record.SBQQ__UpgradedSubscription__c && task.record.SBQQ__Quantity__c <= 0) {
      return "exising_quoteline_removed";
    } else if (task.record.SBQQ__UpgradedSubscription__c) {
      return "exising_quoteline";
    } else if (task.record.SBQQ__Quantity__c <= 0) {
      return "negative_line";
    }
  };
  gantt.templates.task_text = (start, end, task) => {
    if (task.record.SBQQ__UpgradedSubscription__c) {
      return task.text + " (Existing Product)";
    }
    return task.text;
  };
};

const addDurationMarker = (gantt, cmp, ganttData) => {
  let startDate = timezoneDate(ganttData.quote.SBQQ__StartDate__c);
  let endDate = timezoneDate(ganttData.quote.SBQQ__EndDate__c);

  let quoteStartMarkerId = gantt.addMarker({
    start_date: startDate,
    css: "quote_start_marker",
    text: "Quote Start",
    title: gantt.date.date_to_str(gantt.config.date_grid)(startDate)
  });
  cmp._ganttMarkers.set("quote_start_marker", quoteStartMarkerId);

  let quoteEndMarkerId = gantt.addMarker({
    start_date: endDate,
    css: "quote_end_marker",
    text: "Quote End",
    title: gantt.date.date_to_str(gantt.config.date_grid)(endDate)
  });
  cmp._ganttMarkers.set("quote_end_marker", quoteEndMarkerId);

  if (ganttData.quote.SBQQ__MasterContract__c) {
    let contractStartDate = timezoneDate(ganttData.quote.SBQQ__MasterContract__r.StartDate);
    let contractStartMarkerId = gantt.addMarker({
      start_date: contractStartDate,
      css: "contract_start_marker",
      text: "Contract Start",
      title: gantt.date.date_to_str(gantt.config.date_grid)(contractStartDate)
    });
    cmp._ganttMarkers.set("contract_start_marker", contractStartMarkerId);
  }

  ganttData.billingSegments.forEach((segment, index) => {
    // skip first billing segment
    if (index > 0) {
      let bsDate = timezoneDate(segment.Start_Date__c);
      let markerId = gantt.addMarker({
        start_date: bsDate,
        css: "billing_segment_marker",
        text: "Segment " + (index + 1),
        title: "Billing Segment " + (index + 1) + " (" + gantt.date.date_to_str(gantt.config.date_grid)(bsDate) + ")"
      });
      cmp._ganttMarkers.set("billing_segment_marker_" + (index + 1), markerId);
    }
  });
};

const dragHandling = (gantt, cmp, ganttData) => {
  let leftLimit = timezoneDate(ganttData.quote.SBQQ__StartDate__c),
    rightLimit = timezoneDate(ganttData.quote.SBQQ__EndDate__c);

  gantt.attachEvent("onBeforeTaskDrag", (id, mode, e) => {
    let task = gantt.getTask(id);
    if (task.record.SBQQ__UpgradedSubscription__c) {
      return false;
    }
    return true;
  });

  gantt.attachEvent("onTaskDblClick", function (id, e) {
    let task = gantt.getTask(id);
    if (task.record.SBQQ__UpgradedSubscription__c) {
      return false;
    }
    return true;
  });

  gantt.attachEvent("onTaskDrag", function (id, mode, task, original) {
    let modes = gantt.config.drag_mode;
    if (!task.exisingSubscription && (mode === modes.move || mode === modes.resize)) {
      // Keep task within quote start and end dates
      let diff = original.duration * (1000 * 60 * 60 * 24);
      if (+task.end_date > +rightLimit) {
        task.end_date = new Date(rightLimit);
        if (mode === modes.move) {
          task.start_date = new Date(task.end_date - diff);
        }
      }
      if (+task.start_date < +leftLimit) {
        task.start_date = new Date(leftLimit);
        if (mode === modes.move) {
          task.end_date = new Date(+task.start_date + diff);
        }
      }
      // Multiple task resize
      if (mode === modes.resize) {
        gantt.eachSelectedTask((task_id) => {
          let t = gantt.getTask(task_id);
          if (!t.exisingSubscription) {
            t.start_date = task.start_date;
            t.end_date = task.end_date;
            gantt.updateTask(task_id);
          }
        });
      }
      // // Delete link when task is moved
      // task.$source.forEach((value, index, array) => {
      //   gantt.deleteLink(value);
      // });
      // task.$target.forEach((value, index, array) => {
      //   gantt.deleteLink(value);
      // });
    }
  });

  gantt.attachEvent("onBeforeTaskSelected", function (id) {
    var task = gantt.getTask(id);
    if (task.exisingSubscription) {
      return false;
    }
    return true;
  });
};

const unselectRowsOnEmptyClick = (gantt) => {
  gantt.attachEvent("onEmptyClick", function (e) {
    var domHelpers = gantt.utils.dom;
    if (!domHelpers.closest(e.target, "[" + gantt.config.link_attribute + "]")) {
      gantt.batchUpdate(function () {
        gantt.eachSelectedTask((task_id) => {
          if (gantt.isSelectedTask(task_id)) {
            gantt.toggleTaskSelection(task_id);
          }
        });
      });
    }
  });
};

const addTooltips = (gantt, cmp, ganttData) => {
  // Default tooltip for task override
  gantt.templates.tooltip_text = function (start, end, task) {
    return (
      "Product:<b> " +
      task.text +
      "</b><br/>Net Total: <b> " +
      (!isNaN(task.record.SBQQ__NetTotal__c)
        ? parseFloat(task.record.SBQQ__NetTotal__c).toLocaleString(undefined, { maximumFractionDigits: 2 })
        : 0) +
      " " +
      task.record.CurrencyIsoCode +
      "</b><br/>Total Discount: <b>" +
      task.record.SBQQ__TotalDiscountRate__c +
      "%" +
      "</b><br/>ARR: <b> " +
      (!isNaN(task.record.CPQ_QliARR__c)
        ? parseFloat(task.record.CPQ_QliARR__c).toLocaleString(undefined, { maximumFractionDigits: 2 })
        : 0) +
      " " +
      task.record.CurrencyIsoCode +
      "</b>"
    );
  };
  // Add tooltip for marker
  gantt.ext.tooltips.tooltipFor({
    selector: ".gantt_marker",
    html: function (event, domElement) {
      return domElement.title;
    },
    global: false
  });
};

const ganttLightBoxConfig = (gantt, cmp, ganttData) => {
  let lightBoxConfig = [
    { name: "product", height: 100, map_to: "product_desc", type: "template" },
    { name: "period", type: "time", map_to: "auto" }
  ];
  gantt.locale.labels.section_product = "Details";
  gantt.locale.labels.section_period = "Duration";
  gantt.config.lightbox.sections = lightBoxConfig;
  gantt.config.lightbox.project_sections = lightBoxConfig;
  gantt.config.lightbox_additional_height = cmp.theme === "material" ? 120 : 75;
  gantt.config.buttons_left = ["gantt_save_btn"];
  gantt.config.buttons_right = ["gantt_cancel_btn"]; // ["gantt_delete_btn"]
  gantt.attachEvent("onBeforeLightbox", function (id) {
    var task = gantt.getTask(id);
    task.product_desc =
      "Product: <b>" +
      task.text +
      "</b><br/>Net Total: <b>" +
      (!isNaN(task.record.SBQQ__NetTotal__c)
        ? parseFloat(task.record.SBQQ__NetTotal__c).toLocaleString(undefined, { maximumFractionDigits: 2 })
        : 0) +
      " " +
      task.record.CurrencyIsoCode +
      "</b><br/>Total Discount: <b>" +
      task.record.SBQQ__TotalDiscountRate__c +
      "%" +
      "</b><br/>ARR: <b>" +
      (!isNaN(task.record.CPQ_QliARR__c)
        ? parseFloat(task.record.CPQ_QliARR__c).toLocaleString(undefined, { maximumFractionDigits: 2 })
        : 0) +
      " " +
      task.record.CurrencyIsoCode +
      "</b>";
    return true;
  });

  gantt.attachEvent("onLightboxSave", function (id, task, is_new) {
    let leftLimit = timezoneDate(ganttData.quote.SBQQ__StartDate__c),
      rightLimit = timezoneDate(ganttData.quote.SBQQ__EndDate__c);
    if (+task.end_date > +rightLimit) {
      task.end_date = new Date(rightLimit);
    }
    if (+task.start_date < +leftLimit) {
      task.start_date = new Date(leftLimit);
    }
    return true;
  });
};

const linkCreationValidate = (gantt, cmp, ganttData) => {
  gantt.attachEvent("onBeforeLinkAdd", function (id, link) {
    if (link.type !== "0") {
      cmp.showToast(
        "Error",
        "Link must start from the end of a Source product and must end at the start of a Target product.",
        "error"
      );
      return false;
    }
    // else if (+gantt.getTask(link.source).end_date > +gantt.getTask(link.target).start_date) {
    //   cmp.showToast("Error", "Target product start date must be after the Source product end date.", "error");
    //   return false;
    // }
    return true;
  });
};

// const autoSchedulingTasks = (gantt, cmp, ganttData) => {
//   gantt.attachEvent("onAfterTaskAutoSchedule", (task, start, link, predecessor) => {
//     let rightLimit = timezoneDate(ganttData.quote.SBQQ__EndDate__c);
//     if (task.end_date > rightLimit) {
//       task.end_date = rightLimit;
//     }
//     gantt.updateTask(task.id);
//   });
// };

const ganttLinkSettings = (gantt, cmp, ganttData) => {
  gantt.templates.link_class = (link) => {
    var types = gantt.config.links;
    switch (link.type) {
      case types.finish_to_start:
        return "finish_to_start";
      case types.start_to_start:
        return "start_to_start";
      case types.finish_to_finish:
        return "finish_to_finish";
    }
    return "";
  };
  gantt.attachEvent("onBeforeLinkAdd", (id, link) => {
    // auto scheduling lag
    link.lag = 1;
    return true;
  });
};

const setZoomLevel = (gantt, cmp, ganttData) => {
  let leftLimit = timezoneDate(ganttData.quote.SBQQ__StartDate__c),
    rightLimit = timezoneDate(ganttData.quote.SBQQ__EndDate__c);
  let diffInDays = (rightLimit - leftLimit) / (24 * 60 * 60 * 1000);
  gantt.ext.zoom.setLevel("year"); // Default zoom level
  if (diffInDays > 1095) {
    gantt.ext.zoom.setLevel("year-small");
  } else if (diffInDays < 90) {
    gantt.ext.zoom.setLevel("month");
  }
  gantt.showDate(timezoneDate(ganttData.quote.SBQQ__StartDate__c)); // drag to quote start
};

const rowOrderHandling = (gantt, cmp, ganttData) => {
  gantt.attachEvent("onRowDragStart", (id, target, e) => {
    return cmp.linkMode;
  });

  gantt.attachEvent("onRowDragEnd", (id, target) => {
    gantt.eachTask((task) => {
      task.timeline_order = gantt.getGlobalTaskIndex(task.id);
    });
  });
};

export default ganttConfigsPostData;