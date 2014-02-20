#
# Module 'Dynamite.PowerShell.Toolkit'
# Generated by: GSoft, Team Dynamite.
# Generated on: 10/24/2013
# > GSoft & Dynamite : http://www.gsoft.com
# > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
# > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
#

function New-DSPSiteCollectionRecusiveXml()
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[System.Xml.XmlElement]$Site,
		
		[Parameter(Mandatory=$true, Position=1)]
		[string]$WebApplicationUrl
	)	

	[string]$ContentDatabaseName = $Site.ContentDatabase
	[string]$SiteHostNamePath = $Site.HostNamePath
	[string]$SiteRelativePath = $Site.RelativePath
	[string]$Name = $Site.Name
	[string]$OwnerAlias = $Site.OwnerAlias
	[string]$Language = $Site.Language
	[string]$Template = $Site.Template
	[bool]$IsHostNamedSite = -not [string]::IsNullOrEmpty($SiteHostNamePath)
	$SiteRelativeUrl = "/$SiteRelativePath"
	$SiteAbsoluteUrl = if ($IsHostNamedSite) { "$SiteHostNamePath$SiteRelativeUrl" } else { "$WebApplicationUrl$SiteRelativeUrl" }
 
 	# Create the Content Database if they do not exist
	New-DSPContentDatabase -ContentDatabaseName $ContentDatabaseName -WebApplicationUrl $WebApplicationUrl -Verbose:$Verbose
	
	if($SiteRelativePath -and $SiteRelativePath -ne "/")
	{
		# Create the Managed Path if they do not exist
		New-DSPManagedPath -SiteRelativePath $SiteRelativePath -WebApplicationUrl $WebApplicationUrl -Verbose:$Verbose
	}

	$spSite = Get-SPSite -Identity $SiteAbsoluteUrl -ErrorAction SilentlyContinue
	if ($spSite -eq $null)
	{
		Write-Verbose "Creating site collection $SiteAbsoluteUrl"
		$startTime = Get-Date
		if ($IsHostNamedSite)
		{
			$spSite = New-SPSite -URL $SiteAbsoluteUrl -HostHeaderWebApplication $WebApplicationUrl -OwnerAlias $OwnerAlias -SecondaryOwnerAlias $env:USERDOMAIN\$env:USERNAME -Name $Name -Language $Language -Template $Template -ContentDatabase $ContentDatabaseName
		}
		else
		{
			$spSite = New-SPSite -URL $SiteAbsoluteUrl -OwnerAlias $OwnerAlias -SecondaryOwnerAlias $env:USERDOMAIN\$env:USERNAME -Name $Name -Language $Language -Template $Template -ContentDatabase $ContentDatabaseName
		}
		
		$elapsedTime = ($(get-date) - $StartTime).TotalSeconds
		Write-Verbose "Took $elapsedTime sec."
		Write-Verbose "Site $Name Created Successfully!"
	}
	else
	{
		Write-Warning "Another site already exists at $SiteAbsoluteUrl"
	}
	
	$Group = $Site.Groups
	if ($Group -ne $null)
	{
		Add-DSPGroupByXml -Web $spSite.Url -Group $Group
	}
	
	# Create Sub Webs
	if ($Site.Webs -ne $null)
	{
		New-DSPWebXml -Webs $Site.Webs -ParentUrl $spSite.Url -UseParentTopNav
	}
	
	# Create Variations
	if ($Site.Variations -ne $null)
	{
		New-DSPSiteVariations -Config $Site.Variations -Site $spSite -Verbose:$Verbose
	}
}

<#
	.SYNOPSIS
		Method to Create multiple Site Collections and Sites structure

	.DESCRIPTION
		Method to Create multiple Site Collections and Sites structure

    --------------------------------------------------------------------------------------
    Module 'Dynamite.PowerShell.Toolkit'
    by: GSoft, Team Dynamite.
    > GSoft & Dynamite : http://www.gsoft.com
    > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    --------------------------------------------------------------------------------------
    
	.PARAMETER  XmlPath
		Path to the Xml file describing the structure

  .EXAMPLE
		PS C:\> New-DSPStructure "c:\structure.xml"

	.INPUTS
		System.String
        
  .LINK
    GSoft, Team Dynamite on Github
    > https://github.com/GSoft-SharePoint
    
    Dynamite PowerShell Toolkit on Github
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    
    Documentation
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    
  
  .NOTES
  Here is the Structure XML schema.
  
