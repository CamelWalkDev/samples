<!--- Document Information -----------------------------------------------------

Title:      ComputedVariableService.cfc

Author:     Toby Reiter
Email:      tobyhreiter@gmail.com

company:    CamelWalkDev
Website:    n/a

Purpose:    Summary: Provides auto-calculation of data points for all computed variables for all 
			observations
			
			Full: (See ExperimentService.cfc for complete explanation of scenario). The ComputedVariableService performs
			the calculations for all computed variables. This is implemented as a service because it needs access to child
			gateways to do its work.

Usage:      Exists as a service layer of the domain model; instantiated by a dependency injection 
			framework and accessed through a controller object

Modification Log:

Name			Date			Description
================================================================================
Toby Reiter		06/19/2014		Created
------------------------------------------------------------------------------->

<cfcomponent displayname="ComputedVariableService" output="false" hint="I provide a service for generating computed data points that are based on computed variables">

	<cffunction name="init" access="public" returnType="ComputedVariableService" output="false">
		<cfargument name="VariablesGateway" type="any" required="true">
		<cfargument name="DataPointsGateway" type="any" required="true">

		<cfset variables.VariablesGateway = arguments.VariablesGateway />
		<cfset variables.DataPointsGateway = arguments.DataPointsGateway />
		<cfreturn this>
	</cffunction>

	<!--- PACKAGE METHODS --->
	<cffunction access="package" returntype="void" name="computeValues" output="false"
			hint="I compute all computed data points">

		<!--- This retrieves all variables in the system that are non-basic, and are expressed as a computation of data points, as opposed to actual observed data points ---> 
		<cfset var qComputedVariables = variables.VariablesGateway.getComputedVariables(argumentcollection = arguments) />
				
		<cfloop query="qComputedVariables">
			<!--- We want to maximize the number of computed data points that are calculated, so we want to silently catch any exceptions that may arise --->	
			<cftry>
				<cfset computeValuesForVariable ( 	variable_id = qComputedVariables.id, 
													computation = qComputedVariables.computation
												) />
				<cfcatch>
					<cfrethrow /><!--- REMOVE --->
				</cfcatch>
			</cftry>
		</cfloop>			
	</cffunction>

	<!--- PRIVATE METHODS --->
	<!--- This returns all of the dependent variables in a computed variable formula --->
	<cffunction access="package" returntype="string" name="getDependentVariablesFromComputation" output="false"
		hint="I get all of the variable ID's from the equation in a variables computation">
		<cfargument name="computation" type="string" hint="The computation equation string" />

		<!--- This takes the original computation which contains the equation and extracts all of the variable IDs through a regular expression match (each variable is in the format :999; )  --->
		<cfset var dependentVariableArray = REMatch('[0-9]+;',arguments.computation) />
		<!--- The result from the regular expression match is an array, which we turn into a list for simplicity --->
		<cfset dependent_variable_ids = ArrayToList(dependentVariableArray) />
		<!--- and then strip out the semi-colons  --->
		<cfset dependent_variable_ids = replace(dependent_variable_ids,';','','ALL') />

		<cfreturn dependent_variable_ids />
	</cffunction>
	
	<!--- This performs all of the actual computation of the computed variables --->
	<cffunction access="private" returntype="void" name="computeValuesForVariable" hint="I calculate all computed values for a given variable">
		<cfargument name="variable_id" type="numeric" required="true" hint="A primary key of the Variables table" />
		<cfargument name="computation" type="string" required="true" hint="The computation/equation for the computed variable" />

		<!--- Retrieve a list of which variables will appear in this equation. This allows us to retrieve only data points that match these dependent variables --->
		<cfset var dependent_variable_ids = getDependentVariablesFromComputation(arguments.computation) />		

		<!--- The dependent count is used to track whether all variables in the equation are accounted for --->
		<cfset var dependentCount = ListLen(dependent_variable_ids) />
		
		<!--- 	Sometimes, data is missing/not applicable for a given variable and observation. This can lead to misleading 
				or impossible data points, so the scientists have a policy of guidelines of when a computation should 
				simply be skipped:
				- In any case where multiplication occurs and the answer result is 0, only store the calculation when all values are present
				- In any case where division occurs and the answer result is 0, only store the calculation when all values are present
				However:
				- for simple addition and subtraction, treat the missing value as a 0, and store the computed value
		--->				
		<!--- Determine whether the computation has multiplication or division--->
		<cfset var hasMultiplication = Find('*',arguments.computation) />
		<cfset var hasDivision = Find('/',arguments.computation) />

		<!--- Check to see if our equation begins with a function name (i.e. is an aggregate function) --->
		<cfset var aggregateFunction = REReplaceNoCase(arguments.computation,'^([a-zA-z]+)?\(?.+','\1') />
		<cfset var hasAggregateFunction = len(trim(aggregateFunction)) />

		<!--- Declare all variables needed in the computation (to make sure this works pre-CF9 without variable hoisting --->
		<cfset var workingComputation = arguments.computation /><!--- A working/modifiable computation string for the current observation --->
		<cfset var variableReplacementString = '' /><!--- Used to designate the replacement string for a variable in the computation --->
		<cfset var dataPointValue = 0 /><!--- The observed value from the data points, which is also scrubbed--->
		<cfset var replacementCount = 0 /><!--- The number of actual replacements performed for a given computation; this will be useful in cases where this is less than the dependent count, and we are dealing with either multiplication or division--->
		<cfset var workingValue = 0 /><!--- The value of the evaluated computation  --->
		<cfset var aggregateValueArray = 0 /><!--- Used for storing values from the computation for aggregate calculations --->
		
		<!--- This retrieves all observations for observed data points that include the dependent variable --->
		<cfset var qDataPoints = variables.DataPointsGateway.getDataPoints(variable_ids=dependent_variable_ids) />

		<!--- Clear all values for this variable; we need to delete previous values, because the computation may have changed --->
		<cfset variables.DataPointsGateway.deleteForVariable(variable_id) />
		
		<!--- Process for each observation --->
		<cfoutput query="qDataPoints" group="observation_id">

			<!--- Re-initialize the equation for each iteration --->
			<cfset workingComputation = arguments.computation />

			<!--- Re-initialize the replacement count --->
			<cfset replacementCount = 0 />

			<!--- For each dependent variable_id, replace it in the equation --->
			<cfoutput group="variable_id">
				<!--- Get the active data point, and strip commas and percents from the value, as these cause problems --->
				<cfset dataPointValue = REReplace(qDataPoints.value,'[,%]','','ALL') />

				<!--- Get the variable string to match. As mentioned above, variables are encoded in computations as :999;, where 999 is the variable ID --->
				<cfset variableReplacementString = ':#qDataPoints.variable_id#;' />
				<!--- Make sure to replace all instances, as the same variable might appear twice in the same computation --->
				<cfset workingComputation = REReplaceNoCase(workingComputation, variableReplacementString, dataPointValue ,'ALL') />
			</cfoutput>

			<!--- If this is not an aggregate function, attempt to evaluate the equation --->
			<cfif NOT hasAggregateFunction>
				<cftry>
					<!--- Replace any values not found in the equation with 0 --->
					<cfset workingComputation = REReplace(workingComputation,':[0-9]+;','0','ALL') />

					<cfset workingValue = Evaluate(workingComputation) />

					<!--- Round the number to the nearest hundredth (0.01)--->
					<cfset workingValue = Round(workingValue * 100) / 100 />

					<cfcatch type="any">
						<!--- Divide by zero error --->
						<cfif cfcatch.message CONTAINS "Division by zero">
							<!--- Fail silently --->
						<cfelse>
							<cflog type="Warning" file="computed-variables" text="#arguments.variable_id#: Could not evaluate #workingComputation#" />
						</cfif>
						<cfset workingValue = '' />
					</cfcatch>
				</cftry>
				<!--- If the equation == 0, has multiplication or division, and the # of variable_id matches is less than the # of dependent variable_ids, then set the value to blank --->
				<cfif workingValue EQ 0 AND (hasMultiplication OR hasDivision) and replacementCount LT dependentCount>
					<cfset workingValue = '' />
				</cfif>
			<!--- if this is an aggregate function --->
			<cfelse>
				<!--- Process the equation based on which aggregate function it is --->
				<!--- Strip out the function, and remove leading and trailing parantheses, to get a simple list of values --->
				<cfset workingComputation = REReplaceNoCase(workingComputation,'^[a-zA-Z]+\(([^)]+)\)','\1') />

				<!--- Replace any values not found in the equation with blank --->
				<cfset workingComputation = REReplace(workingComputation,':[0-9]+;','','ALL') />

				<!--- Convert the list of values to an array (to perform aggregate operations) --->
				<cfset aggregateValueArray = ListToArray(workingComputation) />

				<cftry>
					<!--- This simply routes the passed in aggregate function to the appropriate array function--->
					<cfswitch expression="#aggregateFunction#">
						<cfcase value="sum">
							<cfset workingValue = arraySum(aggregateValueArray) />
						</cfcase>
						<cfcase value="avg">
							<cfset workingValue = arrayAvg(aggregateValueArray) />
						</cfcase>
						<cfcase value="max">
							<cfset workingValue = arrayMax(aggregateValueArray) />
						</cfcase>
						<cfcase value="min">
							<cfset workingValue = arrayMin(aggregateValueArray) />
						</cfcase>
					</cfswitch>

					<cfcatch>
						<cflog type="Warning" file="computed-variables" text="#arguments.variable_id#: Could not evaluate #workingComputation#" />
					</cfcatch>
				</cftry>
			</cfif>

			<!--- Save the value (even if blank). If there's no existing value, blank values won't be saved --->
			<cfset variables.dataPointsGateway.save(observation_id=qDataPoints.observation_id,variable_id=arguments.variable_id,Value=workingValue) />

			<cflog file="computed-variables" text="#arguments.variable_id#: #workingComputation# = #workingValue# (Saved)" />
		</cfoutput>
	</cffunction>
</cfcomponent>