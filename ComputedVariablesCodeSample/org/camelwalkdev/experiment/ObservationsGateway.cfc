<!--- Document Information -----------------------------------------------------

Title:      ObservationsGateway.cfc

Author:     Toby Reiter
Email:      tobyhreiter@gmail.com

company:    CamelWalkDev
Website:    n/a

Purpose:    Summary: Provides gateway to observation records
			
			Full: (See ComputedVariableService.cfc for complete explanation of scenario).  Observations 
			are snapshot moments during the experiment

Usage:      Exists as an object in the domain model; instantiated by a dependency injection 
			framework and accessed through service layer objects

Modification Log:

Name			Date			Description
================================================================================
Toby Reiter		06/19/2014		Created
------------------------------------------------------------------------------->

<cfcomponent displayname="ObservationsGateway" output="false" hint="I provide a gateway for retrieving observation records">

	<!--- Initializing the Gateway --->
	<cffunction name="init" access="public" returnType="ObservationsGateway" output="false">
		<cfargument name="dsn" type="any" required="true">

		<cfset variables.instance.dsn = arguments.dsn />

		<cfreturn this>
	</cffunction>

	<!--- PACKAGE METHODS --->
	<cffunction access="package" returntype="void" name="createObservationsTable" output="false" 
		hint="I create the observations table">

		<cfset var createObservationsTable = 0 />
		
		<cfquery name="createObservationsTable" datasource="#variables.instance.dsn#">
			if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Observations')
    			drop table Observations;
	
			create table Observations (
			    id int identity(1,1) not null,
			    experiment_id int not null,
			    time_stamp  datetime not null
			)
		</cfquery>		
	</cffunction>
	
	<cffunction access="package" returntype="void" name="populateObservations" output="false" 
		hint="I populate observations for the experiment">
		
		<cfset var populateObservations = 0 />
		
		<cfquery name="populateObservations" datasource="#variables.instance.dsn#">
			DELETE FROM Observations;
			
			DECLARE @Loop INT = 59;
			
			INSERT INTO Observations (experiment_id,time_stamp)
			SELECT
			    (SELECT max(id) from Experiments),
			    '1/1/2014 09:00';
			
			WHILE @Loop > 0
			BEGIN
			    INSERT INTO Observations (experiment_id,time_stamp)
			    SELECT
			        (SELECT max(id) from Experiments),
			        DateAdd(n,1,(select max(time_stamp) from Observations));
			
			    SET @Loop = @Loop - 1
			END
		</cfquery>
	</cffunction>
</cfcomponent>