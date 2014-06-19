<!--- Document Information -----------------------------------------------------

Title:      VariablesGateway.cfc

Author:     Toby Reiter
Email:      tobyhreiter@gmail.com

company:    CamelWalkDev
Website:    n/a

Purpose:    Summary: Provides gateway to variable records
			
			Full: (See ExperimentService.cfc for complete explanation of scenario).  Variables are 
			a either an observable value (number of bacteria in water, concentration of salt in water) or 
			a computed variable (number of bacteria in water/concentration of salt in water). For the purposes
			of this scenario, only methods relating to computing variables have been implemented

Usage:      Exists as an object in the domain model; instantiated by a dependency injection 
			framework and accessed through service layer objects

Modification Log:

Name			Date			Description
================================================================================
Toby Reiter		06/19/2014		Created
------------------------------------------------------------------------------->

<cfcomponent displayname="VariablesGateway" output="false" hint="I provide a gateway for retrieving variable records">

	<!--- Initializing the Gateway --->
	<cffunction name="init" access="public" returnType="VariablesGateway" output="false">
		<cfargument name="dsn" type="any" required="true">

		<cfset variables.instance.dsn = arguments.dsn />

		<cfreturn this>
	</cffunction>

	<!--- PACKAGE METHODS --->
	<cffunction access="package" returntype="void" name="createVariablesTable" output="false" 
		hint="I create the variables table, and populate it with default variables">

		<cfset var createVariablesTable = 0 />
		<cfset var populateVariablesTable = 0 />
		
		<!--- create the table (dropping it if it already exists) --->
		<cfquery name="createVariablesTable" datasource="#variables.instance.dsn#">
			if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Variables')
    			drop table Variables;
	
			create table Variables (
			    id int identity(1,1) not null,
			    name nvarchar(255) not null,
			    label nvarchar(255) not null,
			    computation nvarchar(max) null,
			    date_created datetime default(getdate()),
			    date_edited datetime default(getdate()),
			    date_deleted datetime
			)
		</cfquery>		

		<!--- Populate the variables with bacteria variables --->
		<cfquery name="populateVariablesTable" datasource="#variables.instance.dsn#">
			INSERT INTO [dbo].[Variables]([name], [label], [computation])
			  VALUES(N'BactA', N'## of Bacteria in Colony A', NULL);
			INSERT INTO [dbo].[Variables]([name], [label], [computation])
			  VALUES(N'BactB', N'## of Bacteria in Colony B', NULL);
			INSERT INTO [dbo].[Variables]([name], [label], [computation])
			  VALUES(N'TotalBact', N'## of Bacteria in Both Colonies', N':1; + :2;');
			INSERT INTO [dbo].[Variables]([name], [label], [computation])
			  VALUES(N'Smallbact', N'Smallest Bacterial Colony (A or B)', N'min(:1;,:2;)');
			INSERT INTO [dbo].[Variables]([name], [label], [computation])
			  VALUES(N'BactAsPercTotal', N'Percent of Bacteria in Colony A to total', N':1;/(:1; + :2;)');
		</cfquery>		
		
	</cffunction>

	<cffunction access="package" returntype="query" name="getComputedVariables" output="false"
		hint="I get all of the computed variables">

		<cfset var getComputedVariables = 0 />

		<cfquery name="getComputedVariables" datasource="#variables.instance.dsn#">
			SELECT
				Variables.id,
				Variables.name,
				Variables.label,
				Variables.computation
			FROM
				Variables
			WHERE
				Variables.date_deleted IS NULL AND
				Variables.computation IS NOT NULL
		</cfquery>

		<cfreturn getComputedVariables />
	</cffunction>
	
	<!--- This gets all non-computed variables --->
	<cffunction access="package" returntype="query" name="getNonComputedVariables" output="false"
		hint="I get all of the non-computed variables">

		<cfset var getNonComputedVariables = 0 />

		<cfquery name="getNonComputedVariables" datasource="#variables.instance.dsn#">
			SELECT
				Variables.id,
				Variables.name,
				Variables.label,
				Variables.computation
			FROM
				Variables
			WHERE
				Variables.date_deleted IS NULL AND
				Variables.computation IS NULL
		</cfquery>

		<cfreturn getNonComputedVariables />
	</cffunction>		
</cfcomponent>