<WebApplication Url="http://myWebApp">
  <Site Name="Site Name" RelativePath="mySiteUrl" OwnerAlias="ORG\admin" Language="1033" Template="STS#1" ContentDatabase="CUSTOM_CONTENT_NAME">
    <Groups>
      <Group Name="Site_Admin" OwnerName="ORG\admin" Description="Admin Group" IsAssociatedOwnerGroup="true">
        <PermissionLevels>
          <PermissionLevel Name="Full Control"/>
          <PermissionLevel Name="Contribute"/>
          <PermissionLevel Name="Read"/>
        </PermissionLevels>
      </Group>
    </Groups>
    <Webs>
      <Web Name="SubSite Name" Path="mySubSiteUrl" Template="STS#0">
        <Groups>
          <Group Name="SubSite_Admin" OwnerName="ORG\admin" Description ="Admin Group for SubSite">
            <PermissionLevels>
              <PermissionLevel Name="Full Control"/>
              <PermissionLevel Name="Contribute"/>
              <PermissionLevel Name="Read"/>
            </PermissionLevels>
          </Group>
        </Groups>
      </Web>
    </Webs>
  </Site>
</WebApplication>
#>
function New-DSPStructure()
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$XmlPath
	)
	
	# Get the Xml content and start looping throught Site Collections and generate the structure
	$Config = [xml](Get-Content $XmlPath)
	$Config.WebApplication.Site | ForEach-Object {New-DSPSiteCollectionRecusiveXml -Site $_ -WebApplicationUrl $_.ParentNode.Url}
}

<#
	.SYNOPSIS
		Method to Delete multiple Site Collections and Sites structure

	.DESCRIPTION
		Method to Delete multiple Site Collections and Sites structure

    --------------------------------------------------------------------------------------
    Module 'Dynamite.PowerShell.Toolkit'
    by: GSoft, Team Dynamite.
    > GSoft & Dynamite : http://www.gsoft.com
    > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    --------------------------------------------------------------------------------------
    
	.PARAMETER  XmlPath
		Path to the Xml file describing the structure

  .EXAMPLE
		PS C:\> New-DSPStructure "c:\structure.xml"

	.INPUTS
		System.String
        
  .LINK
    GSoft, Team Dynamite on Github
    > https://github.com/GSoft-SharePoint
    
    Dynamite PowerShell Toolkit on Github
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    
    Documentation
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    
    
  .NOTES
  Here is the Structure XML schema.
  
<WebApplication Url="http://myWebApp">
  <Site Name="Site Name" RelativePath="mySiteUrl" OwnerAlias="ORG\admin" Language="1033" Template="STS#1" ContentDatabase="CUSTOM_CONTENT_NAME">
    <Groups>
      <Group Name="Site_Admin" OwnerName="ORG\admin" Description="Admin Group" IsAssociatedOwnerGroup="true">
        <PermissionLevels>
          <PermissionLevel Name="Full Control"/>
          <PermissionLevel Name="Contribute"/>
          <PermissionLevel Name="Read"/>
        </PermissionLevels>
      </Group>
    </Groups>
    <Webs>
      <Web Name="SubSite Name" Path="mySubSiteUrl" Template="STS#0">
        <Groups>
          <Group Name="SubSite_Admin" OwnerName="ORG\admin" Description ="Admin Group for SubSite">
            <PermissionLevels>
              <PermissionLevel Name="Full Control"/>
              <PermissionLevel Name="Contribute"/>
              <PermissionLevel Name="Read"/>
            </PermissionLevels>
          </Group>
        </Groups>
      </Web>
    </Webs>
  </Site>
