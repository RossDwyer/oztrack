<%@ include file="header.jsp" %>


<h1 id="projectTitle"><c:out value="${project.title}"/></h1>
<h2>Search Project Data</h2>

<form:form commandName="searchQuery" method="POST" name="searchQuery">


    <div>
    <label for="projectAnimalId">Animal Id:</label>
    <form:input path="projectAnimalId" id="projectAnimalId"/>
    <form:errors path="projectAnimalId" cssClass="formErrors"/>
    </div>

    <c:if test="${project.projectType == 'PASSIVE_ACOUSTIC'}">
        <div>
        <label for="receiverOriginalId">Receiver Id:</label>
        <form:input path="receiverOriginalId" id="receiverOriginalId"/>
        <form:errors path="receiverOriginalId" cssClass="formErrors"/>
        </div>
    </c:if>

    <div>
    <label for="fromDate">Date From:</label>
    <form:input path="fromDate" id="fromDatepicker"/>
    <form:errors path="fromDate" cssClass="formErrors"/>
    </div>

    <div>
    <label for="toDate">Date To:</label>
    <form:input path="toDate" id="toDatepicker"/>
    <form:errors path="toDate" cssClass="formErrors"/>
    </div>

    <div>
    <label for="sortField">Sort by:</label>
    <form:select path="sortField">
        <form:option value="Animal"/>
         <c:if test="${project.projectType == 'PASSIVE_ACOUSTIC'}"><form:option value="Receiver"/> </c:if>
        <form:option value="Detection Time"/>
    </form:select>
    </div>

    <div><input type="submit" value="Search"/></div>

</form:form>


<div class="dataTableNav">
<c:out value="${offset+1}"/> to <c:out value="${offset+nbrObjectsThisPage}"/> of <c:out value="${totalCount}"/> results.
<br>

<c:choose>
 <c:when test="${offset > 0}">
    <a href="<c:url value="searchform"><c:param name="offset" value="${0}"/></c:url>">&lt;&lt;</a>
    &nbsp;&nbsp;
    <a href="<c:url value="searchform"><c:param name="offset" value="${offset-nbrObjectsPerPage}"/></c:url>">&lt;</a>
 </c:when>
 <c:otherwise>&lt;&lt;&nbsp;&nbsp;&lt;</c:otherwise>
</c:choose>
&nbsp;&nbsp;

<c:choose>
 <c:when test="${offset < totalCount - (totalCount % nbrObjectsPerPage)}">
    <a href="<c:url value="searchform"><c:param name="offset" value="${offset+nbrObjectsThisPage}"/></c:url>">&gt;</a>
    &nbsp;&nbsp;
    <a href="<c:url value="searchform"><c:param name="offset" value="${totalCount - (totalCount % nbrObjectsPerPage)}"/></c:url>">&gt;&gt;</a>
 </c:when>
 <c:otherwise>&gt;&nbsp;&nbsp;&gt;&gt;</c:otherwise>
</c:choose>

</div>

<c:if test="${acousticDetectionsList != null}">

    <br>
    <p align="center"><a href="#">Paginate Functionality</a> | <a class="oztrackButton" href="#">Export to File</a>
    </p><br>

    <table class="dataTable">

    <tr>
        <th>Date/Time</th>
        <th>Animal</th>
        <th>Receiver</th>
        <th>Sensor 1</th>
        <th>Units 1</th>
        <th>Sensor 2</th>
        <th>Units 2</th>
        <th>DataFile Upload</th>
    </tr>
    <c:forEach items="${acousticDetectionsList}" var="detection">
    <tr>
        <td><fmt:formatDate value="${detection.detectionTime}" type="both" pattern="dd-MM-yyyy H:m:s"/></td>
        <td><c:out value="${detection.animal.projectAnimalId}"/></td>
        <td><c:out value="${detection.receiverDeployment.originalId}"/></td>
        <td><c:out value="${detection.sensor1Value}"/></td>
        <td><c:out value="${detection.sensor1Units}"/></td>
        <td><c:out value="${detection.sensor2Value}"/></td>
        <td><c:out value="${detection.sensor2Units}"/></td>
        <td><c:out value="${detection.dataFile.uploadDate}"/></td>
    </tr>
    </c:forEach>
    </table>
</c:if>

<c:if test="${positionFixList != null}">

    <br>
    <p align="center"><a href="#">Paginate Functionality</a> | <a class="oztrackButton" href="#">Export to File</a>
    </p><br>
     <table class="dataTable">

    <tr>
        <th>Date/Time</th>
        <th>Animal</th>
        <th>Latitude</th>
        <th>Longitude</th>
        <th>Sensor 1</th>
        <th>Units 1</th>
        <th>Sensor 2</th>
        <th>Units 2</th>
        <th>DataFile Upload</th>
    </tr>
    <c:forEach items="${positionFixList}" var="detection">
    <tr>
        <td><fmt:formatDate value="${detection.detectionTime}" type="both" pattern="dd-MM-yyyy H:m:s"/></td>
        <td><c:out value="${detection.animal.id}"/></td>
        <td><c:out value="${detection.latitude}"/></td>
        <td><c:out value="${detection.longitude}"/></td>
        <td><c:out value="${detection.sensor1Value}"/></td>
        <td><c:out value="${detection.sensor1Units}"/></td>
        <td><c:out value="${detection.sensor2Value}"/></td>
        <td><c:out value="${detection.sensor2Units}"/></td>
        <td><c:out value="${detection.dataFile.uploadDate}"/></td>
    </tr>
    </c:forEach>
    </table>

 </c:if>
<%@ include file="footer.jsp" %>
