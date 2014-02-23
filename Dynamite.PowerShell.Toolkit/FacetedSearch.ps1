function New-DSPFacetedSearchSettings()
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
	$TermSet.SetCustomProperty("_Sys_Facet_IsFacetedTermSet", "True")
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


	$sortConstants = @{"1" = "name"; "0"="count"; "2"="number"}
    $sortByConstants = @{"1" = "ascending"; "0"="descending"}	

	$TermName = $TermConfig.Name
	Write-Verbose "`t`tTerm: $TermName" 

	# Get the term from term set
	$Term = $TermSet.GetTerms($TermName, $false);
	
	if ($Term -ne $null)
	{
        $FullRefinementString= @()
        $RefinementConfig = @()

        $i = 0

        $Term.Refiner | ForEach-Object {

            if($_.Type -eq "DateTime")
            {
                $FullRefinementString += $_.PropertyName+"(discretize=manual/2013-02-21T05:00:00Z/2014-01-22T05:00:00Z/2014-02-14T05:00:00Z/2014-02-21T05:00:00Z)"
            }
            else
            {
                #AgropurNavigationOWSTEXT(sort=name/ascending,filter=5/0/*)
                $FullRefinementString += $_.PropertyName +"(sort=" + $sortConstants.Get_Item($_.Sort) + "/" + $sortByConstants.Get_Item($_.SortBy) +",filter=" + $_.MaxNumberRefinementOptions +"/0/*)"
            }

            $RefinementConfig += "_Sys_Facet_RefinerConfig"+$i

            # Set custom property
            $Term.SetCustomProperty("_Sys_Facet_RefinerConfig"+$i, '{"sortBy":'+$_.SortBy +
                                                                        '"sortOrder":'+$_.SortOrder +
                                                                        '"maxNumberRefinementOptions":' + $_.MaxNumberRefinementOptions +
                                                                        '"propertyName":"' + $_.PropertyName +
                                                                        '"type":"' + $_.Type +
                                                                        '"displayTemplate":"' + $_.DisplayTemplate +
                                                                        '"useDefaultDateIntervals":"' + $_.UseDefaultDateIntervals +
                                                                        '"aliases":"' + $_.Aliases +
                                                                        '"refinerSpecStringOverride":"' + $_.RefinerSpecStringOverride +
                                                                        '"intervals":"' + $_.intervals +
                                                                        '}')
        }

        $Term.SetCustomProperty("_Sys_Facet_RefinementConfig", "[" + $RefinementConfig -join ',' + "]")
        $Term.SetCustomProperty("_Sys_Facet_RefinementConfig", "[" + $RefinementConfig -join ',' + "]")
        $Term.SetCustomProperty("_Sys_Facet_FullRefinementString", $FullRefinementString -join ',')
	}
	
	$Term.TermStore.CommitAll()
}