<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="org.oztrack.app.OzTrackApplication" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="tags" %>
<c:set var="dataSpaceEnabled"><%= OzTrackApplication.getApplicationContext().isDataSpaceEnabled() %></c:set>
<c:set var="isoDateFormatPattern" value="yyyy-MM-dd"/>
<tags:page>
    <jsp:attribute name="title">
        <c:choose>
        <c:when test="${project.id != null}">
            Update Project
        </c:when>
        <c:otherwise>
            Create Project
        </c:otherwise>
        </c:choose>
    </jsp:attribute>
    <jsp:attribute name="description">
        <c:choose>
        <c:when test="${project.id != null}">
            Update details for the ${project.title} project.
        </c:when>
        <c:otherwise>
            Create a new OzTrack project.
        </c:otherwise>
        </c:choose>
    </jsp:attribute>
    <jsp:attribute name="head">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/css/optimised/openlayers.css" type="text/css">
        <style type="text/css">
            .dataLicence {
                padding: 10px;
                border: 1px solid #bbb;
                background-color: #f6f6f6;
                color: #555;
                -khtml-border-radius: 3px;
                -webkit-border-radius: 3px;
                -moz-border-radius: 3px;
                -ms-border-radius: 3px;
                -o-border-radius: 3px;
                border-radius: 3px;
            }
            .dataLicenceCheckbox {
                margin-top: 0;
            }
            label.disabled {
                color: #999;'
            }
            .publication td.name {
                padding-right: 12px;
            }
            .publication td.value {
                padding-right: 12px;
            }
            .publication td.actions {
                vertical-align: middle;
            }
            .publication {
                margin-bottom: 18px;
            }
        </style>
    </jsp:attribute>
    <jsp:attribute name="tail">
        <script src="${pageContext.request.scheme}://maps.google.com/maps/api/js?v=3.9&sensor=false"></script>
        <script type="text/javascript" src="${pageContext.request.contextPath}/js/optimised/openlayers.js"></script>
        <script type="text/javascript" src="${pageContext.request.contextPath}/js/srs-selector.js"></script>
        <script type="text/javascript">
            function setCheckboxDisabled(selector, disabled) {
                $(selector).prop('disabled', disabled).parent('label').toggleClass('disabled', disabled);
            }
            function updateLicenceSelectorFromDataLicence() {
                var dataLicenceIdentifier = $('#dataLicenceIdentifier').val();
                if (!dataLicenceIdentifier) {
                    dataLicenceIdentifier = 'CC-BY';
                    $('#dataLicenceIdentifier').val(dataLicenceIdentifier);
                }
                if (dataLicenceIdentifier == 'PDM') {
                    $('#dataLicenceCopyright').prop('checked', false);
                    setCheckboxDisabled('#dataLicenceAttribution', true);
                    setCheckboxDisabled('#dataLicenceDerivatives', true);
                    setCheckboxDisabled('#dataLicenceNonShareAlike', true);
                    setCheckboxDisabled('#dataLicenceCommercial', true);
                }
                else {
                    $('#dataLicenceCopyright').prop('checked', true);
                    setCheckboxDisabled('#dataLicenceAttribution', false);
                    if (dataLicenceIdentifier == 'CC0') {
                        $('#dataLicenceAttribution').prop('checked', false);
                        setCheckboxDisabled('#dataLicenceDerivatives', true);
                        setCheckboxDisabled('#dataLicenceNonShareAlike', true);
                        setCheckboxDisabled('#dataLicenceCommercial', true);
                    }
                    else {
                        $('#dataLicenceAttribution').prop('checked', true);
                        setCheckboxDisabled('#dataLicenceDerivatives', false);
                        setCheckboxDisabled('#dataLicenceCommercial', false);
                        if ((dataLicenceIdentifier == 'CC-BY-ND') || (dataLicenceIdentifier == 'CC-BY-NC-ND')) {
                            $('#dataLicenceDerivatives').prop('checked', false);
                            setCheckboxDisabled('#dataLicenceNonShareAlike', true);
                        }
                        else {
                            $('#dataLicenceDerivatives').prop('checked', true);
                            setCheckboxDisabled('#dataLicenceNonShareAlike', false);
                            var shareAlike = (dataLicenceIdentifier == 'CC-BY-SA') || (dataLicenceIdentifier == 'CC-BY-NC-SA');
                            $('#dataLicenceNonShareAlike').prop('checked', !shareAlike);
                        }
                        if ((dataLicenceIdentifier == 'CC-BY-NC') || (dataLicenceIdentifier == 'CC-BY-NC-ND') || (dataLicenceIdentifier == 'CC-BY-NC-SA')) {
                            $('#dataLicenceCommercial').prop('checked', false);
                        }
                        else {
                            $('#dataLicenceCommercial').prop('checked', true);
                        }
                    }
                }
                $('.dataLicence').hide();
                $('#dataLicence-' + dataLicenceIdentifier).fadeIn();
            }
            function updateDataLicenceFromLicenceSelector() {
                if (!$('#dataLicenceCopyright').prop('checked')) {
                    $('#dataLicenceIdentifier').val('PDM');
                }
                else if (!$('#dataLicenceAttribution').prop('checked')) {
                    $('#dataLicenceIdentifier').val('CC0');
                }
                else {
                    var dataLicenceIdentifier = 'CC-BY';
                    if (!$('#dataLicenceCommercial').prop('checked')) {
                        dataLicenceIdentifier += '-NC';
                    }
                    if (!$('#dataLicenceDerivatives').prop('checked')) {
                        dataLicenceIdentifier += '-ND';
                    }
                    else if (!$('#dataLicenceNonShareAlike').prop('checked')) {
                        dataLicenceIdentifier += '-SA';
                    }
                    $('#dataLicenceIdentifier').val(dataLicenceIdentifier);
                }
                updateLicenceSelectorFromDataLicence();
            }
            function addPublication(publication) {
                var publication = publication || {reference: '', url: ''};
                $('#publications').append($('<div class="publication">')
                    .append($('<table>')
                    .append($('<tr>')
                        .append($('<td class="name">').append('Reference'))
                        .append($('<td class="value">').append($('<input name="publicationReference" type="text" class="input-xxlarge" />')
                            .val(publication.reference)
                        ))
                        .append($('<td class="actions" rowspan="2">')
                            .append($('<div class="btn-group">')
                                .append($('<a class="btn" href="javascript:void(0);">')
                                    .click(function(e) {$(this).closest('.publication').insertBefore($(this).closest('.publication').prev());})
                                    .append('<i class="icon-arrow-up"></i>')
                                )
                                .append($('<a class="btn" href="javascript:void(0);">')
                                    .click(function(e) {$(this).closest('.publication').insertAfter($(this).closest('.publication').next());})
                                    .append('<i class="icon-arrow-down"></i>')
                                )
                                .append($('<a class="btn" href="javascript:void(0);">')
                                    .click(function(e) {$(this).closest('.publication').remove();})
                                    .append('<i class="icon-trash"></i>')
                                )
                            )
                        )
                    )
                    .append($('<tr>')
                        .append($('<td>').append('URL'))
                        .append($('<td>').append($('<input name="publicationUrl" type="text" class="input-xxlarge" />')
                            .val(publication.url)
                        ))
                    )
                ));
            }
            $(document).ready(function() {
                $('#navTrack').addClass('active');
                srsSelector = createSrsSelector({
                    onSrsSelected: function(id) {
                        jQuery('#srsIdentifier').val(id);
                    },
                    srsList: [
                        <c:forEach items= "${srsList}" var="srs" varStatus="status">
                        {
                            id: '<c:out value="${srs.identifier}"/>',
                            title: '<c:out value="${srs.title}"/>',
                            bounds: [
                                <c:out value="${srs.bounds.envelopeInternal.minX}"/>,
                                <c:out value="${srs.bounds.envelopeInternal.minY}"/>,
                                <c:out value="${srs.bounds.envelopeInternal.maxX}"/>,
                                <c:out value="${srs.bounds.envelopeInternal.maxY}"/>
                            ]
                        }<c:if test="${not status.last}">,</c:if>
                        </c:forEach>
                    ]
                });
                $('.dataLicenceCheckbox').change(updateDataLicenceFromLicenceSelector);
                updateLicenceSelectorFromDataLicence();
                $('#otherEmbargoDateInput').datepicker({
                    altField: "#otherEmbargoDate",
                    minDate: new Date(${minEmbargoDate.time}),
                    maxDate: new Date(${beforeNonIncrementalEmbargoDisableDate ? maxEmbargoDate.time : maxIncrementalEmbargoDate.time})
                });

                var publications = [];
                <c:forEach var="publication" items="${project.publications}">
                publications.push({reference: '${publication.reference}', url: '${publication.url}'})
                </c:forEach>
                $.each(publications, function(i, publication) {
                    addPublication(publication);
                });
            });
        </script>
    </jsp:attribute>
    <jsp:attribute name="breadcrumbs">
        <a href="${pageContext.request.contextPath}/">Home</a>
        &rsaquo; <a href="${pageContext.request.contextPath}/projects">Projects</a>
        <c:choose>
        <c:when test="${project.id != null}">
        &rsaquo; <a href="${pageContext.request.contextPath}/projects/${project.id}">${project.title}</a>
        &rsaquo; <span class="active">Update Project</span>
        </c:when>
        <c:otherwise>
        &rsaquo; <span class="active">Create Project</span>
        </c:otherwise>
        </c:choose>
    </jsp:attribute>
    <jsp:body>
        <c:choose>
        <c:when test="${project.id != null}">
            <h1>Update Project</h1>
        </c:when>
        <c:otherwise>
            <h1>Create a New Project</h1>
        </c:otherwise>
        </c:choose>

        <c:if test="${dataSpaceEnabled}">
        <p>The information collected here will be syndicated to the University of Queensland's data collection registry, DataSpace,
        subsequently to the Australian National Data Service, ANDS. A link will be made available to complete the syndication after
        data has been uploaded to OzTrack, and you have the opportunity to edit this information before syndication.</p>
        </c:if>

        <c:choose>
            <c:when test="${project.id != null}">
                <c:set var="method" value="PUT"/>
                <c:set var="action" value="/projects/${project.id}"/>
            </c:when>
            <c:otherwise>
                <c:set var="method" value="POST"/>
                <c:set var="action" value="/projects"/>
            </c:otherwise>
        </c:choose>
        <form:form
            class="form-horizontal form-bordered"
            method="${method}" action="${action}"
            commandName="project" name="project" enctype="multipart/form-data">
            <fieldset>
                <div class="legend">Project Metadata</div>
                <div class="control-group">
                    <label class="control-label" for="title">Title</label>
                    <div class="controls">
                        <form:input path="title" id="title" cssClass="input-xxlarge"/>
                        <div class="help-inline">
                            <div class="help-popover" title="Title">
                                A short title (less than 50 characters if possible) to identify your project in OzTrack.
                            </div>
                        </div>
                        <form:errors path="title" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="description">Description</label>
                    <div class="controls">
                        <form:textarea path="description" id="description" cssStyle="width: 400px; height: 100px;"/>
                        <form:errors path="description" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="spatialCoverageDescr">Location</label>
                    <div class="controls">
                        <form:input path="spatialCoverageDescr" id="spatialCoverageDescr" cssClass="input-xxlarge"/>
                        <div class="help-inline">
                            <div class="help-popover" title="Location Description">
                                The general area of the study, eg. country, state, town.
                            </div>
                        </div>
                        <form:errors path="spatialCoverageDescr" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
            </fieldset>
            <fieldset>
               <div class="legend">Species</div>
                <div class="control-group">
                    <label class="control-label" for="speciesCommonName">Common Name</label>
                    <div class="controls">
                        <form:input path="speciesCommonName" id="speciesCommonName" cssClass="input-xxlarge"/>
                        <form:errors path="speciesCommonName" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="speciesScientificName">Scientific Name</label>
                    <div class="controls">
                        <form:input path="speciesScientificName" id="speciesScientificName" cssClass="input-xxlarge"/>
                        <form:errors path="speciesScientificName" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
            </fieldset>
            <fieldset>
                <div class="legend">Spatial Coordinates</div>
                <div class="control-group" style="margin-bottom: 9px;">
                    <label class="control-label" for="srsIdentifier">SRS Code</label>
                    <div class="controls">
                        <p class="help-block" style="margin: 5px 0 18px 0;">
                            A <strong>Spatial Reference System (SRS)</strong> specifies how the coordinates used to represent
                            spatial data are interpreted as real-world locations on the Earth's surface.
                            The system you select here will be used by the analysis features of OzTrack,
                            such as home range calculators, and will affect the accuracy of results.
                            Click the link below to select an Australian SRS based on the location of your tracking data.
                            If in doubt, enter <tt>EPSG:3577</tt> for the
                            <a target="_blank" href="http://spatialreference.org/ref/epsg/3577/">Australian Albers Equal Area Projection</a>,
                            an Australia-wide system suitable for geoscience and statistical mapping.
                        </p>
                        <form:input id="srsIdentifier" path="srsIdentifier" type="text" class="input-medium"/>
                        <form:errors path="srsIdentifier" element="div" cssClass="help-block formErrors"/>
                        <div class="help-block">
                            <a href="javascript:void(0)" onclick="srsSelector.showDialog();">Select Australian SRS</a><br>
                            <a href="javascript:void(0)" onclick="window.open('http://spatialreference.org/ref/', 'popup', 'width=800,height=600,scrollbars=yes');">Search for international SRS codes</a>
                        </div>
                    </div>
                </div>
                <div class="control-group" style="margin-bottom: 9px;">
                    <label class="control-label" for="crosses180">Crosses 180°</label>
                    <div class="controls">
                        <p class="help-block" style="margin: 5px 0 9px 0;">
                            Check the following box if your project's trajectories cross the antimeridian (180° east or west longitude).
                            If this option is not checked, the resulting geometries may include points near 180° east but then wrap around
                            the globe, through the prime meridian (0° longitude), to include points near 180° west.
                            See the <a target="_blank" href="http://en.wikipedia.org/wiki/180th_meridian">180th meridian</a> article on
                            Wikipedia for more information.
                        </p>
                        <label class="checkbox">
                            <form:checkbox id="crosses180" path="crosses180"/>
                            Crosses 180°
                        </label>
                        <form:errors path="crosses180" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
            </fieldset>
            <fieldset>
                <div class="legend">Publications</div>
                <div class="control-group">
                    <label class="control-label" for="publicationReference">Publication list</label>
                    <div class="controls">
                        <div id="publications">
                        </div>
                        <form:errors path="publications" element="div" cssClass="help-block formErrors" cssStyle="margin: 1em 0;"/>
                        <div>
                            <a class="btn" href="javascript:void(0);" onclick="addPublication();">Add publication</a>
                        </div>
                    </div>
                </div>
            </fieldset>
            <fieldset>
                <div class="legend">Data Availability</div>
                <div class="control-group">
                    <label class="control-label" for="publicationUrl">Access Rights</label>
                    <div class="controls">
                        <label for="accessOpen" class="radio">
                            <form:radiobutton id="accessOpen" path="access" value="OPEN" onclick="
                                $('#embargo-date-control-group').fadeOut();
                                $('#data-licences-control-group').fadeIn();
                            "/>
                            <span class="project-access-open-title">Open Access</span>
                            <div style="margin: 0.5em 0;">
                                Data in this project will be made publicly available in OzTrack.
                                Releasing data under an open-access licence benefits the wider scientific community
                                and increases the potential impact of your research.
                                Many research funding bodies and research organisations require that data from
                                their projects be published and made available for re-use.
                            </div>
                        </label>
                        <label for="accessEmbargo" class="radio <c:if test="${maxEmbargoDate.time < minEmbargoDate.time}">disabled</c:if>">
                            <form:radiobutton id="accessEmbargo" path="access" value="EMBARGO" onclick="
                                $('#embargo-date-control-group').fadeIn();
                                $('#data-licences-control-group').fadeIn();
                            ">
                                <jsp:attribute name="disabled">${maxEmbargoDate.time < minEmbargoDate.time}</jsp:attribute>
                            </form:radiobutton>
                            <span class="project-access-embargo-title">Delayed Open Access</span>
                            <div style="margin: 0.5em 0;">
                                Data in this project will be made publicly available in OzTrack after an embargo period.
                                However, note that metadata including title, description, location, and animal species
                                are made publicly available for all projects in OzTrack.
                            </div>
                            <div style="margin: 0.5em 0;">
                                <c:choose>
                                <c:when test="${beforeNonIncrementalEmbargoDisableDate}">
                                Note: maximum embargo period is ${maxEmbargoYears} years from the project's creation date.
                                </c:when>
                                <c:otherwise>
                                The embargo period can be renewed annually up to a maximum of ${maxEmbargoYears} years.
                                </c:otherwise>
                                </c:choose>
                            </div>
                        </label>
                        <c:if test="${minEmbargoDate.time <= maxEmbargoDate.time}">
                        <div id="embargo-date-control-group" style="margin: 10px 20px 20px 30px;<c:if test="${project.access != 'EMBARGO'}"> display: none;</c:if>">
                            <c:forEach items="${presetEmbargoDates}" var="presetEmbargoDate" varStatus="status">
                            <label for="presetEmbargoDate${status.index}" class="radio <c:if test="${presetEmbargoDate.value.time < minEmbargoDate.time}">disabled</c:if>">
                                <form:radiobutton id="presetEmbargoDate${status.index}" path="embargoDate" >
                                    <jsp:attribute name="value"><fmt:formatDate pattern="${isoDateFormatPattern}" value="${presetEmbargoDate.value}"/></jsp:attribute>
                                    <jsp:attribute name="disabled">${presetEmbargoDate.value.time < minEmbargoDate.time}</jsp:attribute>
                                </form:radiobutton>
                                <span>${presetEmbargoDate.key}</span>
                                <span style="font-size: 11px;">
                                    (expires <fmt:formatDate pattern="${isoDateFormatPattern}" value="${presetEmbargoDate.value}"
                                    /><c:if test="${
                                    !beforeNonIncrementalEmbargoDisableDate &&
                                    (presetEmbargoDate.value.time < maxEmbargoDate.time)}">;
                                    renewable up to <fmt:formatDate pattern="${isoDateFormatPattern}" value="${maxEmbargoDate}"/>
                                    </c:if>)
                                </span>
                            </label>
                            </c:forEach>
                            <label for="otherEmbargoDate" class="radio">
                                <form:radiobutton id="otherEmbargoDate" path="embargoDate" onclick="$('#otherEmbargoDateInput').datepicker('show');">
                                    <jsp:attribute name="value"><fmt:formatDate pattern="${isoDateFormatPattern}" value="${otherEmbargoDate}"/></jsp:attribute>
                                </form:radiobutton>
                                <span>Other date</span>
                                <c:if test="${!beforeNonIncrementalEmbargoDisableDate}">
                                <span style="font-size: 11px;">(before <fmt:formatDate pattern="${isoDateFormatPattern}" value="${maxIncrementalEmbargoDate}"/>)</span>
                                </c:if>
                                <input id="otherEmbargoDateInput" class="input-small datepicker" type="text"
                                    value="<fmt:formatDate pattern="${isoDateFormatPattern}" value="${otherEmbargoDate}"/>"
                                    onclick="$('#otherEmbargoDate').click(); return false;"/>
                            </label>
                            <form:errors path="embargoDate" element="div" cssClass="help-block formErrors"/>
                        </div>
                        </c:if>
                        <c:if test="${beforeClosedAccessDisableDate}">
                        <label for="accessClosed" class="radio">
                            <form:radiobutton id="accessClosed" path="access" value="CLOSED" onclick="
                                $('#embargo-date-control-group').fadeOut();
                                $('#data-licences-control-group').fadeOut();
                            "/>
                            <span class="project-access-closed-title">Closed Access</span>
                            <div style="margin: 0.5em 0;">
                                Data in this project will only be accessible to you.
                                However, note that metadata including title, description, location, and animal species
                                are made publicly available for all projects in OzTrack.
                            </div>
                        </label>
                        </c:if>
                        <form:errors path="access" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <div id="data-licences-control-group" class="control-group" style="<c:if test="${project.access == 'CLOSED'}">display: none;</c:if>">
                    <label class="control-label" for="dataLicenceCopyright">Data Licence</label>
                    <div class="controls">
                        <div style="margin: 0.5em 0 1em 0;">
                            <label>
                                <input id="dataLicenceCopyright" class="dataLicenceCheckbox" type="checkbox" checked="checked" />
                                Data in this project are covered by copyright (i.e. not in the public domain).
                            </label>
                            <label>
                                <input id="dataLicenceAttribution" class="dataLicenceCheckbox" type="checkbox" checked="checked" />
                                Others must acknowledge the author or licence holder of data in this project.
                            </label>
                            <label>
                                <input id="dataLicenceDerivatives" class="dataLicenceCheckbox" type="checkbox" checked="checked" />
                                Others may alter, transform, or build upon data in this project.
                            </label>
                            <label>
                                <input id="dataLicenceNonShareAlike" class="dataLicenceCheckbox" type="checkbox" checked="checked" />
                                Others may licence any derivative data under different licencing terms.
                            </label>
                            <label>
                                <input id="dataLicenceCommercial" class="dataLicenceCheckbox" type="checkbox" checked="checked" />
                                Others may use these data for commercial purposes.
                            </label>
                        </div>
                        <form:errors path="dataLicence" element="div" cssClass="help-block formErrors" cssStyle="margin: 5px 0 1em 0;"/>
                        <input id="dataLicenceIdentifier" name="dataLicenceIdentifier" type="hidden" value="${project.dataLicence.identifier}"/>
                        <c:forEach var="dataLicence" items="${dataLicences}">
                        <div id="dataLicence-${dataLicence.identifier}" class="dataLicence" style="margin: 1.5em 0 0 0; display: none;">
                            <a target="_blank" href="${dataLicence.infoUrl}">
                                <img src="${pageContext.request.scheme}://${fn:substringAfter(dataLicence.imageUrl, '://')}" />
                            </a>
                            <div style="margin: 0.5em 0px; font-weight: bold;">
                                ${dataLicence.title}
                            </div>
                            <div style="margin: 0.5em 0 0 0;">
                                <span>${dataLicence.description}</span>
                                <a target="_blank" href="${dataLicence.infoUrl}">More information</a>
                            </div>
                        </div>
                        </c:forEach>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="publicationUrl">Rights Statement</label>
                    <div class="controls">
                        <p class="help-block" style="margin: 5px 0 1em 0;">
                            If your project requires a statement about the intellectual property rights held in
                            or over a collection, please enter this here. In particular, if data are the
                            property of an institution or someone other than yourself, an appropriate
                            copyright notice should be provided.
                        </p>
                        <form:textarea path="rightsStatement" cssStyle="width: 400px; height: 100px;" placeholder="e.g. Copyright ${currentUser.organisation} ${currentYear}"/>
                        <form:errors path="rightsStatement" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
            </fieldset>
            <div class="form-actions">
                <input class="btn btn-primary" type="submit" value="${(project.id != null) ? 'Update Project' : 'Create Project'}" />
                <c:choose>
                <c:when test="${project.id != null}">
                <a class="btn" href="${pageContext.request.contextPath}/projects/${project.id}">Cancel</a>
                </c:when>
                <c:otherwise>
                <a class="btn" href="${pageContext.request.contextPath}/projects">Cancel</a>
                </c:otherwise>
                </c:choose>
            </div>
        </form:form>
    </jsp:body>
</tags:page>
