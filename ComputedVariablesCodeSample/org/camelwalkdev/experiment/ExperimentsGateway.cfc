<!--- Document Information -----------------------------------------------------

Title:      ExperimentsGateway.cfc

Author:     Toby Reiter
Email:      tobyhreiter@gmail.com

company:    CamelWalkDev
Website:    n/a

Purpose:    Summary: Provides gateway to observation records
			
			Full: (See ComputedVariableService.cfc for complete explanation of scenario).  Experiments 
			are snapshot moments during the experiment

Usage:      Exists as an object in the domain model; instantiated by a dependency injection 
			framework and accessed through service layer objects

Modification Log:

Name			Date			Description
================================================================================
Toby Reiter		06/19/2014		Created
------------------------------------------------------------------------------->

<cfcomponent displayname="ExperimentsGateway" output="false" hint="I provide a gateway for retrieving observation records">

	<!--- Initializing the Gateway --->
	<cffunction name="init" access="public" returnType="ExperimentsGateway" output="false">
		<cfargument name="dsn" type="any" required="true">

		<cfset variables.instance.dsn = arguments.dsn />

		<cfreturn this>
	</cffunction>

	<!--- PACKAGE METHODS --->
	<cffunction access="package" returntype="void" name="createExperimentsTable" output="false" 
		hint="I create the experiments table">

		<cfset var createExperimentsTable = 0 />
		<cfset var populateExperimentsTable = 0 />

		<!--- Create the experiments table, dropping any existing table --->
		<cfquery name="createExperimentsTable" datasource="#variables.instance.dsn#">
			if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Experiments')
    			drop table Experiments;
	
			create table Experiments (
			    id int identity(1,1) not null,
			    name nvarchar(255) not null,
			    description nvarchar(max) null
			)
		</cfquery>		

		<!--- Populate the experiments table --->
		<cfquery name="populateExperimentsTable" datasource="#variables.instance.dsn#">
			INSERT INTO [dbo].[Experiments]([name], [description])
			  VALUES('Sample Experiment', 'This is the result of populating the experiment with random data for each observation increment.')
		</cfquery>		

	</cffunction>	
</cfcomponent>