</WebApplication>
#>
function Remove-DSPStructure()
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$XmlPath
	)
	
	$Config = [xml](Get-Content $XmlPath)
	foreach ($site in $Config.WebApplication.Site)
	{
		[bool]$IsHostNamedSite = -not [string]::IsNullOrEmpty($site.HostNamePath)
		$SiteRelativeUrl = [string]::Concat("/", $site.RelativePath)
		$SiteAbsoluteUrl = if ($IsHostNamedSite) { $site.HostNamePath + $SiteRelativeUrl } else { $site.ParentNode.Url + $SiteRelativeUrl }
		$site = Get-SPSite -Identity $SiteAbsoluteUrl -ErrorAction SilentlyContinue
		
		if($site -ne $null)
		{	
			Write-Verbose "Remove site collection $SiteAbsoluteUrl"
			Remove-SPSite -Identity $SiteAbsoluteUrl
		}
		else
		{
			Write-Warning "No site collection $SiteAbsoluteUrl found"
		}		
	}
}

function Remove-DSPStructureDatabase()
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$XmlPath
	)
	
	$Config = [xml](Get-Content $XmlPath)
	foreach ($site in $Config.WebApplication.Site)
	{
		Remove-SPContentDatabase -Identity $Site.ContentDatabase
	}
}

<#
	.SYNOPSIS
		Method to Add Suggested Browser Content Locations 

	.DESCRIPTION
		Method to Suggested Browser Content Locations on a site collection

    --------------------------------------------------------------------------------------
    Module 'Dynamite.PowerShell.Toolkit'
    by: GSoft, Team Dynamite.
    > GSoft & Dynamite : http://www.gsoft.com
    > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    --------------------------------------------------------------------------------------
    
	.PARAMETER  XmlPath
		Path to the Xml file describing the configuration

  .EXAMPLE
		PS C:\> New-SuggestedBrowserContentLocations "c:\structure.xml"

	.INPUTS
		System.String
        
  .LINK
    GSoft, Team Dynamite on Github
    > https://github.com/GSoft-SharePoint
    
    Dynamite PowerShell Toolkit on Github
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    
    Documentation
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    
    
  .NOTES
  Here is the Structure XML schema.
  
	<Configuration>
	  <Site Url="http://yoururl">
		<PublishingLinks>
		  <Link DisplayName="Images for content" Url="http://site/LibraryRootFolder" UrlDescription="Images picker" Description="Images for content"/>
		</PublishingLinks>
	  </Site>
	</Configuration>
#>
function New-SuggestedBrowserContentLocations
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$XmlPath
	)
	
	$Config = [xml](Get-Content $XmlPath)
	$Config.Configuration.Site | ForEach-Object {
	
		$Site = Get-SPSite $_.Url
		Add-SuggestedBrowserContentLocations $_.PublishingLinks $Site
	}
}

function Add-SuggestedBrowserContentLocations
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[System.Xml.XmlElement]$PublishingLinks,
		
		[Parameter(Mandatory=$true, Position=1)]
		[Microsoft.SharePoint.SPSite]$Site
	)	
	$publishingLinksListUrl = [Microsoft.SharePoint.Utilities.SPUtility]::ConcatUrls($Site.RootWeb.ServerRelativeUrl,"/PublishedLinks")
	$PublishingLinksList = $Site.RootWeb.GetList($publishingLinksListUrl)
	if($PublishingLinksList -ne $null)
	{
		$PublishingLinks.Link | ForEach-Object {
    
                $url = $_.Url

                Write-Verbose "Adding Suggested browser location $url"
                    
				$urlFieldValue = New-Object Microsoft.SharePoint.SPFieldUrlValue
				$urlFieldValue.Url = $url
				$urlFieldValue.Description = $_.UrlDescription
					
				$listItem = $PublishingLinksList.Items.Add()
                $listItem["Title"] = $_.DisplayName
				$listItem["PublishedLinksDescription"] = $_.Description
				[Microsoft.SharePoint.SPFieldUrlValue]$listItem["PublishedLinksURL"] = $urlFieldValue
				
				$listItem.Update()
        }  
    }
}


