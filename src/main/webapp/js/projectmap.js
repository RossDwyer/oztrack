
var map;
var allAnimalTracksLayer;
var pointsLayer;
var projection900913 = new OpenLayers.Projection("EPSG:900913");
var projection4326 =  new OpenLayers.Projection("EPSG:4326");
var colours = [
        '#8DD3C7',
        '#FFFFB3',
        '#BEBADA',
        '#FB8072',
        '#80B1D3',
        '#FDB462',
        '#B3DE69',
        '#FCCDE5',
        '#D9D9D9',
        '#BC80BD',
        '#CCEBC5',
        '#FFED6F'
    ];


var polygonOnStyle;
var polygonOffStyle;
var polygonStyleMap;
var lineOnStyle;
var lineOffStyle;
var lineStyleMap;
var startEndPointsOnStyle;
var startEndPointsOffStyle;
var startEndPointsStyleMap;



function initializeProjectMap() {

    var projectId = $('#projectId').val();
    var mapOptions = {
       maxExtent: new OpenLayers.Bounds(
            -128 * 156543.0339,
            -128 * 156543.0339,
             128 * 156543.0339,
             128 * 156543.0339),
       maxResolution: 156543.0339,
       units: 'm',
       projection: projection900913,
       displayProjection: projection4326
    };

    map = new OpenLayers.Map('projectMap',mapOptions);
    // info on the map
    map.addControl(new OpenLayers.Control.MousePosition());
    map.addControl(new OpenLayers.Control.Scale());
    map.addControl(new OpenLayers.Control.ScaleLine());
    // controls to manipulate
    var navToolbar = new OpenLayers.Control.NavToolbar();
    map.addControl(navToolbar);
    var layerSwitcher = new OpenLayers.Control.LayerSwitcher();
    //map.addControl(new OpenLayers.Control.Measure());
   // layerSwitcher.div = OpenLayers.Util.getElement('customLayerSwitcher');
   // layerSwitcher.roundedCorner = false;
    map.addControl(layerSwitcher);
    map.addControl(new OpenLayers.Control.LoadingPanel());
    
    var gphy = new OpenLayers.Layer.Google(
                "Google Physical",
                {type: google.maps.MapTypeId.TERRAIN}
    );
    var gsat = new OpenLayers.Layer.Google(
                "Google Satellite",
                {type: google.maps.MapTypeId.SATELLITE}
    );
    
    var panel = new OpenLayers.Control.Panel();
    //panel.div = OpenLayers.Util.getElement('mapControlPanel');
    panel.addControls([
        new OpenLayers.Control.Button({
            displayClass: "helpButton", trigger: function() {alert('help');}, title: 'Help'
        }),
        new OpenLayers.Control.Button({
        	displayClass: "zoomButton", trigger: function() {map.zoomToExtent(allAnimalTracksLayer.getDataExtent(),false);}, title: 'Zoom to Data Extent'
        })
    ]);
    map.addControl(panel);
    
    initStyles();

    allAnimalTracksLayer = new OpenLayers.Layer.Vector(
        "All Trajectories",
        {
        projection: projection4326,
        protocol: new OpenLayers.Protocol.WFS.v1_1_0({
           url:  "mapQueryWFS?projectId=" + projectId + "&queryType=ALL_LINES",
           featureType: "Track",
           featureNS: "http://localhost:8080/",
           geometryName: "startPoint"
           }),
        strategies: [new OpenLayers.Strategy.Fixed()],
        styleMap:lineStyleMap, 
         eventListeners: {
            loadend: function (e) {
        		map.zoomToExtent(allAnimalTracksLayer.getDataExtent(),false);
        		updateAnimalInfo(allAnimalTracksLayer);
            	if (!pointsLayer) {createPointsLayer();}
        	}
         }
        });
    
    map.addLayers([gsat,gphy,allAnimalTracksLayer]);
    map.setCenter(new OpenLayers.LonLat(133,-28).transform(projection4326,projection900913), 4);
    
    reportProjectionDescr();
}

