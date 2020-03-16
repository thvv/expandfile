/* Javascript Timeline Chart
 *
 * THVV 2017-03-01 v1
 * THVV 2017-06-22 v1.1 deal with HiDPI canvases
 *
 * Invoke this with a CANVAS tag
 * <canvas id="canvas2" width="550" height="200" title="Multics History Timeline" class="tline">
 *  %[*callv,imgdiv,="mulimg/m-timeline.png",="",="Multics timeline 1965-2014",="",="tline",=""]%
 * </canvas>
 *
 * Inside the CANVAS tag, put an alternate representation in case the browser cannot run Javascript.
 *
 * Input is in a TABLE.
 * .. the table has rows defined by TR tags, defining vertical labels
 * .. each row has columns
 * .... TYPE - one of 'data', 'axis', 'back'
 * .... POSITION - horizontal position on timeline
 * .... LSTYLE - line style, e.g. "red"
 * .... OFFSET - vertical offset
 * .... TEXT - text of the data item; vertical bar will cause a newline
 * .... TSTYLE - text style, e.g. "bold italic 10pt serif" or ""
 * Output is a timeline chart.
 * The CAPTION tag is the table title.
 * args to the Javascript function are
 *  datatableid ID tag for the data table
 *  canvasid    ID tag for the canvas
 *  bgcolor     optional background color as hex, rgb(), or color name
 *  timelinecolor    color for the timeline rect
 * 
 * The TABLE can be a separate table with display: none.
 * In some applications the table is the alternate representation and goes inside the CANVAS.
*/
// Copyright 2017 Tom Van Vleck
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

