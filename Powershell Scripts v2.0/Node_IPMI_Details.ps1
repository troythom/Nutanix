# For Internal Use
# Requires Nutanix VPN Access
# Originally written by Grant Strang - Nutanix Systems Engineer

[reflection.assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$folderFrom = New-Object System.Windows.Forms.Form
$pathTextBox = New-Object System.Windows.Forms.TextBox
$folderFrom.Text = "Get IPMI Macs"
$pathTextBox.Location = '23,23'
$pathTextBox.Size = '150,23'
#$Icon = New-Object System.Drawing.Icon ("nutanix.exe")
#$folderFrom.Icon = $Icon
$folderFrom.Controls.Add($pathTextBox)


$selectButton = New-Object System.Windows.Forms.Button
$selectButton.Text = 'Select'
$selectButton.Location = '196,23'
$folderFrom.Controls.Add($selectButton)

$fileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$fileBrowser.Filter = "CSV files (*.csv)|*.csv|Excel Files (*.xlsx)|*.xlsx|All files (*.*)|*.*"
$selectButton.Add_Click({
    $fileBrowser.ShowDialog()
    $pathTextBox.Text = $fileBrowser.FileName
})

$pathTextBox.ReadOnly = $true


$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Name = "Getting MAC address"
$progressBar.Value = 0
$progressBar.Style = "Continuous"
$progressBar.Location = "23,140"
$progressBar.Width = 235


$getMACS = New-Object System.Windows.Forms.Button
$getMACS.Location = '23,90'
$getMACS.Text = 'Get MACs'
$getMACS.Add_Click({
$folderFrom.Controls.Add($progressBar)
Try
{
    $filePath = $fileBrowser.FileName
    $savePath = $filePath.Substring(0, $filePath.LastIndexOf('\'))
    Remove-Item -Path "$savePath\IPMI MAC report.csv" -ErrorAction SilentlyContinue
    $progressBar.Value = 10
}
Catch
{
 Write-host "Error - Could not get to file path" -ForegroundColor Red
}

Try {
    test-connection watchtower.corp.nutanix.com -Count 1 -ErrorAction Stop
    #Write-Host "Connected to corprate VPN.  Getting MAC address." -ForegroundColor Green
    $progressBar.Value = 15
}
Catch {
    Write-Host "Error - Unable to connect to server. Check that you are connected to the Nutanix networking, including VPN and try again." -ForegroundColor Red
    break
}


Try {
$result = @()
$snImport = import-csv $filePath
FOREACH ($SN in $snImport.SN)
{
    $progressBar.Value = $progressBar.Value + 4
    $webrequest = "https://watchtower.corp.nutanix.com/factoryData.json/$SN"
    $datajson = Invoke-WebRequest -uri $webrequest -UseBasicParsing
    $modelNumber = $datajson.Content | ConvertFrom-Json | Select -expand data | select model_number
    IF ($modelNumber.model_number -like "NX-*")
    {
        $modelNumber = $modelNumber.model_number
    }
    ELSE
    {
       $skuNumber = $datajson.Content | ConvertFrom-Json | Select -expand data | select sku
       $modelNumber = $skuNumber.sku
    }
    #Single node models
    IF ($modelNumber -like "NX-1120S*" -or $modelNumber -like "NX-1175S*" -or $modelNumber -like "NX-1165*" -or $modelNumber -like "NX-3160*" -or $modelNumber -like "NX-3155*" -or $modelNumber -like "NX-3170*" -or $modelNumber -like "NX-8135*" -or $modelNumber -like "NX-8150*" -or $modelNumber -like "NX-8155*" -or $modelNumber -like "NX-8170*")
    {
        $ipmimac = $datajson.Content | ConvertFrom-Json | Select -expand data | Select -Expand node_list | Select ipmi_mac_addr | Select -First 1
        $nodeSN = $datajson.content | ConvertFrom-Json | select -expand data | select -expand node_list | Select node_serial_number | Select -First 1
        $obj = New-Object psobject
        $obj | Add-Member -MemberType NoteProperty -Name Block_SN -Value $SN
        $obj | Add-Member -MemberType NoteProperty -Name Node_SN -Value $nodeSN.node_serial_number
        $obj | Add-Member -MemberType NoteProperty -Name IPMIMAC -Value $ipmimac.ipmi_mac_addr
        $obj | Add-Member -MemberType NoteProperty -Name MULTINODE -Value "NO"
        $obj | Add-Member -MemberType NoteProperty -Name LOCATION -Value "N/A"
        $result += $obj
    }
    #Dual node models
    ELSEIF ($modelNumber -like 'NX-1265*' -or $modelNumber -like 'NX-3260*' -or $modelNumber -like 'NX-8235*')
    {
        $nodes = $datajson.content | ConvertFrom-Json | select -expand data | select -expand node_list
        FOREACH ($node in $nodes)
        {
            $SNCheck = $result.SN -contains $node.motherboard_info.serial_number
            IF ($SNCheck -eq "True")
            {
                Write-Host "Exclude"
            }
            ELSE
            {
                $obj = New-Object psobject
                $obj | Add-Member -MemberType NoteProperty -Name Block_SN -Value $SN
                $obj | Add-Member -MemberType NoteProperty -Name Node_SN -Value $node.motherboard_info.serial_number
                $obj | Add-Member -MemberType NoteProperty -Name IPMIMAC -Value $node.motherboard_info.mb_ipmi_mac
                $obj | Add-Member -MemberType NoteProperty -Name MULTINODE -Value "Yes"
                $obj | Add-Member -MemberType NoteProperty -Name LOCATION -Value $node.node_location
                $result += $obj
            }
        }
    }
    #Three node models
    ELSEIF ($modelNumber -like "NX-1365*" -or $modelNumber -like "NX-3360*")
    {
        $nodes = $datajson.content | ConvertFrom-Json | select -expand data | select -expand node_list
        FOREACH ($node in $nodes)
        {
        $SNCheck = $result.SN -contains $node.motherboard_info.serial_number
        IF ($SNCheck -ne "True")
        {
            $obj = New-Object psobject
            $obj | Add-Member -MemberType NoteProperty -Name Block_SN -Value $SN
            $obj | Add-Member -MemberType NoteProperty -Name Node_SN -Value $node.motherboard_info.serial_number
            $obj | Add-Member -MemberType NoteProperty -Name IPMIMAC -Value $node.motherboard_info.mb_ipmi_mac
            $obj | Add-Member -MemberType NoteProperty -Name MULTINODE -Value "Yes"
            $obj | Add-Member -MemberType NoteProperty -Name LOCATION -Value $node.node_location
            $result += $obj
        }

        }
    }
    #Four node models
    ELSEIF ($modelNumber -like "NX-1465*" -or $modelNumber -like "NX-3460*")
    {
        $nodes = $datajson.content | ConvertFrom-Json | select -expand data | select -expand node_list
        FOREACH ($node in $nodes)
        {
        $SNCheck = $result.SN -contains $node.motherboard_info.serial_number
        IF ($SNCheck -ne "True")
        {
            $obj = New-Object psobject
            $obj | Add-Member -MemberType NoteProperty -Name Block_SN -Value $SN
            $obj | Add-Member -MemberType NoteProperty -Name Node_SN -Value $node.motherboard_info.serial_number
            $obj | Add-Member -MemberType NoteProperty -Name IPMIMAC -Value $node.motherboard_info.mb_ipmi_mac
            $obj | Add-Member -MemberType NoteProperty -Name MULTINODE -Value "Yes"
            $obj | Add-Member -MemberType NoteProperty -Name LOCATION -Value $node.node_location
            $result += $obj
        }

        }
    }
    ELSE
    {
            $obj = New-Object psobject
            $obj | Add-Member -MemberType NoteProperty -Name Block_SN -Value $SN
            $obj | Add-Member -MemberType NoteProperty -Name Node_SN -Value $node.motherboard_info.serial_number
            $obj | Add-Member -MemberType NoteProperty -Name IPMIMAC -Value "Not Found"
            $obj | Add-Member -MemberType NoteProperty -Name MULTINODE -Value ""
            $obj | Add-Member -MemberType NoteProperty -Name LOCATION -Value ""
            $result += $obj
    }
}

}
Catch
{

}
$result | export-csv "$savepath\IPMI MAC report.csv" -NoTypeInformation
Write-Host "File saved to $savepath\IPMI MAC report.csv"
$progressBar.Value = 100

})
$folderFrom.Controls.Add($getMACS)


$close = New-Object System.Windows.Forms.Button
$close.Location = '99,190'
$close.Text = 'Close'
$close.Add_Click({
    $folderFrom.Close() | Out-Null
})
$folderFrom.Controls.Add($close)


$folderFrom.ShowDialog() | Out-Null