function initStyles() {
	
    var wfsStyleContext = {
            getColour: function(feature) {
                var c = feature.attributes.animalId%colours.length;
                return colours[c];
            } };
    
	var lineOnTemplate = {
			strokeColor: "${getColour}",
			strokeWidth: 1,
			strokeOpacity: 1.0,
			};

	lineOnStyle = new OpenLayers.Style(lineOnTemplate, {context: wfsStyleContext});
	
	lineOffStyle = {
			strokeOpacity: 0.0
	};
	
	lineStyleMap = new OpenLayers.StyleMap({
		"default":lineOnStyle,
		"temporary":lineOffStyle
	});
	
    var kmlStyleContext = {
            getColour: function(feature) {
                var c = feature.attributes.id.value%colours.length;
                return colours[c];
            } };
            
	var polygonOnTemplate = {
			strokeColor: "${getColour}",
			strokeWidth: 2,
			strokeOpacity: 1.0,
			fillColor: "${getColour}",
			fillOpacity: 0.5		 
			};
	
	polygonOnStyle = new OpenLayers.Style(polygonOnTemplate, {context:kmlStyleContext});
	
	polygonOffStyle = {
			strokeOpacity: 0.0,
			fillOpacity: 0.0
			};
	
	polygonStyleMap = new OpenLayers.StyleMap({
		"default" : polygonOnStyle,
		"temporary" : polygonOffStyle
		 });
	
	var startEndPointsStyleContext = {
			getPointColour: function(feature) {
				var pointColour = (feature.attributes.pointName == "start") ? "#00CD00" : "#CD0000";
				return pointColour;
			}};
		
	var startEndPointsOnTemplate = {
			pointRadius: 2,
			fillColor: "${getPointColour}",
			strokeColor:"${getPointColour}",	
			fillOpacity: 0,
			strokeOpacity: 1,
			strokeWidth: 1.2
			};
	
	startEndPointsOnStyle = new OpenLayers.Style(startEndPointsOnTemplate, {context:startEndPointsStyleContext});
	
	startEndPointsOffStyle = {
			strokeOpacity: 0,
			fillOpacity: 0
			};
	
	startEndPointsStyleMap = new OpenLayers.StyleMap({
		"default" : startEndPointsOnStyle,
		"temporary" : startEndPointsOffStyle
		 });

}

var thisProjection;

function reportProjectionDescr() {

	var projectionCode = $('input[id=projectionCode]').val();
	
	$('#projectionDescr').html("Searching for " + projectionCode + "...");
	thisProjection = new Proj4js.Proj(projectionCode, projectionCallback);

}

function projectionCallback() {

	var detailText = "";
	var strArray = thisProjection.defData.split("+");
	var title;
	
	for (var s in strArray) {
		if (strArray[s].indexOf("title") != -1) {
			detailText = "Title: " + strArray[s].split("=")[1];
		}
	}
	
	if (detailText == "") {
		if (thisProjection.ellipseName != null) {
			detailText = "Ellipse Name: " + thisProjection.ellipseName;
		} else {
			if (thisProjection.defData != null) {
				detailText = "Details: ";
				for (var i=1; i <strArray.length; i++) {
					detailText = detailText + trim(strArray[i]) + ", ";
				}
				//labelText = thisProjection.defData;
			} else {
				detailText = "Projection exists."
			}
		}
	}
	
	var headerText = "<b>" + thisProjection.srsCodeInput + "</b>:<br>"
	
	$('#projectionDescr').html(headerText+detailText);
	
}

function trim(str) {
	return str.replace(/^\s+|\s+$/g,"");

}


Proj4js.reportError = function(msg) {
	
	$('#projectionDescr').html(msg + "Manually search for a code at <a href='http://spatialreference.org'>spatialreference.org</a>");
}


