<cfcomponent output="false">
	
	<cfset this.name = 'ComputedVariablesCodeSample' />
	<cfset this.applicationTimeout = createTimeSpan(0,1,0,0)>

	<!--- Main mapping path for the site (all component paths depend on this) --->
	<cfset this.mappings["/"] = getDirectoryFromPath(getCurrentTemplatePath()) />

	<!--- Mapping paths for frameworks --->
	<cfset this.mappings["/coldspring"] = ExpandPath('../coldspring') />

	<cffunction name="onApplicationStart" returnType="boolean" output="false">
		<cfset loadBeanFactory() />
		<cfreturn true>
	</cffunction>

	<cffunction access="private" returntype="void" name="loadBeanFactory" hint="I load a custom bean factory for the application">		
		<cfset application.ColdSpringBeanFactory = createObject("component", "coldspring.beans.DefaultXmlBeanFactory").init() />
		<cfset application.ColdSpringBeanFactory.loadBeansFromXmlFile("/conf/beans.xml", true) />
	</cffunction>
	
	<cffunction name="onRequestStart" returnType="boolean" output="false">
		<cfargument name="thePage" type="string" required="true">
		
		<cfif isDefined("url.refresh") AND YesNoFormat(url.refresh)>
			<cfset loadBeanFactory()>
		</cfif>
		
		<cfreturn true />
	</cffunction>
</cfcomponent>