function timelinecanvas(datatableid, canvasid, bgcolor, timelinecolor) {
    var background_color = 'white';
    var timeline_color = 'red';
    // check that args are supplied
    if (typeof bgcolor !== 'undefined') {
        background_color = bgcolor;
    }
    if (typeof timelinecolor !== 'undefined') {
        timeline_color = timelinecolor;
    }
    // check source data table and canvas tag
    var data_table = document.getElementById(datatableid);
    if (typeof data_table === 'undefined') {
        return;
    }
    var canvas = document.getElementById(canvasid);
    if (typeof canvas === 'undefined') {
        return;
    }
    // exit if canvas is not supported
    if (typeof canvas.getContext === 'undefined') {
        return;
    }
    // get canvas context
    var context = canvas.getContext('2d');

    // deal with HiDPI
    var factor = window.devicePixelRatio || 1;
    var cw = canvas.width;
    var ch = canvas.height;
    canvas.width = cw * factor;
    canvas.height = ch * factor;
    canvas.style.width = cw + "px";
    canvas.style.height = ch + "px";
    context.scale(factor, factor);

    data_table.style.display = 'none'; // bug in MSIE 9, shows content of CANVAS tag

    // constants
    var TITLE_STY = '12pt sans-serif';
    var DFT_BACK_STY = 'bold 7pt sans-serif';
    var DFT_DATE_STY = 'bold 9pt sans-serif';
    var DFT_EVENT_TXT_STY = '9pt serif';
    var DFT_EVENT_COLOR = 'gray';

    var LEFT_MARGIN = 15; // inset timeline on each side so the label won't be cut off
    var RIGHT_MARGIN = 15;
    var TIMELINE_HEIGHT = 5;
    var EVENT_WIDTH = 3;
    var TITLE_HEIGHT = 20;
    var EVENT_TEXT_GAP = 5; // space between bottom of timeline and text block
    var TEXT_LINE_HEIGHT = 11; // height of a line of text
    
    var roomforaxis = TITLE_HEIGHT+2, roomfortitle = 0, roomforsubtitle = 0, roomfornegativeevents = 0;
    var timeline_room = cw - LEFT_MARGIN - RIGHT_MARGIN; // leave room for text labels to spread
    
    // if the table has CAPTION elements
    var charttitle = '', chartsubtitle = '';
    var captions = data_table.getElementsByTagName('caption'); // all captions
    if (typeof captions === 'undefined') {
	// no caption
    } else {
	if (captions.length > 0) {
	    charttitle = captions[0].innerHTML;
	    roomfortitle += TITLE_HEIGHT; // push everything down so the title will fit
	}
	for (var j=1; j < captions.length; j++) { // concat all the other captions into a footer
	    chartsubtitle += captions[j].innerHTML + " ";
	    roomforsubtitle = TITLE_HEIGHT; // not doing this right now
	}
    }

    var tds, data_year = [], data_event_lth = [], data_event_txt = [], data_txt_style = [], data_line_style = [];
    var axis_year = [], axis_txt_style = [];
    var back_fyear = [], back_lyear = [], back_color = [], back_text = [], back_style = [];
    var value = 0, opcode = '', val;
    var smallestlinelength = 0;

    var TD_TYP_INDEX = 0; // column 0 TD is type
    var TD_POS_INDEX = 1; // column 1 TD contains the horizontal pos
    var TD_LST_INDEX = 2; // column 2 TD is event color
    var TD_OFF_INDEX = 3; // column 3 TD contains the vertical pos
    var TD_TXT_INDEX = 4; // column 4 TD contains descriptive text
    var TD_STY_INDEX = 5; // column 5 TD is a text style

    // copy the HTML table rows into data*[] and axis*[]
    var trs = data_table.getElementsByTagName('tr'); // all TRs
    for (var i=0; i < trs.length; i++) {
        tds = trs[i].getElementsByTagName('td'); // all TDs
        if (tds.length === 0) continue; //  no TDs in this TR, skip
	opcode = tds[TD_TYP_INDEX].innerHTML;
	if (opcode == 'data') {
	    // -- 1
            data_year[data_year.length] = parseInt(tds[TD_POS_INDEX].innerHTML); // this is a year
	    // -- 2
	    if (typeof(tds[TD_LST_INDEX]) == 'undefined') {
		data_line_style[data_line_style.length] = "";
	    } else {
		data_line_style[data_line_style.length] = tds[TD_LST_INDEX].innerHTML; // line style
	    }
	    // -- 3
            val = parseInt(tds[TD_OFF_INDEX].innerHTML); // coded vertical offset, see eventheight()
	    if (val < smallestlinelength) {
		smallestlinelength = val;
	    }
	    data_event_lth[data_event_lth.length] = val;
	    // -- 4
	    if (typeof(tds[TD_TXT_INDEX]) == 'undefined') {
		data_event_txt[data_event_txt.length] = "";
	    } else {
		data_event_txt[data_event_txt.length] = tds[TD_TXT_INDEX].innerHTML; // text of event
	    }
	    // -- 5
	    val = tds[TD_STY_INDEX].innerHTML; // style of event text, or blank=default
	    if (val == '') {
		val = DFT_EVENT_TXT_STY;
	    }
	    data_txt_style[data_txt_style.length] = val;
	} else if (opcode == 'axis') {
	    // -- 1
	    axis_year[axis_year.length] = parseInt(tds[TD_POS_INDEX].innerHTML); // this is a year
	    // -- 5 is optional style for the date
	    if (typeof(tds[TD_STY_INDEX]) == 'undefined') { // style of axis item
		axis_txt_style[axis_txt_style.length] = DFT_DATE_STY;
	    } else if (tds[TD_STY_INDEX] == '') {
		axis_txt_style[axis_txt_style.length] = DFT_DATE_STY;
	    } else {
		axis_txt_style[axis_txt_style.length] = tds[TD_STY_INDEX].innerHTML; // this is a style for the date, blank=default
	    } 
	} else if (opcode == 'back') { // background block
	    // -- 1 begin year
	    back_fyear[back_fyear.length] = parseInt(tds[TD_POS_INDEX].innerHTML); // this is a year
	    // -- 2 end year
	    back_lyear[back_lyear.length] = parseInt(tds[TD_OFF_INDEX].innerHTML); // this is a year
	    // -- 3 color
	    back_color[back_color.length] = tds[TD_LST_INDEX].innerHTML; // background color
	    // -- 4 background label
	    back_text[back_text.length] = tds[TD_TXT_INDEX].innerHTML; // label
	    // -- 5 background label style
	    back_style[back_style.length] = tds[TD_STY_INDEX].innerHTML; // text style
	}
    } // for

    // general layout
    var minyr = 1960; // default minimum year
    var maxyr = 2020;
    // if there were axis values, compute the min and max
    if (axis_year.length > 0) {
	// .. assume they are in order, should sort axis_year and axis_txt_style
	minyr = axis_year[0];
	maxyr = axis_year[axis_year.length-1];
    }
    if (smallestlinelength < 0) { // if we saw any negative line sizes, they go above the timeline
	roomfornegativeevents = 20 * (-smallestlinelength);
    }

    // ----------------------------------------------------------------

    // fill the background
    context.fillStyle = background_color;
    context.fillRect(0, 0, cw, ch);

    // draw the background blocks
    context.fillStyle = '#000'; // black text
    context.textBaseline = 'top';
    context.textAlign = 'left';
    for (var itemx in back_fyear) { // loop for background blocks
	var xx = xscale(back_fyear[itemx], timeline_room, minyr, maxyr)+LEFT_MARGIN;
	var rect = [xx, 0, xscale(back_lyear[itemx], timeline_room, minyr, maxyr)+LEFT_MARGIN, ch];
	drawbackbox(context, rect, back_color[itemx]);
	context.fillStyle = '#000'; // black text
	if (back_style[itemx] != "") {
	    context.font = back_style[itemx];
	} else {
	    context.font = DFT_BACK_STY;
	}
	//alert("back "+back_text[itemx]+" "+xx);
    	context.fillText(back_text[itemx], xx + 5, ch-10);
    } // loop for background blocks
    
    // draw the horizontal timeline
    var timeline = [LEFT_MARGIN, roomfortitle+roomforaxis+roomfornegativeevents, timeline_room, TIMELINE_HEIGHT+roomfortitle+roomforaxis+roomfornegativeevents]; // x, y of start, x, y of end
    drawtimeline(context, timeline, timeline_color);

    // draw the vertical events
    var bw = 10;
    for (var itemx in data_year) { // loop for items, drawing a event
	var event_color = DFT_EVENT_COLOR;
	//alert(" year="+data_year[itemx]+" lth="+data_event_lth[itemx]+" style="+data_line_style[itemx]+" sty="+data_txt_style[itemx]+" txt="+data_event_txt[itemx]);
	if (data_line_style[itemx] != "") { // if there is a line style
	    event_color = data_line_style[itemx];
	} // if there is a line style
	var x = xscale(data_year[itemx], timeline_room, minyr, maxyr)+LEFT_MARGIN; // compute left side of event by scaling year
	var y;
	if (data_event_lth[itemx] < 0) {
	    // line down from top
	    y = roomfortitle+roomforaxis+roomfornegativeevents; // bottom of event ends at top of timeline
	    event = [x, y, x+EVENT_WIDTH, y+eventheight(data_event_lth[itemx])];
	    draw_falling_event(context, event, event_color);
	} else {
	    y = roomfortitle+roomforaxis+roomfornegativeevents+TIMELINE_HEIGHT; // top of event ends at bottom of timeline
	    event = [x, y, x+EVENT_WIDTH, y+eventheight(data_event_lth[itemx])];
	    draw_rising_event(context, event, event_color);
	}
    } // loop for items

    // draw the axis labels
    var FUDGE_AXIS_TOP = 10; // room for the axis text above the timeline
    context.fillStyle = '#000'; // black text
    context.textBaseline = 'top';
    context.textAlign = 'center';
    for (var itemx in axis_year) { // loop for axis labels, which have -1 as the coded y-size
	context.font = axis_txt_style[itemx];
    	context.fillText(""+axis_year[itemx],
			 xscale(axis_year[itemx], timeline_room, minyr, maxyr)+LEFT_MARGIN, // ??? last date comes out too far to the right
			 yscale(-1, ch, roomfortitle+roomfornegativeevents+FUDGE_AXIS_TOP));
    } // loop for axis labels

    // draw the titles below each event
    context.fillStyle = '#000'; // black text
    context.textBaseline = 'top';
    context.textAlign = 'center';
    for (var itemx in data_event_txt) { // loop for event labels
	context.font = data_txt_style[itemx];
	if (data_event_lth[itemx] >= 0) {
	    var w = data_event_txt[itemx].split("|"); // fillText does not interpret newlines, do by hand
	    for (var ln = 0; ln < w.length; ln++) {
    		context.fillText(w[ln],
				 xscale(data_year[itemx], timeline_room, minyr, maxyr)+LEFT_MARGIN,
				 yscale(data_event_lth[itemx], ch, roomfortitle+roomforaxis+roomfornegativeevents+TIMELINE_HEIGHT)
				 +EVENT_TEXT_GAP+(ln*TEXT_LINE_HEIGHT));
	    } // for
	} else {
	    // falling line
	    var w = data_event_txt[itemx].split("|"); // fillText does not interpret newlines, do by hand
	    for (var ln = 0; ln < w.length; ln++) {
    		context.fillText(w[w.length-ln-1],
				 xscale(data_year[itemx], timeline_room, minyr, maxyr)+LEFT_MARGIN,
				 yscale(data_event_lth[itemx], ch, roomfortitle+roomforaxis+roomfornegativeevents+TIMELINE_HEIGHT)
				 -EVENT_TEXT_GAP-(ln*TEXT_LINE_HEIGHT)-10);
	    } // for
	}
    } // loop for event labels

    // draw chart title
    var TITLE_TOP_PAD = 5;
    var TITLE_LFT_PAD = 5;
    if (charttitle != '') {
	context.font = TITLE_STY;
	context.fillStyle = '#000'; // black text
	context.textBaseline = 'top';
	context.textAlign = 'left';
    	context.fillText(charttitle, TITLE_TOP_PAD, TITLE_LFT_PAD);
    }
} // timelinecanvas