function updateAnimalInfo(linesLayer) {
    
    var layerName = linesLayer.name;
    var layerId = linesLayer.id;
    var featureId = "";
    
	for (var key in linesLayer.features) {
        var feature = linesLayer.features[key];
        if (feature.attributes && feature.attributes.animalId) {
                var colour = colours[feature.attributes.animalId % colours.length];
                var labelText = "";
                if (linesLayer === allAnimalTracksLayer) {
                	labelText = feature.attributes.animalName;
                	layerName = "Trajectory";
                }
                feature.renderIntent = "default";
                
                // set the colour and make sure the show/hide all box is checked
                $('#legend-colour-' + feature.attributes.animalId).attr('style', 'background-color: ' + colour + ';');
                $('input[id=select-animal-' + feature.attributes.animalId + ']').attr('checked','checked');
                
                // add detail for this layer
                
    	    	var distance = feature.geometry.getGeodesicLength(map.projection)/1000;
    	    	
                var checkboxValue = layerId + "-" + feature.id;
                var checkboxId = checkboxValue.replace(/\./g,"");
                
                var checkboxHtml = "<input type='checkbox' class='shortInputCheckbox' " 
                				 + "id='select-feature-" + checkboxId + "' value='" + checkboxValue + "' checked='true'/></input>";
                
                var html = "<b>&nbsp;&nbsp;" + layerName + "</b>"
                		+ "<table><tr><td>Date From:</td><td>" + feature.attributes.fromDate + "</td></tr>"
	    		  		+ "<tr><td>Date To:</td><td>" + feature.attributes.toDate + "</td></tr>"
    	    			+ "<tr><td>Minimum Distance: </td><td>" + Math.round(distance*1000)/1000 + "km </td></tr></table><br>";
 	            
                $('#animalInfo-'+ feature.attributes.animalId).append(checkboxHtml + html);
 	            $('input[id=select-feature-' + checkboxId + ']').change(function() {
                    toggleFeature(this.value,this.checked);
                });
	        }
        }
    linesLayer.redraw();
} 



function createPointsLayer() {
	
	pointsLayer = new OpenLayers.Layer.Vector(
        		"Start and End Points",
        		{projection: projection4326,
        		 styleMap: startEndPointsStyleMap	
        		 });
		
	for (var key in allAnimalTracksLayer.features) {
         var feature = allAnimalTracksLayer.features[key];
         if (feature.attributes) {
        	// add features
	         var startPoint = new OpenLayers.Feature.Vector(feature.geometry.components[0]);
	         	 startPoint.attributes = {animalId : feature.attributes.animalId,
					            		animalName : feature.attributes.animalName, 
					            		fromDate: feature.attributes.fromDate,
					            		pointName:	"start"};
	        var endPoint = new OpenLayers.Feature.Vector(feature.geometry.components[feature.geometry.components.length-1]);
	            endPoint.attributes = {animalId : feature.attributes.animalId,
					            		animalName : feature.attributes.animalName, 
					            		toDate: feature.attributes.toDate,
					            		pointName:	"end"};
            pointsLayer.addFeatures([startPoint,endPoint]);
	         
         }
    }
	map.addLayer(pointsLayer);
}

function zoomToTrack(animalId) {

	for (var key in allAnimalTracksLayer.features) {
	     var feature = allAnimalTracksLayer.features[key];
	     if (feature.attributes && animalId == feature.attributes.animalId) {
	       	map.zoomToExtent(feature.geometry.getBounds(),false);
	     }
	}
}

function getVectorLayers() {
	//get vector layers from layerswitcher 
	var vectorLayers = new Array();
	for (var c in map.controls) {
		var control = map.controls[c];
		if (control.id.indexOf("LayerSwitcher") != -1) {
			for (var i=0; i < control.dataLayers.length; i++) {
				vectorLayers.push(control.dataLayers[i].layer);
			}
		}
	}
	return vectorLayers;
}


function toggleFeature(featureIdentifier, setVisible) {
	
	var splitString = featureIdentifier.split("-");
	var layerId = splitString[0];
	var featureId = splitString[1];
	
 	var layer = map.getLayer(layerId);
	for (var key in layer.features) {
        var feature = layer.features[key];
        if (feature.id == featureId) {

    		if (setVisible) {
				feature.renderIntent = "default";
			}else {
				feature.renderIntent = "temporary";
			}
			layer.drawFeature(feature);
        }
	}
}

function toggleAllAnimalFeatures(animalId, setVisible) {

	var vectorLayers = getVectorLayers();

    for (var l in vectorLayers) {
    	var layer = vectorLayers[l];
    	var layerName = layer.name;
    	for (var f in layer.features) {
    		var feature = layer.features[f];
    		var featureAnimalId;
    		if (layerName.indexOf("Trajector") != -1 || layerName.indexOf("Start and End Points") != -1) {
    			featureAnimalId = feature.attributes.animalId;
    		} else {
    			featureAnimalId = feature.attributes.id.value;
    		}
    		
    		if (featureAnimalId == animalId) {
    			var featureIdentifier = layer.id + "-" + feature.id;
    			toggleFeature(featureIdentifier, setVisible);
    		}
    	}
     }
    $("#animalInfo-"+animalId).find(':checkbox').attr("checked",setVisible);
}

