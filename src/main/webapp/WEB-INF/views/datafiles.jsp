<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="tags" %>
<c:set var="dateFormatPattern" value="dd/MM/yyyy"/>
<tags:page title="${project.title}: Data Uploads">
    <jsp:attribute name="head">
        <script type="text/javascript"> 
            projectPage = true;
            $(document).ready(function() {
                $('#navTrack').addClass('active');
            });
        </script>
    </jsp:attribute>
    <jsp:attribute name="breadcrumbs">
        <a href="<c:url value="/"/>">Home</a>
        &rsaquo; <a href="<c:url value="/projects"/>">Animal Tracking</a>
        &rsaquo; <a href="<c:url value="/projectdetail?id=${project.id}"/>">${project.title}</a>
        &rsaquo; <span class="active">Data Uploads</span>
    </jsp:attribute>
    <jsp:body>
		<h1 id="projectTitle"><c:out value="${project.title}"/></h1>
		<h2>Data Uploads</h2>
		
		<c:choose>
		 <c:when test="${(empty dataFileList)}">
			<p>This project has no data to work with. You might like to <a href="<c:url value='/datafileadd'>
			    <c:param name="project_id" value="${project.id}"/>
			</c:url>">upload a data file.</a></p>
			<a class="oztrackButton" id="pageRefresh" href="#">Refresh</a>
		 </c:when>
		 <c:otherwise>
		    
		    <p><c:out value="${fn:length(dataFileList)}"/> data file(s) found.</p>
		
				<p><a class="oztrackButton" href="<c:url value='/datafileadd'>
			        <c:param name="project_id" value="${project.id}"/>
			    </c:url>" >Add a Datafile</a>
				<a class="oztrackButton" id="pageRefresh" href="#">Refresh</a></p>
				
				<p><c:out value="${errorStr}"/></p>
				
				<table class="dataTable" id="dataFileStatusTable">
				
				    <tr>
				        <th>File Name</th>
				        <th>Detection Date Range</th>
				        <th>Upload Date</th>
				        <th>File Status</th>
				    </tr>
				
				    <c:forEach items="${dataFileList}" var="dataFile">
				        <tr>
				            <td><c:out value="${dataFile.userGivenFileName}"/></td>
				            <td><c:if test="${fn:contains(dataFile.status,'COMPLETE')}">
				            	<fmt:formatDate pattern="${dateFormatPattern}" value="${dataFile.firstDetectionDate}"/> to <fmt:formatDate pattern="${dateFormatPattern}" value="${dataFile.lastDetectionDate}"/>
				            	</c:if>
				             </td>	
				            <td><fmt:formatDate pattern="${dateFormatPattern}" value="${dataFile.createDate}"/>
				            <td>
				                <a href="<c:url value="/datafiledetail">
							        <c:param name="project_id" value="${project.id}"/>
							        <c:param name="datafile_id" value="${dataFile.id}"/>
						            </c:url>"><c:out value="${dataFile.status}"/></a>
				            </td>
						</tr>
				    </c:forEach>
				</table>
			</c:otherwise>
		</c:choose>	
    </jsp:body>
</tags:page>