// ================================================================

function xscale(bvyear, bvboxwidth, bvminyr, bvmaxyr) {
    var pixels_per_year = bvboxwidth / (bvmaxyr - bvminyr);
    return (bvyear-bvminyr) * pixels_per_year;
} // xscale

function eventheight(x) {
    if (x == 0) {return 10;}
    else if (x == -4) {return -70;}
    else if (x == -3) {return -50;}
    else if (x == -2) {return -20;}
    else if (x == -1) {return 0;} // axis labels
    else if (x == 1) {return 20;}
    else if (x == 2) {return 40;}
    else if (x == 3) {return 60;}
    else if (x == 4) {return 80;}
    else if (x == 5) {return 110;}
    else {return 140;}
} // eventheight

function yscale(something, bvcanvasheight, toppadding) {
    // scaling a event
    // "something" is a coded y offset
    var x = eventheight(something);
    //alert("yscale "+something+" "+toppadding);
    return x+toppadding;
} // yscale

function drawbackbox(bvcontext, bvrect, bvrectcolor) {
    // draw the rect
    bvcontext.beginPath();
    bvcontext.moveTo(bvrect[0], bvrect[1]);
    bvcontext.lineTo(bvrect[2], bvrect[1]);
    bvcontext.lineTo(bvrect[2], bvrect[3]);
    bvcontext.lineTo(bvrect[0], bvrect[3]);
    bvcontext.lineTo(bvrect[0], bvrect[1]);
    bvcontext.closePath();
    bvcontext.fillStyle = bvrectcolor;    // color
    bvcontext.fill();
} // drawbackbox