function addProjectMapLayer() {

    var projectId = $('#projectId').val();
    var dateFrom = $('input[id=fromDatepicker]').val();
    var dateTo=$('input[id=toDatepicker]').val();
    var queryType =$('input[name=mapQueryTypeSelect]:checked');
    var queryTypeDescription =  queryType.parent().next().text();
     
/*
    var data = '&dateFrom=' + dateFrom
     + '&dateTo=' + dateTo
     + '&queryType=' + queryType.val()
     + '&mapQueryTypeDescription=' + queryTypeDescription;
    
     alert("data : " + data);
*/
    if (queryType.val() != null) {
    
        var params = {projectId: projectId
	                 ,queryType: queryType.val()};
	    var layerName = queryTypeDescription;
	
	    if (dateFrom.length == 10) {
	        layerName = layerName + " from " + dateFrom;
	        params.dateFrom = dateFrom;
	    }
	
	    if (dateTo.length == 10) {
	        layerName = layerName + " to " + dateTo;
	        params.dateTo = dateTo;
	    }
	
	    if (queryType.val() == "LINES") {
	        addWFSLayer(layerName, params);
	    } else {
	        addKMLLayer(layerName,params);
	    }
	    
    } else {
	    alert("Please set a Layer Type.");
    }
        
}

function addKMLLayer(layerName, params) {


	
	var queryOverlay = new OpenLayers.Layer.Vector(
                layerName,{
                	strategies: [new OpenLayers.Strategy.Fixed()],
                	eventListeners: {
                		loadend: function (e) {updateAnimalInfoFromKML(layerName, e);}
                	},
                	protocol: new OpenLayers.Protocol.HTTP(
                			{url: "mapQueryKML",
                			 params: params,
                			 format: new OpenLayers.Format.KML(
		                        {//extractStyles: true,
		                         extractAttributes: true,
		                         maxDepth: 2,
		                         internalProjection: projection900913,
		                         externalProjection: projection4326,
		                         kmlns:"http://localhost:8080/"
		                        })
                			}),
                	styleMap:polygonStyleMap		
                });

        map.addLayer(queryOverlay);
}
                
function updateAnimalInfoFromKML(layerName, e) {
	
	for (var f in e.object.features) {
		var feature = e.object.features[f];
		var area = feature.attributes.area.value;
		
		feature.renderIntent = "default";
		feature.layer.drawFeature(feature);

		var checkboxValue = feature.layer.id + "-" + feature.id;
        var checkboxId = checkboxValue.replace(/\./g,"");
	    var checkboxHtml = "<input type='checkbox' class='shortInputCheckbox' " 
			 + "id='select-feature-" + checkboxId + "' value='" + checkboxValue + "' checked='true'/></input>";
		var html = "&nbsp;&nbsp;<b>" + layerName + "</b>" 
//				+ "<br> Area: " + 		Math.round(area*1000)/1000 + "<br>";
   		+ "<table><tr><td> Area: </td><td>" + Math.round(area*1000)/1000 + " km<sup>2</sup></td></tr></table><br>";
		$('#animalInfo-'+ feature.attributes.id.value).append(checkboxHtml + html);
	    $('input[id=select-feature-' + checkboxId + ']').change(function() {
	        toggleFeature(this.value,this.checked);
	    });

	}
	
}

function addWFSLayer(layerName, params) {

        newWFSOverlay = new OpenLayers.Layer.Vector(
            layerName,
            {strategies: [new OpenLayers.Strategy.Fixed()],
             eventListeners: {
                loadend: function (e) {
                	map.zoomToExtent(newWFSOverlay.getDataExtent(),false);
                	updateAnimalInfo(this);
            	}
             },
             projection: projection4326,
             protocol: new OpenLayers.Protocol.WFS.v1_1_0({
                url:  "mapQueryWFS",
                params:params,
                featureType: "Track",
                featureNS: "http://localhost:8080/"
                })
            });

        map.addLayer(newWFSOverlay);
        
}


