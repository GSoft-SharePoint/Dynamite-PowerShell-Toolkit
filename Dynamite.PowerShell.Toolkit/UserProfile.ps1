
function Add-DSPUserProfileSection {
	
	[CmdletBinding()]
	Param
	(
        [Parameter(Mandatory=$true, Position=0)]
		$UserProfileApplication,

		[Parameter(Mandatory=$true, Position=1)]
		[System.Xml.XmlElement]$Sections,

        [Parameter(Mandatory=$false, Position=2)]
		[switch]$Delete
	)	

    Load-DSPUserProfileAssemblies

    $serviceContext = Get-DSPServiceContext $UserProfileApplication
    $userProfileConfigManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager $serviceContext

	if ($Sections -ne $null)
	{	
		foreach ($newSection in $Sections)
		{
            $SectionName = $newSection.Name;
            $SectionDisplayName = $newSection.DisplayName;

			#Create new section in User Profiles 
			Write-Verbose "Creating new section $SectionName" 

			$allEntries = $userProfileConfigManager.GetPropertiesWithSection();

			$sectionExists =$false

			foreach ($temp in $allEntries) 
			{
				if($temp.Name -eq $SectionName) 
				{
					Write-Verbose "Section $SectionName already exists";
					$sectionExists = $true;
					$section = $temp
				}
			}

            # Delete the previous section if specified
            if($section-ne $null)
            {
                $allEntries.RemoveSectionByName($SectionName)
                $sectionExists = $false
            }
            else
            {
                Write-Verbose "Section $SectionName doesn't exists";
            }

			if ($sectionExists -ne $true -and $Delete -eq $false)
			{
				$section = $allEntries.Create($true);
				$section.Name = $SectionName;
				$section.ChoiceType = [Microsoft.Office.Server.UserProfiles.ChoiceTypes]::Off;
				$section.DisplayName = $SectionDisplayName
				$section.Commit();
				Write-Verbose "Section $SectionName created!" 
			}


            $newSection.UserProperty | ForEach-Object {
                Add-DSPUserProfileProperty $UserProfileApplication $_ $Delete              
            }
            
		}
	}	
}


