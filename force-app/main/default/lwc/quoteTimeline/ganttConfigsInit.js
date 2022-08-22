/* eslint-disable no-unused-vars */
/* eslint-disable no-use-before-define */
import timelineSteps from "./timelineSteps";

const ganttConfigsInit = (gantt) => {
  gantt.plugins({
    marker: true,
    multiselect: true,
    overlay: true,
    tooltip: true,
    undo: true
    // auto_scheduling: true
  });

  gantt.config.drag_progress = false;
  gantt.config.show_progress = true;
  gantt.config.sort = true;
  gantt.config.server_utc = true;
  gantt.config.order_branch = "marker";
  // gantt.config.auto_scheduling = true;
  // gantt.config.auto_scheduling_strict = true;
  // gantt.config.auto_scheduling_compatibility = true;
  gantt.config.bar_height = 30;
  gantt.config.row_height = 45;
  gantt.config.drag_project = true;
  gantt.config.multiselect_one_level = true;
  gantt.config.date_grid = "%j %M %Y";
  gantt.config.round_dnd_dates = false;
  gantt.config.time_step = 1440;
  gantt.config.open_tree_initially = true;
  gantt.config.columns = [
    { name: "text", label: "Products", tree: true, width: "180", resize: true },
    { name: "start_date", label: "Start Date", width: "90", align: "center", resize: true },
    { name: "end_date", label: "End Date", width: "90", align: "center", resize: true },
    { name: "quantity", label: "Qty", width: "50", align: "center", resize: true }
  ];

  gantt.templates.parse_date = (date) => new Date(date);
  gantt.templates.format_date = (date) => gantt.date.date_to_str(gantt.config.date_grid)(date);

  gantt.ext.zoom.init(timelineSteps(gantt));

  tooltipViewport(gantt);
  ganttCreateDataProcessor(gantt);
};

const ganttCreateDataProcessor = (gantt) => {
  gantt.createDataProcessor({
    task: {
      create: function (data) {},
      update: function (data, id) {
        return new Promise((resolve, reject) => {
          resolve({});
        });
      },
      delete: function (id) {
        return new Promise((resolve, reject) => {
          resolve({});
        });
      }
    },
    link: {
      create: function (data) {
        return new Promise((resolve, reject) => {
          resolve({});
        });
      },
      update: function (data, id) {
        return new Promise((resolve, reject) => {
          resolve({});
        });
      },
      delete: function (id) {
        return new Promise((resolve, reject) => {
          resolve({});
        });
      }
    }
  });
};

const tooltipViewport = (gantt) => {
  // Make tooltip work with lightning
  gantt.attachEvent("onGanttReady", function () {
    var tooltips = gantt.ext.tooltips;
    tooltips.tooltip.setViewport(gantt.$task_data);
  });
};

export default ganttConfigsInit;