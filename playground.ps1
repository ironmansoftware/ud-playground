$Commands = Get-Command -Module 'UniversalDashboard' -Verb 'New'
$CommonParams = @('Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable')

$Navigation = $Commands | ForEach-Object {
    $Item = $_
    New-UDListItem -Label $_.Noun -OnClick {
        $Session:SelectedComponent = $Item.Name
        $Session:ScriptBlock = $null
        $Session:Parameters = $null

        Sync-UDElement -Id 'display'
        Sync-UDElement -Id 'parameters'
    }
} 

New-UDDashboard -Title 'Universal Dashboard Playground' -Content {
    $Session:SelectedComponent = "New-UDButton"

    New-UDDynamic -Content {
        New-UDTypography -Text $Session:SelectedComponent -Variant h4
        New-UDPaper -Content {
            $ScriptBlock = $Session:SelectedComponent
            $Parameters = (Get-Command -Name $Session:SelectedComponent).Parameters
            
            foreach ($parameter in $Session:parameters.psobject.properties) {
                if ($parameter.Value -eq $null) {
                    continue
                }
                elseif ($Parameter.Name -eq 'Icon') {
                    if (-not [string]::IsNullOrEmpty($parameter.value)) {
                        $ScriptBlock += " -Icon (New-UDIcon -Icon '$($parameter.Value)')"
                    }
                    
                }
                elseif ($Parameters[$Parameter.Name].ParameterType.Name -eq 'ScriptBlock' -or $Parameters[$Parameter.Name].ParameterType.Name -eq 'Endpoint' ) {
                    $ScriptBlock += " -$($parameter.Name) { $($parameter.Value) }"
                }
                elseif ($parameter.TypeNameOfValue -eq 'System.Boolean') {
                    if ($parameter.Value) {
                        $ScriptBlock += " -$($parameter.Name)"
                    }
                }
                else {
                    $ScriptBlock += " -$($parameter.Name) '$($parameter.Value)'"
                }
            }

            & ([ScriptBlock]::Create($ScriptBlock))
            $Session:ScriptBlock = $ScriptBlock
            Sync-UDElement -Id 'script'
        }
        
    } -Id 'display'

    New-UDDynamic -Id 'parameters' -Content {
        New-UDTabs -Tabs {
            New-UDTab -Text 'Parameters' -Content {
                $Parameters = Get-Command -Name $Session:SelectedComponent

                New-UDForm -Id 'form' -Content {
                    New-UDTable -Data ($Parameters.Parameters.Values | Where-Object { $CommonParams -notcontains $_.Name }) -Columns @(
                        New-UDTableColumn -Property Name -Title 'Name'
                        New-UDTableColumn -Property Value -Title 'Value' -Render {
                            if ($EventData.ParameterType.Name -eq 'SwitchParameter') {
                                New-UDSwitch -Id $EventData.Name
                            }
                            elseif ($EventData.ParameterType.Name -eq 'ScriptBlock' -or $EventData.ParameterType.Name -eq 'Endpoint') {
                                New-UDTextbox -Placeholder $EventData.ParameterType -Id $EventData.Name -Multiline
                            }
                            elseif ($EventData.Name -eq 'Icon') {
                                New-UDAutocomplete -OnLoadOptions { 
                                    Find-UDIcon -Name $Body | ConvertTo-Json
                                } -Id 'icon'
                            }
                            elseif ($EventData.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidateSetAttribute' }) {
                                $Attribute = $EventData.Attributes | Where-Object { $_.TypeId.Name -eq 'ValidateSetAttribute' }
                                New-UDSElect -Option {
                                    $Attribute.ValidValues | ForEach-Object {
                                        New-UDSElectOption -Name $_ -Value $_
                                    }
                                } -Id $EventData.Name
                            }
                            else {
                                New-UDTextbox -Placeholder $EventData.ParameterType -Id $EventData.Name
                            }
                        }
                    )
                } -OnSubmit {
                    $Session:Parameters = $EventData
                    Sync-UDElement -Id 'display'
                } 
            }
            New-UDTab -Text 'Script' -Content {
                New-UDDynamic -Id 'script' -Content {
                    New-UDButton -Text 'Copy' -OnClick {
                        Set-UDClipboard -Data $Session:ScriptBlock
                    } 
                    New-UDElement -Tag 'pre' -Content { $Session:ScriptBlock }
                }
            }
        }
    }
} -Navigation $Navigation -NavigationLayout Permanent