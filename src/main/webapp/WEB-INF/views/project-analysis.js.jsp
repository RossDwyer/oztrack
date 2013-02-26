<%@ page contentType="text/javascript; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
(function(OzTrack) {
    OzTrack.AnalysisMap = function(div, options) {
        if (!(this instanceof OzTrack.AnalysisMap)) {
            throw new Error("Constructor called as a function");
        }
        var that = this;

        that.projection900913 = new OpenLayers.Projection("EPSG:900913");
        that.projection4326 = new OpenLayers.Projection("EPSG:4326");

        that.projectId = options.projectId;
        that.animalIds = options.animalIds;
        that.animalVisible = {};
        $.each(that.animalIds, function(i, animalId) {
            that.animalVisible[animalId] = true;
        });
        that.projectBounds = options.projectBounds.clone().transform(that.projection4326, that.projection900913);
        that.animalBounds = {};
        $.each(options.animalBounds, function(animalId, bounds) {
            that.animalBounds[animalId] = bounds.clone().transform(that.projection4326, that.projection900913);
        });
        that.animalColours = options.animalColours;
        that.minDate = options.minDate;
        that.maxDate = options.maxDate;
        that.onAnalysisCreate = options.onAnalysisCreate;
        that.onAnalysisError = options.onAnalysisError;
        that.onAnalysisSuccess = options.onAnalysisSuccess;

        that.detectionLayers = [];
        that.trajectoryLayers = [];
        that.projectMapLayers = {};
        that.wfsLayers = {};
        that.analyses = {};
        that.projectMapLayerIdSeq = 0;
        that.wfsLayerIdSeq = 0;

        that.map = new OpenLayers.Map(div, {
            theme: null,
            units : 'm',
            projection : that.projection900913,
            displayProjection : that.projection4326,
            controls: []
        });
        that.map.addControl(new OpenLayers.Control.Navigation());
        that.map.addControl(new OpenLayers.Control.Zoom());
        that.map.addControl(new OpenLayers.Control.Attribution());
        that.map.addControl(new OpenLayers.Control.MousePosition());
        that.map.addControl(new OpenLayers.Control.ScaleLine());
        that.map.addControl(new OpenLayers.Control.NavToolbar());
        that.layerSwitcher = new OpenLayers.Control.LayerSwitcher();
        that.map.addControl(that.layerSwitcher);
        that.layerSwitcher.maximizeControl();
        that.loadingPanel = new OpenLayers.Control.LoadingPanel();
        that.map.addControl(that.loadingPanel);

        that.googlePhysicalLayer = new OpenLayers.Layer.Google('Google Physical', {
            type : google.maps.MapTypeId.TERRAIN
        });
        that.googleSatelliteLayer = new OpenLayers.Layer.Google('Google Satellite', {
            type : google.maps.MapTypeId.SATELLITE,
            numZoomLevels : 22
        });
        that.googleStreetsLayer = new OpenLayers.Layer.Google('Google Streets', {
            numZoomLevels : 20
        });
        that.googleHybridLayer = new OpenLayers.Layer.Google('Google Hybrid', {
            type : google.maps.MapTypeId.HYBRID,
            numZoomLevels : 20
        });
        that.map.addLayers([that.googleSatelliteLayer, that.googlePhysicalLayer, that.googleStreetsLayer, that.googleHybridLayer]);

        that.osmLayer = new OpenLayers.Layer.OSM('OpenStreetMap');
        that.map.addLayer(that.osmLayer);

        that.bathymetryLayer = new OpenLayers.Layer.WMS(
            'Bathymetry',
            '/geoserver/gwc/service/wms',
            {
                layers: 'oztrack:gebco_08',
                styles: 'oztrack_bathymetry',
                format: 'image/png'
            },
            {
                isBaseLayer: true,
                wrapDateLine: true,
                attribution: '<a href="http://www.gebco.net">The GEBCO_08 Grid, version 20091120</a>'
            }
        );
        that.map.addLayer(that.bathymetryLayer);

        that.controlPanel = new OpenLayers.Control.Panel();
        that.controlPanel.addControls([
            new OpenLayers.Control.Button({
                title : 'Zoom to Data Extent',
                displayClass : "zoomButton",
                trigger : function() {
                    that.map.zoomToExtent(that.projectBounds, false);
                }
            })
        ]);
        that.map.addControl(that.controlPanel);

        that.startEndStyleMap = createStartEndPointsStyleMap();
        that.polygonStyleMap = createPolygonStyleMap();

        that.allDetectionsLayer = createDetectionLayer({});
        that.map.addLayer(that.allDetectionsLayer.getWMSLayer());

        that.allTrajectoriesLayer = createTrajectoryLayer({});
        that.map.addLayer(that.allTrajectoriesLayer.getWMSLayer());

        that.map.addLayer(createWFSLayer('Start and End Points', 'StartEnd', {
            projectId : that.projectId,
            queryType : 'START_END'
        }, that.startEndStyleMap));
        
        that.map.zoomToExtent(that.projectBounds, false);

        function createPointStyleMap() {
            var styleContext = {
                getColour : function(feature) {
                    return that.animalColours[feature.attributes.animalId];
                }
            };
            var pointOnStyle = new OpenLayers.Style({
                fillColor : "\${getColour}",
                strokeColor : "\${getColour}",
                strokeOpacity : 0.8,
                strokeWidth : 0.2,
                graphicName : "cross",
                pointRadius : 4
            }, {
                context : styleContext
            });
            var pointOffStyle = {
                strokeOpacity : 0.0,
                fillOpacity : 0.0
            };
            var pointStyleMap = new OpenLayers.StyleMap({
                "default" : pointOnStyle,
                "temporary" : pointOffStyle
            });
            return pointStyleMap;
        }

        function createPolygonStyleMap() {
            var styleContext = {
                getColour : function(feature) {
                    return that.animalColours[feature.attributes.id.value];
                }
            };
            var polygonOnStyle = new OpenLayers.Style({
                strokeColor : "\${getColour}",
                strokeWidth : 2.0,
                strokeOpacity : 0.8,
                fillColor : "\${getColour}",
                fillOpacity : 0.5
            }, {
                context : styleContext
            });
            var polygonOffStyle = {
                strokeOpacity : 0.0,
                fillOpacity : 0.0
            };
            var polygonStyleMap = new OpenLayers.StyleMap({
                "default" : polygonOnStyle,
                "temporary" : polygonOffStyle
            });
            return polygonStyleMap;
        }

        function createStartEndPointsStyleMap() {
            var styleContext = {
                getColour : function(feature) {
                    if (feature.attributes.identifier == "start") {
                        return "#00CD00";
                    }
                    if (feature.attributes.identifier == "end") {
                        return "#CD0000";
                    }
                    return "#CDCDCD";
                }
            };
            var startEndPointsOnStyle = new OpenLayers.Style({
                pointRadius : 2,
                strokeColor : "\${getColour}",
                strokeWidth : 1.2,
                strokeOpacity : 1.0,
                fillColor : "\${getColour}",
                fillOpacity : 0
            }, {
                context : styleContext
            });
            var startEndPointsOffStyle = {
                strokeOpacity : 0,
                fillOpacity : 0
            };
            var startEndPointsStyleMap = new OpenLayers.StyleMap({
                "default" : startEndPointsOnStyle,
                "temporary" : startEndPointsOffStyle
            });
            return startEndPointsStyleMap;
        }

        that.addProjectMapLayer = function() {
            var queryType = $('input[name=queryTypeSelect]:checked');
            var queryTypeValue = queryType.val();
            var queryTypeLabel = $('label[for="' + queryType.attr('id') + '"]').text();
            if (queryTypeValue == null) {
                alert("Please set a Layer Type.");
            }
            var layerName = queryTypeLabel;
            var params = {
                queryType : queryTypeValue,
                projectId : $('#projectId').val()
            };
            var fromDate = $('#fromDate').val();
            if (fromDate) {
                params.fromDate = fromDate;
            }
            var toDate = $('#toDate').val();
            if (toDate) {
                params.toDate = toDate;
            }
            params.animalIds = $('input[name=animal]:checked').map(function() {return $(this).val();}).toArray().join(',');
            $('.paramField-' + queryTypeValue).each(function() {
                if ($(this).attr('type') == 'checkbox') {
                    params[$(this).attr('name')] = $(this).is(':checked') ? 'true' : 'false';
                }
                else if ($(this).val()) {
                    params[$(this).attr('name')] = $(this).val();
                }
            });
            if (queryTypeValue == "LINES") {
                var trajectoryLayer = createTrajectoryLayer(params);
                that.map.addLayer(trajectoryLayer.getWMSLayer());
            }
            else if (queryTypeValue == "POINTS") {
                var detectionLayer = createDetectionLayer(params);
                that.map.addLayer(detectionLayer.getWMSLayer());
            }
            else if (queryTypeValue == "START_END") {
                that.map.addLayer(createWFSLayer(layerName, 'StartEnd', params, that.startEndStyleMap));
            }
            else {
                createAnalysisLayer(params, layerName);
            }
        };

        function createAnalysisLayer(params, layerName) {
            $.ajax({
                url: '/projects/' + that.projectId + '/analyses',
                type: 'POST',
                data: params,
                error: function(xhr, textStatus, errorThrown) {
                    that.onAnalysisError($(xhr.responseText).find('error').text() || 'Error processing request');
                },
                complete: function (xhr, textStatus) {
                    if (textStatus == 'success') {
                        var analysisUrl = xhr.getResponseHeader('Location');
                        that.onAnalysisCreate(layerName, analysisUrl);
                        that.addAnalysisLayer(analysisUrl, layerName);
                    }
                }
            });
        }

        that.addAnalysisLayer = function(analysisUrl, layerName) {
            $.ajax({
                url: analysisUrl,
                type: 'GET',
                error: function(xhr, textStatus, errorThrown) {
                    that.onAnalysisError($(xhr.responseText).find('error').text() || 'Error getting analysis');
                },
                complete: function (xhr, textStatus) {
                    if (textStatus == 'success') {
                        var analysis = $.parseJSON(xhr.responseText);
                        that.analyses[analysis.id] = analysis;
                        currentAnalysisId = analysis.id;
                        updateAnimalInfoForAnalysis(layerName, analysis);
                        that.loadingPanel.increaseCounter();
                        pollAnalysisLayer(analysisUrl, layerName);
                    }
                }
            });
        };

        function pollAnalysisLayer(analysisUrl, layerName) {
            $.ajax({
                url: analysisUrl,
                type: 'GET',
                error: function(xhr, textStatus, errorThrown) {
                    that.loadingPanel.decreaseCounter();
                    that.onAnalysisError($(xhr.responseText).find('error').text() || 'Error getting analysis');
                },
                complete: function (xhr, textStatus) {
                    if (textStatus == 'success') {
                        var analysis = $.parseJSON(xhr.responseText);
                        if (!that.analyses[analysis.id]) {
                            that.loadingPanel.decreaseCounter();
                            return;
                        }
                        that.analyses[analysis.id] = analysis;
                        if (analysis.status == 'COMPLETE') {
                            addAnalysisResultLayer(analysis, layerName);
                        }
                        else if ((analysis.status == 'NEW') || (analysis.status == 'PROCESSING')) {
                            setTimeout(function () {pollAnalysisLayer(analysisUrl, layerName);}, 1000);
                        }
                        else {
                            that.loadingPanel.decreaseCounter();
                            that.onAnalysisError(analysis.message || 'Error running analysis');
                        }
                    }
                }
            });
        }

        function addAnalysisResultLayer(analysis, layerName) {
            var styleMap = that.polygonStyleMap;
            var extractStyles = false;
            if ((analysis.params.queryType == "HEATMAP_POINT") || (analysis.params.queryType == "HEATMAP_LINE")) {
                styleMap = null;
                extractStyles = true;
            }
            var queryOverlay = new OpenLayers.Layer.Vector(layerName, {
                styleMap : styleMap
            });
            if (that.analyses[analysis.id]) {
                that.analyses[analysis.id].layer = queryOverlay;
            }
            var protocol = new OpenLayers.Protocol.HTTP({
                url : analysis.resultUrl,
                format : new OpenLayers.Format.KML({
                    extractStyles: extractStyles,
                    extractAttributes: true,
                    maxDepth: 2,
                    internalProjection: that.projection900913,
                    externalProjection: that.projection4326,
                    kmlns: "http://oztrack.org/xmlns#"
                })
            });
            var callback = function(resp) {
                that.loadingPanel.decreaseCounter();
                if (resp.code == OpenLayers.Protocol.Response.SUCCESS) {
                    queryOverlay.addFeatures(resp.features);
                    updateAnimalInfoFromKML(analysis, resp.features);
                    that.onAnalysisSuccess();
                }
                else {
                    that.onAnalysisError(jQuery(resp.priv.responseText).find('error').text() || 'Error processing request');
                }
            };
            protocol.read({
                callback : callback
            });
            that.map.addLayer(queryOverlay);
        }
        
        that.deleteCurrentAnalysis = function() {
            if (currentAnalysisId) {
                that.deleteAnalysis(currentAnalysisId);
            }
        };
        
        that.deleteAnalysis = function(id) {
            var confirmMessage =
                (that.analyses[id] && (that.analyses[id].params.animalIds.length > 1))
                ? 'This will delete the analysis for all animals. Do you wish to continue?'
                : 'Are you sure you wish to delete this analysis?';
            if (!confirm(confirmMessage)) {
                return;
            }
            if (that.analyses[id]) {
                if (that.analyses[id].layer) {
                    that.analyses[id].layer.destroy();
                }
                delete that.analyses[id];
            }
            if (id == currentAnalysisId) {
                currentAnalysisId = null;
            }
            $('.analysisInfo-' + id).fadeOut().remove();
        };
        
        that.deleteProjectMapLayer = function(id) {
            if (!confirm('This will delete the layer for all animals. Do you wish to continue?')) {
                return;
            }
            if (that.projectMapLayers[id]) {
                that.projectMapLayers[id].getWMSLayer().destroy();
                delete that.projectMapLayers[id];
            }
            that.detectionLayers = $.grep(that.detectionLayers, function(e, i) {return e.id != id});
            that.trajectoryLayers = $.grep(that.trajectoryLayers, function(e, i) {return e.id != id});
            $('.projectMapLayerInfo-' + id).fadeOut().remove();
        };

        that.deleteWFSLayer = function(id) {
            if (!confirm('This will delete the layer for all animals. Do you wish to continue?')) {
                return;
            }
            if (that.wfsLayers[id]) {
                that.wfsLayers[id].destroy();
                delete that.wfsLayers[id];
            }
            $('.wfsLayerInfo-' + id).fadeOut().remove();
        };

        function createDetectionLayer(params) {
            function buildFilter(params) {
                // If supplied, use param to filter animals; otherwise, include all animals.
                var cqlFilterAnimalIds = params.animalIds ? params.animalIds.split(',') : that.animalIds;
                
                // Exclude animals not currently visible on the map.
                cqlFilterAnimalIds = $.grep(cqlFilterAnimalIds, function(e, i) {return that.animalVisible[e]});
                
                // If filter is empty, include dummy ID (i.e. -1) that will never be matched.
                // This prevents the CQL_FILTER parameter from being syntactically invalid.
                cqlFilterAnimalIds = (cqlFilterAnimalIds.length > 0) ? cqlFilterAnimalIds : [-1];
                
                var cqlFilter = 'project_id = ' + that.projectId + ' and deleted = false';
                cqlFilter += ' and animal_id in (' + cqlFilterAnimalIds.join(',') + ')';
                if (params.fromDate) {
                    cqlFilter += ' and detectiontime >= \'' + moment(new Date(params.fromDate)).format('YYYY-MM-DD') + '\'';
                }
                if (params.toDate) {
                    cqlFilter += ' and detectiontime <= \'' + moment(new Date(params.toDate)).format('YYYY-MM-DD') + '\'';
                }
                return cqlFilter;
            }
            var title = 'Detections';
            var wmsLayer = new OpenLayers.Layer.WMS(
                title,
                '/geoserver/wms',
                {
                    layers: 'oztrack:positionfixlayer',
                    styles: 'oztrack_positionfixlayer',
                    cql_filter: buildFilter(params),
                    format: 'image/png',
                    transparent: true
                },
                {
                    isBaseLayer: false,
                    tileSize: new OpenLayers.Size(512,512)
                }
            );
            var layer = {
                id: that.projectMapLayerIdSeq++,
                getTitle: function() {
                    return title;
                },
                getParams: function() {
                    return params;
                },
                getCQLFilter: function() {
                    return buildFilter(params);
                },
                getWMSLayer: function() {
                    return wmsLayer;
                }
            };
            that.projectMapLayers[layer.id] = layer;
            that.detectionLayers.push(layer);
            updateAnimalInfoFromLayer(layer);
            that.onAnalysisSuccess();
            return layer;
        }
        
        function updateDetectionLayers() {
            for (var i = 0; i < that.detectionLayers.length; i++) {
                that.detectionLayers[i].getWMSLayer().params['CQL_FILTER'] = that.detectionLayers[i].getCQLFilter();
                that.detectionLayers[i].getWMSLayer().redraw();
            }
        }
        
        function createTrajectoryLayer(params) {
            function buildFilter(params) {
                // If supplied, use param to filter animals; otherwise, include all animals.
                var cqlFilterAnimalIds = params.animalIds ? params.animalIds.split(',') : that.animalIds;
                
                // Exclude animals not currently visible on the map.
                cqlFilterAnimalIds = $.grep(cqlFilterAnimalIds, function(e, i) {return that.animalVisible[e]});
                
                // If filter is empty, include dummy ID (i.e. -1) that will never be matched.
                // This prevents the CQL_FILTER parameter from being syntactically invalid.
                cqlFilterAnimalIds = (cqlFilterAnimalIds.length > 0) ? cqlFilterAnimalIds : [-1];

                var cqlFilter = 'project_id = ' + that.projectId;
                cqlFilter += ' and animal_id in (' + cqlFilterAnimalIds.join(',') + ')';
                if (params.fromDate) {
                    cqlFilter += ' and startdetectiontime >= \'' + moment(new Date(params.fromDate)).format('YYYY-MM-DD') + '\'';
                }
                if (params.toDate) {
                    cqlFilter += ' and enddetectiontime <= \'' + moment(new Date(params.toDate)).format('YYYY-MM-DD') + '\'';
                }
                return cqlFilter;
            }
            var title = 'Trajectory';
            var wmsLayer = new OpenLayers.Layer.WMS(
                title,
                '/geoserver/wms',
                {
                    layers: 'oztrack:trajectorylayer',
                    styles: 'oztrack_trajectorylayer',
                    cql_filter: buildFilter(params),
                    format: 'image/png',
                    transparent: true
                },
                {
                    isBaseLayer: false,
                    tileSize: new OpenLayers.Size(512,512)
                }
            );
            var layer = {
                id: that.projectMapLayerIdSeq++,
                getTitle: function() {
                    return title;
                },
                getParams: function() {
                    return params;
                },
                getCQLFilter: function() {
                    return buildFilter(params);
                },
                getWMSLayer: function() {
                    return wmsLayer;
                }
            };
            that.projectMapLayers[layer.id] = layer;
            that.trajectoryLayers.push(layer);
            updateAnimalInfoFromLayer(layer);
            that.onAnalysisSuccess();
            return layer;
        }
        
        function updateTrajectoryLayers() {
            for (var i = 0; i < that.trajectoryLayers.length; i++) {
                that.trajectoryLayers[i].getWMSLayer().params['CQL_FILTER'] = that.trajectoryLayers[i].getCQLFilter();
                that.trajectoryLayers[i].getWMSLayer().redraw();
            }
        }

        function createWFSLayer(layerName, featureType, params, styleMap) {
            var wfsLayerId = that.wfsLayerIdSeq++;
            var wfsLayer = new OpenLayers.Layer.Vector(layerName, {
                projection : that.projection4326,
                protocol : new OpenLayers.Protocol.WFS.v1_1_0({
                    url : "/mapQueryWFS",
                    params : params,
                    featureType : featureType,
                    featureNS : "http://oztrack.org/xmlns#"
                }),
                strategies : [
                    new OpenLayers.Strategy.Fixed()
                ],
                styleMap : styleMap,
                eventListeners : {
                    loadend : function(e) {
                        updateAnimalInfoFromWFS(e.object, wfsLayerId);
                        that.onAnalysisSuccess();
                    }
                }
            });
            that.wfsLayers[wfsLayerId] = wfsLayer;
            return wfsLayer;
        }

        function updateAnimalInfoFromWFS(wfsLayer, wfsLayerId) {
            var animalProcessed = {};
            for (var key in wfsLayer.features) {
                var feature = wfsLayer.features[key];
                if (feature.attributes && feature.attributes.animalId) {
                    if (animalProcessed[feature.attributes.animalId]) {
                        continue;
                    }
                    animalProcessed[feature.attributes.animalId] = true;
                    feature.renderIntent = "default";
                    $('input[id=select-animal-' + feature.attributes.animalId + ']').attr('checked', 'checked');
                    var html = '<div class="layerInfoTitle">';
                    html += '<a class="layer-delete" href="javascript:analysisMap.deleteWFSLayer(' + wfsLayerId + ');">delete</a></span>';
                    html += wfsLayer.name;
                    html += '</div>';
                    var tableRowsHtml = '';
                    if (feature.attributes.fromDate) {
                        tableRowsHtml += '<tr>';
                        tableRowsHtml += '<td class="layerInfoLabel">Date From:</td>';
                        tableRowsHtml += '<td>' + feature.attributes.fromDate + '</td>';
                        tableRowsHtml += '</tr>';
                    }
                    if (feature.attributes.toDate) {
                        tableRowsHtml += '<tr>';
                        tableRowsHtml += '<td class="layerInfoLabel">Date To:</td>';
                        tableRowsHtml += '<td>' + feature.attributes.toDate + '</td>';
                        tableRowsHtml += '</tr>';
                    }
                    if (feature.geometry.CLASS_NAME == 'OpenLayers.Geometry.LineString') {
                        var distance = (Math.round(feature.geometry.getGeodesicLength(that.map.projection)) / 1000);
                        tableRowsHtml += '<tr>';
                        tableRowsHtml += '<td class="layerInfoLabel">Min Distance: </td>';
                        tableRowsHtml += '<td>' + distance + ' km </td>';
                        tableRowsHtml += '</tr>';
                    }
                    if (tableRowsHtml != '') {
                        html += '<table>' + tableRowsHtml + '</table>';
                    }
                    $('#animalInfo-' + feature.attributes.animalId).append('<div class="layerInfo wfsLayerInfo-' + wfsLayerId + '">' + html + '</div>');
                }
            }
        }
        
        function updateAnimalInfoFromLayer(layer) {
            var layerAnimalIds = layer.getParams().animalIds ? layer.getParams().animalIds.split(',') : that.animalIds
            for (var i = 0; i < layerAnimalIds.length; i++) {
                var html = '<div class="layerInfoTitle">';
                html += '<a class="layer-delete" href="javascript:analysisMap.deleteProjectMapLayer(' + layer.id + ');">delete</a></span>';
                html += layer.getTitle();
                html += '</div>';
                var tableRowsHtml = '';
                var fromDate = layer.getParams().fromDate || moment(that.minDate).format('YYYY-MM-DD');
                tableRowsHtml += '<tr>';
                tableRowsHtml += '<td class="layerInfoLabel">Date From:</td>';
                tableRowsHtml += '<td>' + fromDate + '</td>';
                tableRowsHtml += '</tr>';
                var toDate = layer.getParams().toDate || moment(that.maxDate).format('YYYY-MM-DD');
                tableRowsHtml += '<tr>';
                tableRowsHtml += '<td class="layerInfoLabel">Date To:</td>';
                tableRowsHtml += '<td>' + toDate + '</td>';
                tableRowsHtml += '</tr>';
                if (tableRowsHtml != '') {
                    html += '<table>' + tableRowsHtml + '</table>';
                }
                $('#animalInfo-' + layerAnimalIds[i]).append('<div class="layerInfo projectMapLayerInfo-' + layer.id + '">' + html + '</div>');
            }
        }

        function updateAnimalInfoForAnalysis(layerName, analysis) {
            for (var i = 0; i < analysis.params.animalIds.length; i++) {
                var html = '<div class="layerInfoTitle">';
                html += '<a class="layer-delete" href="javascript:analysisMap.deleteAnalysis(' + analysis.id + ');">delete</a></span>';
                html += layerName;
                html += '</div>';
                var tableRowsHtml = '';
                if (analysis.params.fromDate) {
                    tableRowsHtml += '<tr>';
                    tableRowsHtml += '<td class="layerInfoLabel">Date From:</td>';
                    tableRowsHtml += '<td>' + analysis.params.fromDate + '</td>';
                    tableRowsHtml += '</tr>';
                }
                if (analysis.params.toDate) {
                    tableRowsHtml += '<tr>';
                    tableRowsHtml += '<td class="layerInfoLabel">Date To:</td>';
                    tableRowsHtml += '<td>' + analysis.params.toDate + '</td>';
                    tableRowsHtml += '</tr>';
                }
                <c:forEach items="${analysisTypeList}" var="analysisType">
                if (analysis.params.queryType == '${analysisType}') {
                    <c:forEach items="${analysisType.parameterTypes}" var="parameterType">
                    if (analysis.params.${parameterType.identifier}) {
                        tableRowsHtml += '<tr>';
                        tableRowsHtml += '<td class="layerInfoLabel">${parameterType.displayName}: </td>';
                        tableRowsHtml += '<td>' + analysis.params.${parameterType.identifier} + ' ${parameterType.units}</td>';
                        tableRowsHtml += '</tr>';
                    }
                    </c:forEach>
                }
                </c:forEach>
                html += '<table id="analysis-table-' + analysis.params.animalIds[i] + '-' + analysis.id + '" style="' + (tableRowsHtml ? '' : 'display: none;') + '">' + tableRowsHtml + '</table>';
                $('#animalInfo-' + analysis.params.animalIds[i]).append('<div class="layerInfo analysisInfo-' + analysis.id + '">' + html + '</div>');
            }
        }

        function updateAnimalInfoFromKML(analysis, features) {
            for (i = 0; i < analysis.params.animalIds.length; i++) {
                var animalId = analysis.params.animalIds[i];
                var animalFeature = null;
                for (j = 0; j < features.length; j++) {
                    if (features[j].attributes.id && features[j].attributes.id.value == animalId) {
                        animalFeature = features[j];
                        break;
                    }
                }
                var tableRowsHtml = '';
                if (animalFeature) {
                    animalFeature.renderIntent = "default";
                    animalFeature.layer.drawFeature(animalFeature);
                    if (animalFeature.attributes.area && animalFeature.attributes.area.value) {
                        var area = Math.round(animalFeature.attributes.area.value * 1000) / 1000;
                        tableRowsHtml += '<tr>';
                        tableRowsHtml += '<td class="layerInfoLabel">Area: </td>';
                        tableRowsHtml += '<td>' + area + ' km<sup>2</sup></td>';
                        tableRowsHtml += '</tr>';
                    }
                    if (!analysis.params.hValue && animalFeature.attributes.hval && animalFeature.attributes.hval.value) {
                        var hval = Math.round(animalFeature.attributes.hval.value * 1000) / 1000;
                        tableRowsHtml += '<tr>';
                        tableRowsHtml += '<td class="layerInfoLabel">h value: </td>';
                        tableRowsHtml += '<td>' + hval + '</td>';
                        tableRowsHtml += '</tr>';
                    }
                }
                tableRowsHtml += '<tr>';
                tableRowsHtml += '<td class="layerInfoLabel">Export as: </td>';
                tableRowsHtml += '<td>';
                tableRowsHtml += '<a href="' + analysis.resultUrl + '">KML</a> ';
                tableRowsHtml += '<div id="analysisHelpPopover-' + analysis.id + '" class="help-popover" title="KML Export">';
                tableRowsHtml += '<p>To enable users to animate their animal tracking files, as well as visualisation in ';
                tableRowsHtml += '3-dimensions, we offer the option of exporting the animal tracking data and home-range ';
                tableRowsHtml += 'layers into Google Earth. Once loaded into Google Earth, the user can alter the altitude and ';
                tableRowsHtml += 'angle of the viewer, add additional features, and run the animal track as an animation.</p>';
                tableRowsHtml += '</div>';
                tableRowsHtml += '<script>initHelpPopover($(\'#analysisHelpPopover-' + analysis.id + '\'));</script>';
                tableRowsHtml += '</td>';
                tableRowsHtml += '</tr>';
                if (tableRowsHtml) {
                    $('#analysis-table-' + animalId + '-' + analysis.id).show().append(tableRowsHtml);
                }
            }
        }

        that.zoomToAnimal = function(animalId) {
            if (that.animalBounds[animalId]) {
                that.map.zoomToExtent(that.animalBounds[animalId], false);
            }
        };

        that.toggleAllAnimalFeatures = function(animalId, visible) {
            that.animalVisible[animalId] = visible;
            $("#animalInfo-" + animalId).find(':checkbox').attr("checked", visible);
        };

        that.toggleAllAnimalFeaturesCommit = function() {
            updateDetectionLayers();
            updateTrajectoryLayers();
            function getVectorLayers() {
                var vectorLayers = new Array();
                for (var c in that.map.controls) {
                    var control = that.map.controls[c];
                    if (control.id.indexOf("LayerSwitcher") != -1) {
                        for (var i = 0; i < control.dataLayers.length; i++) {
                            vectorLayers.push(control.dataLayers[i].layer);
                        }
                    }
                }
                return vectorLayers;
            }
            var vectorLayers = getVectorLayers();
            for (i = 0; i < that.animalIds.length; i++) {
                var animalId = that.animalIds[i];
                for (var l in vectorLayers) {
                    var layer = vectorLayers[l];
                    var layerName = layer.name;
                    for (var f in layer.features) {
                        var feature = layer.features[f];
                        var featureAnimalId =
                            (feature.attributes.animalId) ? feature.attributes.animalId :
                            (feature.attributes.id.value) ? feature.attributes.id.value :
                            null;
                        if (featureAnimalId == animalId) {
                            feature.renderIntent = that.animalVisible[animalId] ? 'default' : 'temporary';
                            feature.layer.drawFeature(feature);
                        }
                    }
                }
            }
        };

        that.updateSize = function() {
            that.map.updateSize();

            // Workaround zooming bug:
            // Map resize displays google layer at incorrect zoom level
            // Calling pan results in zoom levels for all layers getting back in synch
            // http://gis.stackexchange.com/questions/30075/map-resize-displays-google-layer-at-incorrect-zoom-level
            that.map.pan(1, 0, null);
            that.map.pan(-1, 0, null);
        };
    };
}(window.OzTrack = window.OzTrack || {}));