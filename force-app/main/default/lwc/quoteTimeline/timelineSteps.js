const timelineSteps = (gantt) => {
  return {
    levels: [
      {
        name: "day",
        scale_height: 27,
        min_column_width: 80,
        scales: [{ unit: "day", step: 1, format: "%d %M, %Y" }]
      },
      {
        name: "week",
        scale_height: 50,
        min_column_width: 50,
        scales: [
          {
            unit: "week",
            step: 1,
            format: function (date) {
              var dateToStr = gantt.date.date_to_str("%d %M %Y");
              var endDate = gantt.date.add(date, 6, "day");
              var weekNum = gantt.date.date_to_str("%W")(date);
              return "#" + weekNum + ", " + dateToStr(date) + " - " + dateToStr(endDate);
            }
          },
          { unit: "day", step: 1, format: "%j %D" }
        ]
      },
      {
        name: "month",
        scale_height: 50,
        min_column_width: 80,
        scales: [{ unit: "month", format: "%F, %Y" }]
      },
      {
        name: "year",
        scale_height: 50,
        min_column_width: 400,
        scales: [{ unit: "year", step: 1, format: "%Y" }]
      },
      {
        name: "year-small",
        scale_height: 50,
        min_column_width: 100,
        scales: [{ unit: "year", step: 1, format: "%Y" }]
      }
    ]
  };
};

export default timelineSteps;