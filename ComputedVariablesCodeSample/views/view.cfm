<!--- Document Information -----------------------------------------------------

Title:      view.cfm

Author:     Toby Reiter
Email:      tobyhreiter@gmail.com

company:    CamelWalkDev
Website:    n/a

Purpose:    Summary: A simple view for displaying the data point results
			
Usage:      Included by the controller file

Modification Log:

Name			Date			Description
================================================================================
Toby Reiter		06/19/2014		Created
------------------------------------------------------------------------------->

<cfsavecontent variable="request.output">
	<cfif isQuery(variables.qResults)>
		<cfoutput>
			<h1>#variables.qResults.experiment_name#</h1>
			
			<p>#variables.qResults.experiment_description#</p>
		</cfoutput>
		<table>
			<cfoutput query="variables.qResults" group="observation_id">
				<tr class="time-stamp">
					<th>#TimeFormat(time_stamp,'h:mm')#</th>
					<cfoutput group="variable_id">
						<th>#variable_label#</th>
					</cfoutput>
				</tr>
				<tr>
					<td>&nbsp;</td>
					<cfoutput group="datapoint_id">
						<td>#value#</td>
					</cfoutput>				
				</tr>
			</cfoutput>
		</table>
	</cfif>
</cfsavecontent>