<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<%@ attribute name="project" type="org.oztrack.data.model.Project" required="true" %>
<div class="sidebarMenu">
    <ul>
        <li id="projectMenuDetails"><a href="<c:url value="/projects/${project.id}"/>">Project Details</a></li>
        <sec:authorize access="#project.global or hasPermission(#project, 'read')">
        <li id="projectMenuAnalysis"><a href="<c:url value="/projects/${project.id}/analysis"/>">View Tracks</a></li>
        <li id="projectMenuSearch"><a href="<c:url value="/projects/${project.id}/search"/>">View Raw Data</a></li>
        </sec:authorize>
        <sec:authorize access="hasPermission(#project, 'write')">
        <li id="projectMenuUploads"><a href="<c:url value="/projects/${project.id}/datafiles"/>">Data Uploads</a></li>
        <li id="projectMenuCleanse"><a href="<c:url value="/projects/${project.id}/cleanse"/>">Data Cleansing</a></li>
        </sec:authorize>
    </ul>
</div>
