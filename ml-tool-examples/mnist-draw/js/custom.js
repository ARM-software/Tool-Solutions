// Canvas setup
var canvas = new fabric.Canvas('canvas');
canvas.isDrawingMode = true;
canvas.freeDrawingBrush.width = 20;
canvas.freeDrawingBrush.color = "#000000";
canvas.backgroundColor = "#ffffff";
canvas.renderAll();


// Clear button callback
$("#clear-canvas").click(function(){ 
  canvas.clear(); 
  canvas.backgroundColor = "#ffffff";
  canvas.renderAll();
  updateChart(zeros);
  $("#status").removeClass();
});


// Predict button callback
$("#predict").click(function(){  

  // Change status indicator
  $("#status").removeClass().toggleClass("fa fa-spinner fa-spin");

  // Get canvas contents as url
  var fac = (1.) / 13.; 
  var url = canvas.toDataURLWithMultiplier('png', fac);

  // Post url to python script
  var jq = $.post('cgi-bin/mnist.py', url)
    .done(function (json) {
      if (json.result) {
        $("#status").removeClass().toggleClass("fa fa-check");
        $('#svg-chart').show();
        updateChart(json.data);
      } else {
         $("#status").removeClass().toggleClass("fa fa-exclamation-triangle");
         console.log('Script Error: ' + json.error)
      }
    })
    .fail(function (xhr, textStatus, error) {
      $("#status").removeClass().toggleClass("fa fa-exclamation-triangle");
      console.log("POST Error: " + xhr.responseText + ", " + textStatus + ", " + error);
    }
  );

});

// Iniitialize d3 bar chart
$('#svg-chart').hide();
var labels = ['0','1','2','3','4','5','6','7','8','9'];
var zeros = [0,0,0,0,0,0,0,0,0,0,0];

var margin = {top: 0, right: 0, bottom: 20, left: 0},
    width = 360 - margin.left - margin.right,
    height = 180 - margin.top - margin.bottom;

var svg = d3.select("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", 
          "translate(" + margin.left + "," + margin.top + ")");

var x = d3.scale.ordinal()
    .rangeRoundBands([0, width], .1)
    .domain(labels);
    
var y = d3.scale.linear()
          .range([height, 0])
          .domain([0,1]);  

var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    .tickSize(0);

svg.selectAll(".bar")
    .data(zeros)
  .enter().append("rect")
    .attr("class", "bar")
    .attr("x", function(d, i) { return x(i); })
    .attr("width", x.rangeBand())
    .attr("y", function(d) { return y(d); })
    .attr("height", function(d) { return height - y(d); });

svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis);

// Update chart data
function updateChart(data) {
  d3.selectAll("rect")
    .data(data)
    .transition()
    .duration(500)
    .attr("y", function(d) { return y(d); })
    .attr("height", function(d) { return height - y(d); });
}
      