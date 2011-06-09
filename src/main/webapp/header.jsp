<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="form" uri="http://www.springframework.org/tags/form" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<html>
<head>
    <title>OzTrack</title>
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
    <link rel="stylesheet" type="text/css" href="css/oztrack.css"/>
    <link rel="stylesheet" type="text/css" href="css/formalize.css"/>
    <link href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/base/jquery-ui.css" rel="stylesheet" type="text/css"/>
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js">;</script>
    <script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>
    <script type="text/javascript" src="js/oztrack.js"></script>
    <script type="text/javascript" src="js/oztrackmaps.js"></script>
    <script type="text/javascript" src="js/jquery/jquery.formalize.min.js"></script>
    <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/jquery-ui.min.js"></script>
    <script src="http://google-maps-utility-library-v3.googlecode.com/svn/trunk/keydragzoom/src/keydragzoom_packed.js"></script>
</head>

<body>

<div id="container">
<div id="top_header">
    <img src="images/header_croc.jpg" align="right"/>
</div>


<div id="nav">
<ul id="navMenu">

<li><a id="navHome" href="<c:url value="home"/>">Home</a></li>

<c:choose>
 <c:when test="${currentUser != null}">
    <li><a id="navTrack" class="menuParent" href="#">Tracking Projects</a>
        <ul>
            <li><a href="<c:url value="projects"/>">Project List</a></li>
            <li><a href="<c:url value="projectadd"/>">Create New Project</a></li>
        </ul>
    </li>
 </c:when>
<c:otherwise>
    <li><a id="navTrack" href="<c:url value="login"/>">Tracking Projects</a></li>
</c:otherwise>
</c:choose>

<li><a id="navSighting" href="<c:url value="sighting"/>">Animal Sightings</a></li>
<li><a id="navAbout" href="<c:url value="about"/>">About</a></li>
<li><a id="navContact" href="<c:url value="contact"/>">Contact</a></li>
</ul>
</div>


<div id="crumbs">
    <a id="homeUrl" href="<c:url value="home"/>">Home</a>
</div>

<div id="login">
<c:set var="thisURL" value="${pageContext.request.requestURL}"/>
<c:if test="${!fn:contains(thisURL,'login') && !fn:contains(thisURL,'register')}">
    <c:choose>
    <c:when test="${currentUser != null}">
      Welcome, <c:out value="${currentUser.firstName}"/>
      &nbsp;|&nbsp;
      <a href=#>Profile</a>
      &nbsp;|&nbsp;
      <a href="<c:url value="logout"/>">Logout</a>
    </c:when>
    <c:otherwise>
      <a href="<c:url value="login"/>">Login</a> or <a href="<c:url value="register"/>">Register</a>
    </c:otherwise>
    </c:choose>

</c:if>
</div>

 <div id="main">


<div id="leftMenu">

<c:if test="${fn:contains(thisURL,'project') && !fn:contains(thisURL,'projectdetail')&& !fn:contains(thisURL,'projectanimals') && !fn:contains(thisURL,'projectreceivers')&& !fn:contains(thisURL,'alloztrackprojects')}">
    <ul>
    <li><a href="<c:url value="projects"/>">Project List</a></li>
    <li><a href="<c:url value="projectadd"/>">Create New Project</a></li>
    </ul>
</c:if>

<c:if test="${fn:contains(thisURL,'projectdetail') || fn:contains(thisURL,'searchform') || fn:contains(thisURL,'datafiles') || fn:contains(thisURL,'projectanimals') || fn:contains(thisURL,'projectreceivers') || fn:contains(thisURL,'datafileadd')|| fn:contains(thisURL,'datafiledetail')|| fn:contains(thisURL,'animalform')|| fn:contains(thisURL,'receiverform')}">
    <c:if test="${project.title != null}">
        <ul>
          <li><a href="<c:url value="projectdetail"/>">Project Details</a></li>
          <li><a href="<c:url value="searchform"/>">Analysis Tools</a></li>
          <li><a href="<c:url value="datafiles"/>">Data Uploads</a></li>
          <li><a href="<c:url value="projectanimals"/>">Animals</a></li>
          <li><a href="<c:url value="projectreceivers"/>">Receivers</a></li>
        </ul>

    </c:if>
</c:if>


<div id="logos">
<a href="http://ands.org.au/"/><img src="images/ands-logo.png"/></a>
<a href="http://itee.uq.edu.au/~eresearch/"/><img src="images/uq_logo.png"/></a>
</div>
</div>

<div id="content">

<!--
<c:forEach items='${sessionScope}' var='p'>
<ul>
<li>Parameter Name: <c:out value='${p.key}'/></li>
<li>Parameter Value: <c:out value='${p.value}'/></li>
</ul>
</c:forEach>
-->



