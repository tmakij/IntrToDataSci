"use strict";

var ASEMAT = [
    {
        Asema: "Kaisaniemi",
        x: 320,
        y: 450,
    },
    {
        Asema: "Eteläesplanadi",
        x: 330,
        y: 510,
    },
    {
        Asema: "Baana",
        x: 260,
        y: 510,
    },
    {
        Asema: "Heperian puisto",
        x: 270,
        y: 450,
    },
];

/*var ASEMAT = [
Lauttasaaren silta eteläpuoli; 25 494 110, 42; 6 672 061, 62
Lauttasaaren silta pohjoispuoli; 25 494 453, 04; 6 672 209, 73
Kulosaaren silta et.sisältää myös pohjoispuolen; 25 499 610, 15; 6 674 731, 18
Kuusisaarentie; 25 492 931, 19; 6 674 956, 03
Munkkiniemi silta pohjoispuoli; 25 493 792, 78; 6 675 914, 28
Munkkiniemen silta eteläpuoli; 25 493 760, 23; 6 675 847, 29
Heperian puisto (Ooppera); 25 496 167, 91; 6 674 249, 37
Pitkäsilta länsipuoli; 25 497 188, 98; 6 673 692, 00
Pitkäsilta itäpuoli; 25 497 255, 67; 6 673 768, 13
Merikannontie; 25 495 211, 14; 6 673 759, 38
Kulosaaren silta po.suljettu, tietyö; 25 499 598, 49; 6 674 835, 97
Ratapihantie; 25 496 284, 75; 6 676 427, 37
Huopalahti(asema); 25 494 615, 55; 6 678 081, 68
]*/

var aaa = "fcb38635-055b-44c0-8055-2bb505190dc1";
var FMI_ADDRESS = "http://data.fmi.fi/fmi-apikey/";
var WFS_FEATURES = "/wfs?request=getFeature&storedquery_id=fmi::observations::weather::simple&place=kumpula&";

function main() {

    document.getElementById("cform").addEventListener("submit", function (evt) {
        evt.preventDefault();
        var xmlreq = new XMLHttpRequest();
        xmlreq.addEventListener("load", function () {
            console.log(this.responseXML);
            var featNode = this.responseXML.childNodes[0];
            var temperature = 0;
            var windspeed = 0;
            for (var i = 0; i < featNode.childNodes.length; i++) {
                var child = featNode.childNodes[i];
                if (child.nodeName === "wfs:member") {
                    var bsWfsEl = child.childNodes[1];
                    for (var k = 0; k < bsWfsEl.childNodes.length; k++) {
                        var elem = bsWfsEl.childNodes[k];
                        if (elem.nodeName === "BsWfs:ParameterName") {
                            var paramVal = bsWfsEl.childNodes[k + 2].textContent;
                            var value = Number(paramVal);
                            console.log(elem.textContent, paramVal, value);
                            switch (elem.textContent) {
                                case "t2m":
                                    temperature = value;
                                case "ws_10min":
                                    windspeed = value;
                            }
                            break;
                        }
                    }
                }
            }
            console.log(temperature, windspeed);
        });
        xmlreq.addEventListener("error", function (event) {
            console.error("Error");
            console.log(event);
        });

        var start = new Date();
        var end = "endtime=" + start.toISOString() + "&";

        start.setMinutes(start.getMinutes() - 15);
        var start = "starttime=" + start.toISOString() + "&";

        xmlreq.open("GET", FMI_ADDRESS + aaa + WFS_FEATURES + start + end);
        xmlreq.send();
    }, true);;

    var heatmap = h337.create({
        container: document.getElementById("mapcontainer"),
    });

    var points = [];
    var max = 10;
    for (var i = 0; i < ASEMAT.length; i++) {
        var asema = ASEMAT[i];
        points.push({
            x: asema.x,
            y: asema.y,
            value: 10,//Math.random() * 10,
        });
    }
    /*var max = 0;
    var width = 840;
    var height = 400;
    var len = 200;

    while (len--) {
        var val = Math.floor(Math.random() * 100);
        max = Math.max(max, val);
        var point = {
            x: Math.floor(Math.random() * width),
            y: Math.floor(Math.random() * height),
            value: val
        };
        points.push(point);
    }*/
    // heatmap data format
    var data = {
        max: max,
        data: points
    };
    // if you have a set of datapoints always use setData instead of addData
    // for data initialization
    heatmap.setData(data);

    /*heatmap.setData({
        max: 5,
        data: [{ x: 20, y: 15, value: 544 }, { x: 100, y: 150, value: 0 }],
    });*/
}

window.onload = main;

/**
 *     <script src="https://cdnjs.cloudflare.com/ajax/libs/gmaps.js/0.4.25/gmaps.min.js"></script>
    <script src="g_heatmap.js"></script>

    
 */
