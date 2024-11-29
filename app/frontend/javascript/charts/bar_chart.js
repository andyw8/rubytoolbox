import Chart from "chart.js"

export default function(selector, labels, values) {
  var ctx = document.querySelector(selector)
                    .getContext('2d');

  new Chart(ctx, {
    type: "bar",
    data: {
      labels: labels,
      datasets: [
        {
          data: values,
          fill: true,
          borderWidth: 0,
          backgroundColor: "rgba(166,20,20,1)"
        }
      ]
    },
    options: {
      animation: false,
      legend: {
        display: false
      },
      responsive: true,
      maintainAspectRatio: false,
      tooltips: {
        mode: "index",
        intersect: false,
        axis: "x"
      },
      scales: {
        xAxes: [
          {
            gridLines : {
              display : false
            }
          }
        ],
        yAxes: [
          {
            ticks: {
              beginAtZero: true,
            }
          }
        ]
      }
    }
  });
}