function Add-DSPUserProfileProperty {
    [CmdletBinding()]
	Param
	(
        [Parameter(Mandatory=$true, Position=0)]
		$UserProfileApplication,

		[Parameter(Mandatory=$true, Position=1)]
		[System.Xml.XmlElement]$Properties,
		
        [Parameter(Mandatory=$false, Position=2)]
		[switch]$Delete
	)	

    Load-DSPUserProfileAssemblies

    $serviceContext = Get-DSPServiceContext $UserProfileApplication
    $userProfileConfigManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager $serviceContext

    $userProfilePropertyManager = $userProfileConfigManager.ProfilePropertyManager
    $userProfilePropertyManager = $userProfilePropertyManager.GetCoreProperties()
    $userProfileTypeProperties = $userProfileConfigManager.ProfilePropertyManager.GetProfileTypeProperties([Microsoft.Office.Server.UserProfiles.ProfileType]::User)
    $userProfileSubTypeManager = [Microsoft.Office.Server.UserProfiles.ProfileSubTypeManager]::Get($serviceContext)

	$userProfile = $userProfileSubTypeManager.GetProfileSubtype([Microsoft.Office.Server.UserProfiles.ProfileSubtypeManager]::GetDefaultProfileName([Microsoft.Office.Server.UserProfiles.ProfileType]::User))
	$userProfileProperties = $userProfile.Properties 

	if ($Properties -ne $null)
	{	
		foreach ($newProperty in $Properties)
		{

            # Remove property if exists

            $UserPropertyName = $newProperty.GeneralSettings.Name
            $userProperty = $userProfilePropertyManager.GetPropertyByName($UserPropertyName)       

            if($userProperty -ne $null)
            {
                # Remove in all cases
                $userProfilePropertyManager.RemovePropertyByName($UserPropertyName)
            }
            else
            {
                Write-Verbose "User Property $UserPropertyName doesn't exists";
            }

            if($Delete -eq $false)
            {
                Write-Verbose "Creating User Property $UserPropertyNamets";

                $userProperty = $userProfilePropertyManager.Create($false)

                # General Settings

                $userProperty.Name = $UserPropertyName
                $userProperty.DisplayName = $newProperty.GeneralSettings.DisplayName
                $userProperty.Type = $newProperty.GeneralSettings.Type
                $userProperty.Length = $newProperty.GeneralSettings.Length
                $userProperty.IsAlias = [System.Convert]::ToBoolean($newProperty.GeneralSettings.IsAlias)
                $userProperty.IsSearchable = [System.Convert]::ToBoolean($newProperty.GeneralSettings.IsSearchable)
                $userProperty.IsMultivalued = [System.Convert]::ToBoolean($newProperty.GeneralSettings.IsMultivalued)

                # Taxonomy Settings

                if($newProperty.GeneralSettings.IsMultivalued -eq $true)
                {

                    $Separator =  $newProperty.TaxonomySettings.Separator
                
                    $userProperty.Separator = [Microsoft.Office.Server.UserProfiles.MultiValueSeparator]::$Separator
                }
           
                if($newProperty.TaxonomySettings.TermsetName -ne $null -and $newProperty.TaxonomySettings.TermsetGroup -ne $null)
                {

                    $userProperty.TermSet = Get-DSPTermSet -GroupName $newProperty.TaxonomySettings.TermsetGroup -TermSetName $newProperty.TaxonomySettings.TermsetName
                }

                $userProfilePropertyManager.Add($userProperty)
                $profileTypeProperty = $userProfileTypeProperties.Create($userProperty)

                # Display Settings

                $profileTypeProperty.IsVisibleOnEditor = [System.Convert]::ToBoolean($newProperty.DisplaySettings.IsVisibleOnEditor) 
                $profileTypeProperty.IsVisibleOnViewer = [System.Convert]::ToBoolean($newProperty.DisplaySettings.IsVisibleOnViewer)
                $profileTypeProperty.IsEventLog =[System.Convert]::ToBoolean($newProperty.DisplaySettings.IsEventLog) 


                $userProfileTypeProperties.Add($profileTypeProperty)
			    $Privacy = $newProperty.DisplaySettings.Privacy
			    $PrivacyPolicy =$newProperty.DisplaySettings.PrivacyPolicy
			
                $profileSubTypeProperty = $userProfileProperties.Create($profileTypeProperty)
                $profileSubTypeProperty.DefaultPrivacy =[Microsoft.Office.Server.UserProfiles.Privacy]::$Privacy
                $profileSubTypeProperty.PrivacyPolicy =    [Microsoft.Office.Server.UserProfiles.PrivacyPolicy]::$PrivacyPolicy
                $userProfileProperties.Add($profileSubTypeProperty)

                $profileTypeProperty.Commit();
            }
        }
    }

}

function Get-DSPServiceContext()
{
    [CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true, Position=0)]
		$serviceApplication
	)

    
    return [Microsoft.SharePoint.SPServiceContext]::GetContext($serviceApplication.ServiceApplicationProxyGroup, [Microsoft.SharePoint.SPSiteSubscriptionIdentifier]::Default)
}

function Load-DSPUserProfileAssemblies()
{
    #Load SharePoint User Profile assemblies
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server") > $null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.UserProfiles") > $null
}

# Add full permissions to the current user !
function Set-DSPUserProfileSchema
{
    [CmdletBinding()]
	Param
	(
		[Parameter(ParameterSetName="Default", Mandatory=$true, Position=0)]
	    [string]$XmlPath,

        [Parameter(Mandatory=$false, Position=1)]
		[switch]$Delete
	)

    [xml]$xmlContent = Get-Content $XmlPath

    if($xmlContent -ne $null)
    {
        $serviceApplication = Get-SPServiceApplication | ?{$_.Name -eq $xmlContent.Configuration.UserProfileApplicationName}
         
        Add-DSPUserProfileSection $serviceApplication $xmlContent.Configuration.Section $Delete
    }
   
}

$VerbosePreference = "Continue"  
Set-DSPUserProfileSchema "D:\dev\Agropur - Intranet\Development\Team\Source\Agropur.Intranet\Scripts\Configuration\UserProfileProperties.xml"


