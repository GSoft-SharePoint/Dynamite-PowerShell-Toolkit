#
# Module 'Dynamite.PowerShell.Toolkit'
# Generated by: GSoft, Team Dynamite.
# Generated on: 10/24/2013
# > GSoft & Dynamite : http://www.gsoft.com
# > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
# > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
#

<#
	.SYNOPSIS
		Commandlet to set Term Driven configuration in the term store

	.DESCRIPTION
		This cmdlet allow you to configure term driven configuration pages for the taxonomy term store. 
		You can pass a XML file as parameter to automatically create the correct settings.

    --------------------------------------------------------------------------------------
    Module 'Dynamite.PowerShell.Toolkit'
    by: GSoft, Team Dynamite.
    > GSoft & Dynamite : http://www.gsoft.com
    > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    --------------------------------------------------------------------------------------
		
	.PARAMETER XmlPath
		Path to the XML file that contains the term driven configuration. The schema for the XML is as follow:
		
	<TermStore Name="Managed Metadata Service">
	  <TermGroup Name="TermGroup">
		<TermSet Name="TermSet">
		  <TargetUrlForChildTerms>/Pages/Example.aspx</TargetUrlForChildTerms>
		  <CatalogTargetUrlForChildTerms>/Pages/Example.aspx</CatalogTargetUrlForChildTerms>
		  <Terms>
			<Term Name="Term">
			  <TargetUrl>/Pages/Example.aspx</TargetUrl>
			  <TargetUrlForChildTerms>/Pages/Example.aspx</TargetUrlForChildTerms>
			  <CatalogTargetUrl></CatalogTargetUrl>
			  <CatalogTargetUrlForChildTerms></CatalogTargetUrlForChildTerms>
			</Term>
		  </Terms>
		</TermSet>
	  </TermGroup>
	</TermStore>
		
	.EXAMPLE
		PS C:\> New-DSPTermDrivenPagesSettings -XmlPath "C:\TermDriven.xml"

    
  .LINK
    GSoft, Team Dynamite on Github
    > https://github.com/GSoft-SharePoint
    
    Dynamite PowerShell Toolkit on Github
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    
    Documentation
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    
#>
function New-DSPTermDrivenPagesSettings()
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$XmlPath
	)
	
	# Get the Xml content and start looping throught Site Collections and generate the structure
	$Config = [xml](Get-Content $XmlPath)
	
	# Get the term store
	$TermStore = Get-DSPTermStore -Name $Config.TermStore.Name
	
	# Process all Term Groups
	$Config.TermStore.TermGroup | ForEach-Object {
	
		Process-TermGroup -GroupConfig $_ -TermStore $TermStore 
	}
}

function Process-TermGroup()
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		$GroupConfig,
		
		[Parameter(Mandatory=$true, Position=0)]
		$TermStore
	)
	
	$TermGroupName = $GroupConfig.Name
	Write-Verbose "TermGroup: $TermGroupName" 
	
	$GroupConfig.TermSet | ForEach-Object {
	
		Set-TermSetConfig -GroupName $TermGroupName -TermSetConfig $_ -TermStore $TermStore
	
	}
}

function Set-TermSetConfig()
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$GroupName,
		
		[Parameter(Mandatory=$true, Position=1)]
		$TermSetConfig,
		
		[Parameter(Mandatory=$true, Position=1)]
		$TermStore
	)
		
	$TermSetName = $TermSetConfig.Name 
	
	Write-Verbose "`tTermSet: $TermSetName" 

	# Get the term set 
	$TermSet = Get-DSPTermSet -GroupName $GroupName -TermSetName $TermSetName -TermStore $TermStore
	
	# Set the term navigation enabled
	$TermSet.SetCustomProperty("_Sys_Nav_IsNavigationTermSet", "True")
	$TermSet.TermStore.CommitAll()	
		
	# Set the custom properties
	if(![string]::IsNullOrEmpty($TermSetConfig.TargetUrlForChildTerms)){$TermSet.SetCustomProperty("_Sys_Nav_TargetUrlForChildTerms", $TermSetConfig.TargetUrlForChildTerms )}
	if(![string]::IsNullOrEmpty($TermSetConfig.CatalogTargetUrlForChildTerms)){$TermSet.SetCustomProperty("_Sys_Nav_CatalogTargetUrlForChildTerms", $TermSetConfig.CatalogTargetUrlForChildTerms)}
	
	$TermSet.TermStore.CommitAll()
	
	$TermSetConfig.Terms.Term | ForEach-Object {
	
		Set-TermConfig -TermSet $TermSet -TermConfig $_
	}
}

function Set-TermConfig()
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		$TermSet,
		
		[Parameter(Mandatory=$true, Position=1)]
		$TermConfig
	)
	
	$TermName = $TermConfig.Name
	Write-Verbose "`t`tTerm: $TermName" 

	# Get the term from term set
	$Term = $TermSet.GetTerms($TermName, $false);

    $FirstOnly = $TermConfig.FirstOnly

	if ($Term -ne $null)
	{
        $exit = $false
        $i = 0
        $Term | ForEach-Object {
                    
                if ([System.Convert]::ToBoolean($FirstOnly) -eq $true -and $i -eq 1)
                {
                    $exit = $true
                }                    
                                         
                if ($exit -eq $false)
                {
		            if (![string]::IsNullOrEmpty($TermConfig.TargetUrl)){$_.SetLocalCustomProperty("_Sys_Nav_TargetUrl", $TermConfig.TargetUrl)}
		            if (![string]::IsNullOrEmpty($TermConfig.TargetUrlForChildTerms)){$_.SetLocalCustomProperty("_Sys_Nav_TargetUrlForChildTerms", $TermConfig.TargetUrlForChildTerms)}
		            if (![string]::IsNullOrEmpty($TermConfig.CatalogTargetUrl)){$_.SetLocalCustomProperty("_Sys_Nav_CatalogTargetUrl", $TermConfig.CatalogTargetUrl)}
		            if (![string]::IsNullOrEmpty($TermConfig.CatalogTargetUrlForChildTerms)){$_.SetLocalCustomProperty("_Sys_Nav_CatalogTargetUrlForChildTerms", $TermConfig.CatalogTargetUrlForChildTerms)}		
                    $i++
                }
  
            }
	}
	
	$Term.TermStore.CommitAll()
}