function drawtimeline(bvcontext, bvrect, bvrectcolor) {
    // draw the rect
    bvcontext.beginPath();
    bvcontext.moveTo(bvrect[0], bvrect[1]);
    bvcontext.lineTo(bvrect[2], bvrect[1]);
    bvcontext.lineTo(bvrect[2], bvrect[3]);
    bvcontext.lineTo(bvrect[0], bvrect[3]);
    bvcontext.lineTo(bvrect[0], bvrect[1]);
    bvcontext.closePath();
    bvcontext.fillStyle = bvrectcolor;    // color
    bvcontext.fill();
    // draw the arrowhead at the right
    var mid = (bvrect[1]+bvrect[3])/2;
    var AHH = 5;		     // half the arrowhead height
    var AHL = 10;		     // arrowhead length
    bvcontext.moveTo(bvrect[2], mid); // center of right end
    bvcontext.lineTo(bvrect[2], mid-AHH);
    bvcontext.lineTo(bvrect[2]+AHL, mid);
    bvcontext.lineTo(bvrect[2], mid+AHH);
    bvcontext.lineTo(bvrect[2], mid);
    bvcontext.closePath();
    bvcontext.fill();
} // drawtimeline

function draw_rising_event(bvcontext, bvrect, bvrectcolor) {
    var AHH = 5;		     // half the arrowhead height
    var AHL = 10;		     // arrowhead length
    // draw the rect
    bvcontext.beginPath();
    bvcontext.moveTo(bvrect[0], bvrect[1]+AHL); // shorten the rect a little
    bvcontext.lineTo(bvrect[2], bvrect[1]+AHL);
    bvcontext.lineTo(bvrect[2], bvrect[3]);
    bvcontext.lineTo(bvrect[0], bvrect[3]);
    bvcontext.lineTo(bvrect[0], bvrect[1]+AHL);
    bvcontext.closePath();
    bvcontext.fillStyle = bvrectcolor;    // color
    bvcontext.fill();
    // draw the arrowhead at the top
    var mid = (bvrect[0]+bvrect[2])/2;
    bvcontext.moveTo(mid, bvrect[1]+AHL); // center of top
    bvcontext.lineTo(mid-AHH, bvrect[1]+AHL);
    bvcontext.lineTo(mid, bvrect[1]);
    bvcontext.lineTo(mid+AHH, bvrect[1]+AHL);
    bvcontext.lineTo(mid, bvrect[1]+AHL);
    bvcontext.closePath();
    bvcontext.fill();
} // draw_rising_event

