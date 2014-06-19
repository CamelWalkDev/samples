<!--- Document Information -----------------------------------------------------

Title:      DataPointsGateway.cfc

Author:     Toby Reiter
Email:      tobyhreiter@gmail.com

company:    CamelWalkDev
Website:    n/a

Purpose:    Summary: Provides gateway to data point records
			
			Full: (See ComputedVariableService.cfc for complete explanation of scenario).  Data points are
			the value of a given variable (see VariablesGateway.cfc) at a particular time (this is called an observation).

Usage:      Exists as an object in the domain model; instantiated by a dependency injection 
			framework and accessed through service layer objects

Modification Log:

Name			Date			Description
================================================================================
Toby Reiter		06/19/2014		Created
------------------------------------------------------------------------------->

<cfcomponent displayname="DataPointsGateway" output="false" hint="I provide a gateway for retrieving data point records">

	<!--- Initializing the Gateway --->
	<cffunction name="init" access="public" returnType="DataPointsGateway" output="false">
		<cfargument name="dsn" type="any" required="true">

		<cfset variables.instance.dsn = arguments.dsn />

		<cfreturn this>
	</cffunction>

	<!--- PACKAGE METHODS --->
	<cffunction access="package" returntype="void" name="createDataPointsTable" output="false" 
		hint="I create the data points table">

		<cfset var createDataPointsTable = 0 />
		
		<cfquery name="createDataPointsTable" datasource="#variables.instance.dsn#">
			if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'DataPoints')
    			drop table DataPoints;
	
			create table DataPoints (
			    id int identity(1,1) not null,
			    variable_id int not null,
			    observation_id int not null,
			    value   float null,
			    date_created datetime default(getdate()),
			    date_edited datetime default(getdate())
			)
		</cfquery>		
	</cffunction>
	
	<cffunction access="package" returntype="void" name="populateDataPoints" output="false" 
		hint="I populate data points for the experiment">
		<cfargument name="variable_names" type="string" hint="A list of variable labels from the variables table" />
		
		<cfset var populateObservations = 0 />
		<cfset var populateDataPoints = 0 />
				
		<cfquery name="populateDataPoints" datasource="#variables.instance.dsn#">
			DELETE FROM DataPoints;
			
			INSERT INTO DataPoints (variable_id,observation_id,value)
			SELECT
			    Variables.id as variable_id,
			    Observations.id as observation_id,
			    /* This allows for having a randomly generated number for each row; the 1000 sets our range for the random number, and then we're adding this to 2000, see http://stackoverflow.com/a/1045162/3298457 */
			    CAST(2000 + ABS(CHECKSUM(NewId())) % 1000 as int)
			FROM
			    Observations CROSS JOIN Variables
			WHERE
			    Variables.name IN (<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.variable_names#" list="true" />)
		</cfquery>
	</cffunction>

	<cffunction access="package" returntype="query" name="getDataPoints" output="false" 
		hint="I return data points matching the given criteria">
		<cfargument name="variable_id" type="numeric" hint="A primary key of the variables table" />
		<cfargument name="variable_ids" type="string" hint="A list of primary keys of the variables table" />
		

		<cfset var getDataPoints = 0 />
		
		<cfquery name="getDataPoints" datasource="#variables.instance.dsn#">
			SELECT
				Experiments.name as experiment_name,
				Experiments.description as experiment_description,
				Observations.time_stamp,
				Observations.experiment_id,
				DataPoints.id as datapoint_id,
				DataPoints.observation_id,
				DataPoints.variable_id,
				DataPoints.value,
				Variables.name as variable_name,
				Variables.label as variable_label
			FROM
				DataPoints INNER JOIN Observations
					ON DataPoints.observation_id = Observations.id
				INNER JOIN Variables
					ON DataPoints.variable_id = Variables.id
				INNER JOIN Experiments
					ON Observations.experiment_id = Experiments.id
			WHERE
				<cfif structKeyExists(arguments,'variable_id') AND len(trim(arguments.variable_id))>
					variable_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.variable_id#" />
				<cfelseif structKeyExists(arguments,'variable_ids') AND len(trim(arguments.variable_ids))>
					variable_id IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.variable_ids#" list="true"/>)
				<cfelse>
					1=1
				</cfif>
			ORDER BY
				Observations.id,
				Variables.id
		</cfquery>
		
		<cfreturn getDataPoints />
	</cffunction>

	<cffunction access="package" returntype="void" name="deleteForVariable" output="false"
			hint="I clear (set to null) data point values for a given variable ">
		<cfargument name="variable_id" type="numeric" hint="A primary key of the variables table" />

		<cfset var deleteForVariable = 0 />

		<cfquery name="deleteForVariable" datasource="#variables.instance.dsn#">
			UPDATE
			    DataPoints
			SET
			    value = Null
			WHERE
			    DataPoints.variable_id = <cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.variable_id#" />
		</cfquery>
	</cffunction>

	<cffunction access="package" returntype="void" name="save" output="false" 
		hint="I save a data point">
		<cfargument name="observation_id" type="numeric" hint="An observation ID" />
		<cfargument name="variable_id" type="numeric" hint="A variable ID" />
		<cfargument name="value" type="string" hint="The value for the data point" />
		
		<cfset var saveDataPoint = 0 />
		
		<!--- Don't need to worry about performing an update, because all values were cleared out when first running the compute task --->
		<cfquery name="saveDataPoint" datasource="#variables.instance.dsn#">
			insert into DataPoints (observation_id,variable_id,value)
			VALUES (
				<cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.observation_id#" />,
				<cfqueryparam cfsqltype="cf_sql_bigint" value="#arguments.variable_id#" />,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.value#" />
			)
			
		</cfquery>
		
	</cffunction>
</cfcomponent>