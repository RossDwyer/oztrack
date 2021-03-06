<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="org.oztrack.app.OzTrackApplication" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="tags" %>
<c:set var="aafEnabled"><%= OzTrackApplication.getApplicationContext().isAafEnabled() %></c:set>
<c:set var="dataSpaceEnabled"><%= OzTrackApplication.getApplicationContext().isDataSpaceEnabled() %></c:set>
<c:set var="title" value="${(user.id != null) ? 'User Profile' : 'Register'}"/>
<tags:page title="${title}">
    <jsp:attribute name="description">
        <c:choose>
        <c:when test="${user.id != null}">
            Update your OzTrack account.
        </c:when>
        <c:otherwise>
            Register a new OzTrack account.
        </c:otherwise>
        </c:choose>
    </jsp:attribute>
    <jsp:attribute name="tail">
        <script type="text/javascript">
            $(document).ready(function() {
                $('#navHome').addClass('active');
            });
        </script>
    </jsp:attribute>
    <jsp:attribute name="breadcrumbs">
        <a href="${pageContext.request.contextPath}/">Home</a>
        &rsaquo; <span class="active">${title}</span>
    </jsp:attribute>
    <jsp:body>
        <h1>${title}</h1>

        <c:if test="${aafEnabled && (user.id == null) && (empty user.aafId)}">
        <form class="form-vertical form-bordered" style="margin: 18px 0;">
            <fieldset>
                <div class="legend">Register using AAF</div>
                <div style="margin: 18px 0;">
                    <p>
                        Click here to register using your <a target="_blank" href="http://www.aaf.edu.au/">Australian Access Federation (AAF)</a> profile.
                    </p>
                    <p>
                        You will be redirected to your home institution's login page.
                    </p>
                </div>
            </fieldset>
            <div class="form-actions">
                <a class="btn btn-primary" href="${pageContext.request.contextPath}/login/shibboleth">Register using AAF</a>
            </div>
        </form>
        </c:if>

        <form:form
            cssClass="form-horizontal form-bordered"
            commandName="user"
            method="${(user.id == null) ? 'POST' : 'PUT'}"
            action="${(user.id == null) ? '/users' : '/users/'}${(user.id == null) ? '' : user.id}"
            style="margin: 18px 0;">
            <fieldset>
                <div class="legend">${(user.id != null) ? 'Update user profile' : 'Register new profile'}</div>
                <c:if test="${aafEnabled && ((not empty user.aafId) || (user.id != null))}">
                <div class="control-group">
                    <label class="control-label" for="aafId">AAF ID:</label>
                    <div class="controls">
                        <c:choose>
                        <c:when test="${not empty user.aafId}">
                            <input type="text" name="aafId" id="aafId" readonly="readonly" value="${user.aafId}" />
                            <a class="btn" href="javascript:void($('#aafId').val(''));">Remove AAF ID</a>
                        </c:when>
                        <c:otherwise>
                            <a class="btn" href="${pageContext.request.contextPath}/login/shibboleth">Link profile with AAF ID</a>
                        </c:otherwise>
                        </c:choose>
                        <div class="help-inline">
                            <div class="help-popover" title="AAF ID">
                                Providing your Australian Access Federation (AAF) ID allows you to login
                                through your home institution as an alternative to using your OzTrack
                                username and password.<br>
                                <br>
                                Your AAF ID is made up of your username and the domain name for your
                                institution separated by '@'. For example, if you are a UQ staff member
                                with username 'uqjsmith', your ID is 'uqjsmith@uq.edu.au'.
                            </div>
                        </div>
                        <form:errors path="aafId" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                </c:if>
                <div class="control-group">
                    <label class="control-label" for="username">Username:</label>
                    <div class="controls">
                        <form:input path="username" id="username"/>
                        <div class="help-inline">
                            <div class="help-popover" title="Username">
                                This will be the name that you log on to OzTrack with.
                            </div>
                        </div>
                        <form:errors path="username" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="password">Password:</label>
                    <div class="controls">
                        <input type="password" name="password" id="password"/>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="password">Password (confirm):</label>
                    <div class="controls">
                        <input type="password" name="password2" id="password2"/>
                        <form:errors path="password" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="title">Title:</label>
                    <div class="controls">
                        <form:input path="title" id="title" />
                        <form:errors path="title" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="firstname">First Name:</label>
                    <div class="controls">
                        <form:input path="firstName" id="firstname"/>
                        <form:errors path="firstName" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="lastname">Last Name:</label>
                    <div class="controls">
                        <form:input path="lastName" id="lastname"/>
                        <form:errors path="lastName" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="organisation">Organisation:</label>
                    <div class="controls">
                        <form:input path="organisation" id="organisation"/>
                        <div class="help-inline">
                            <div class="help-popover" title="Organisation">
                                <p>Please give the name of the organisation in full.</p>
                                <c:if test="${dataSpaceEnabled}">
                                <p>This field is used when project metadata are syndicated to UQ DataSpace and ANDS.</p>
                                </c:if>
                            </div>
                        </div>
                        <form:errors path="organisation" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="email">Email:</label>
                    <div class="controls">
                        <form:input path="email" id="email"/>
                        <form:errors path="email" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="dataSpaceAgentDescription">Short Bio:</label>
                    <div class="controls">
                        <form:textarea path="dataSpaceAgentDescription" id="dataSpaceAgentDescription" cssStyle="width: 400px; height: 100px;"/>
                        <div class="help-inline">
                            <div class="help-popover" title="Short Bio">
                                <p>Briefly describe yourself and your research interests.</p>
                                <c:if test="${dataSpaceEnabled}">
                                <p>This field is used when project metadata are syndicated to UQ DataSpace and ANDS.
                                See examples at <a target="_blank" href="http://dataspace.uq.edu.au/agents">http://dataspace.uq.edu.au/agents</a>.</p>
                                </c:if>
                            </div>
                        </div>
                        <form:errors path="dataSpaceAgentDescription" element="div" cssClass="help-block formErrors"/>
                    </div>
                </div>
                <c:if test="${not empty recaptchaHtml}">
                <div class="control-group">
                    <label class="control-label" for="recaptcha_response_field">Verification:</label>
                    <div class="controls">
                        ${recaptchaHtml}
                        <c:if test="${not empty recaptchaError}">
                        <div class="help-block formErrors">
                            ${recaptchaError}
                        </div>
                        </c:if>
                    </div>
                </div>
                </c:if>
            </fieldset>
            <div class="form-actions">
                <input class="btn btn-primary" type="submit" value="${(user.id != null) ? 'Update' : 'Register'}" />
            </div>
        </form:form>
    </jsp:body>
</tags:page>