function draw_falling_event(bvcontext, bvrect, bvrectcolor) {
    var AHH = 5;		     // half the arrowhead height
    var AHL = 12;		     // arrowhead length
    // draw the rect
    bvcontext.beginPath();
    bvcontext.moveTo(bvrect[0], bvrect[1]-AHL); // shorten the rect a little
    bvcontext.lineTo(bvrect[2], bvrect[1]-AHL);
    bvcontext.lineTo(bvrect[2], bvrect[3]);
    bvcontext.lineTo(bvrect[0], bvrect[3]);
    bvcontext.lineTo(bvrect[0], bvrect[1]-AHL);
    bvcontext.closePath();
    bvcontext.fillStyle = bvrectcolor;    // color
    bvcontext.fill();
    // draw the arrowhead at the bottom
    var mid = (bvrect[0]+bvrect[2])/2;	 // x coord of middle of rect
    bvcontext.moveTo(mid, bvrect[1]-AHL); // center of bottom
    bvcontext.lineTo(mid-AHH, bvrect[1]-AHL); // line to the left
    bvcontext.lineTo(mid, bvrect[1]);	     // line down to the point
    bvcontext.lineTo(mid+AHH, bvrect[1]-AHL); // line to the right
    bvcontext.lineTo(mid, bvrect[1]-AHL);     // back to start
    bvcontext.closePath();
    bvcontext.fill();
} // draw_falling_event
