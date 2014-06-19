<!--- Document Information -----------------------------------------------------

Title:      ExperimentService.cfc

Author:     Toby Reiter
Email:      tobyhreiter@gmail.com

company:    CamelWalkDev
Website:    n/a

Purpose:    Summary: Provides skeleton for running experiment, and returning results
			
			Full: Experiments are performed in a laboratory, and then the results are compiled 
			for peer review. Some data is purely observational (e.g. number of bacteria in a 
			colony). Other data points are based on a combination of observed data points 
			(number of bacteria in colony A / number of bacteria in colony B).  The scientists have defined 
			variables for each variable the are tracking and for each computed variable they are 
			tracking. For the sake of this program, the scientists are tracking all variables 
			instantaneously every minute. Each "snapshot" is referred to as an observation. After 
			an hour of observations, the scientists then run an analysis on the data, which includes
			generating values for all of the computed variables, and saving these as additional data 
			points tied to that particular observation.

Usage:      Exists as a service layer of the domain model; instantiated by a dependency injection 
			framework and accessed through a controller object

Modification Log:

Name			Date			Description
================================================================================
Toby Reiter		06/19/2014		Created
------------------------------------------------------------------------------->

<cfcomponent displayname="ExperimentService" output="false" hint="I provide a service for generating computed data points that are based on computed variables">

	<cffunction name="init" access="public" returnType="ExperimentService" output="false">
		<cfargument name="ComputedVariableService" type="any" required="true">
		<cfargument name="ExperimentsGateway" type="any" required="true">
		<cfargument name="VariablesGateway" type="any" required="true">
		<cfargument name="ObservationsGateway" type="any" required="true">
		<cfargument name="DataPointsGateway" type="any" required="true">

		<cfset variables.ComputedVariableService = arguments.ComputedVariableService />
		<cfset variables.ExperimentsGateway = arguments.ExperimentsGateway />
		<cfset variables.VariablesGateway = arguments.VariablesGateway />
		<cfset variables.ObservationsGateway = arguments.ObservationsGateway />
		<cfset variables.DataPointsGateway = arguments.DataPointsGateway />
		<cfreturn this>
	</cffunction>

	<!--- PUBLIC METHODS --->
	<cffunction access="public" returntype="void" name="setup" output="false"
			hint="I set up the database">

		<cfset variables.ExperimentsGateway.createExperimentsTable() />
		<cfset variables.VariablesGateway.createVariablesTable() />
		<cfset variables.ObservationsGateway.createObservationsTable() />
		<cfset variables.DataPointsGateway.createDataPointsTable() />		
	</cffunction>

	<cffunction access="public" returntype="void" name="run" output="false"
			hint="I compute all computed data points">

		<!--- Retrieve all variables in the system that are actual observed data points, and not computed ---> 
		<cfset var qNonComputedVariables = variables.VariablesGateway.getNonComputedVariables(argumentcollection = arguments) />
		<!--- Create observation snapshots, in 1 minute increments --->
		<cfset variables.ObservationsGateway.populateObservations() />
		<!--- Create random data points for the bacteria colonies for each observation increment --->
		<cfset variables.DataPointsGateway.populateDataPoints(ValueList(qNonComputedVariables.name)) />
		
		<!--- Calculate computed variables --->
		<cfset variables.ComputedVariableService.computeValues() />		
	</cffunction>
	
	<cffunction access="public" returntype="query" name="getResults" output="false" 
		hint="I get the results back from the experiment (i.e. the data points)">
				
		<cfreturn variables.DataPointsGateway.getDataPoints() />
	</cffunction>
</cfcomponent>