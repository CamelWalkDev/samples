<!--- Document Information -----------------------------------------------------

Title:      controller.cfm

Author:     Toby Reiter
Email:      tobyhreiter@gmail.com

company:    CamelWalkDev
Website:    n/a

Purpose:    A very simple controller
			
Usage:      Run as is from a URL

Modification Log:

Name			Date			Description
================================================================================
Toby Reiter		06/19/2014		Created
------------------------------------------------------------------------------->

<cftry>
	<cfset variables.ExperimentService = application.ColdspringBeanFactory.getBean('ExperimentService') />
	
	<cfset variables.ExperimentService.setup() />
	<cfset variables.ExperimentService.run() />
	<cfset variables.qResults = variables.ExperimentService.getResults() />

	<cfinclude template="views/view.cfm" />
	<cfinclude template="views/layout.cfm" />
	
<cfcatch>
	<cfdump var="#cfcatch#">
	<cfabort>

</cfcatch>
</cftry>