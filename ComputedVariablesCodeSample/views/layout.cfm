<!--- Document Information -----------------------------------------------------

Title:      layout.cfm

Author:     Toby Reiter
Email:      tobyhreiter@gmail.com

company:    CamelWalkDev
Website:    n/a

Purpose:    Summary: A simple layout for the site
			
Usage:      Included by the controller file

Modification Log:

Name			Date			Description
================================================================================
Toby Reiter		06/19/2014		Created
------------------------------------------------------------------------------->
<cfcontent reset="true"><!DOCTYPE html>
<html>
	<head>
		<title>Experiment: Computed Variables Code Sample</title>
		<link rel="stylesheet" href="assets/style.css" />
	</head>
	<body><cfoutput>#request.output#</cfoutput></body>
</html>